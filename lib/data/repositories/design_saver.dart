import 'dart:typed_data';

import 'design_store.dart';

/// Outcome of one save attempt — the UI decides what to show.
enum DesignSaveStatus {
  /// PNG written and its name persisted. The album will show it forever.
  saved,

  /// The capture came back empty (screen disposed too early, or a platform
  /// without a render surface). Safe to retry.
  emptyCapture,

  /// The file could not be written (disk full, permissions). Safe to retry.
  writeFailed,
}

class DesignSaveResult {
  const DesignSaveResult(this.status, {this.fileName});

  final DesignSaveStatus status;
  final String? fileName;

  bool get isSaved => status == DesignSaveStatus.saved;
}

/// Saves a finished design **without touching a single Riverpod object**.
///
/// Why this class exists (and why the screen no longer does the job):
/// reading `ref.read(...)` before an `await` avoids using a disposed *widget*,
/// but the notifier itself can still be disposed — for example when the app is
/// closing or the whole `ProviderScope` is torn down. Mutating a disposed
/// notifier throws, and the design's image name would be lost.
///
/// So the durable path is deliberately boring:
///   1. capture the PNG bytes,
///   2. write the file atomically (`DesignFileStore`),
///   3. persist the file name in the index (`DesignImageIndex`).
///
/// Steps 2 and 3 only touch long-lived singletons. And because the file name is
/// derived from the design id (`design_<id>.png`), step 3 is a *convenience*,
/// not a requirement: if it never lands, the album still finds the picture by
/// looking at what is actually on disk.
///
/// Every failure mode is a value, never an exception:
///
/// | what failed                  | status         | what the child sees      |
/// |------------------------------|----------------|--------------------------|
/// | capture returned null/empty  | `emptyCapture` | a quiet retry (3x), then |
/// |                              |                | the album repairs it     |
/// | disk write failed            | `writeFailed`  | same                     |
/// | index write failed           | `saved` (file is on disk; name is derived) |
///
/// Retrying is **idempotent**: the same design id always maps to the same file
/// name, so a retry can neither duplicate a file nor duplicate an album entry.
///
/// Nothing here reads a clock, a widget or a provider → fully unit-testable by
/// injecting a fake capture callback, a fake file store and a fake index.
class DesignSaver {
  const DesignSaver({
    DesignFileStore? files,
    DesignImageIndex? index,
  })  : _files = files,
        _index = index;

  /// Null only in tests that deliberately check the "no storage configured"
  /// path — production always gets both from `designSaverProvider`.
  final DesignFileStore? _files;
  final DesignImageIndex? _index;

  Future<DesignSaveResult> save({
    required String designId,
    required Future<Uint8List?> Function() capture,
  }) async {
    final Uint8List? bytes;
    try {
      bytes = await capture();
    } catch (_) {
      return const DesignSaveResult(DesignSaveStatus.emptyCapture);
    }

    if (bytes == null || bytes.isEmpty) {
      return const DesignSaveResult(DesignSaveStatus.emptyCapture);
    }

    final DesignFileStore? store = _files;
    if (store == null) return const DesignSaveResult(DesignSaveStatus.writeFailed);

    final String? fileName;
    try {
      fileName = await store.saveDesignImage(bytes, designId: designId);
    } catch (_) {
      return const DesignSaveResult(DesignSaveStatus.writeFailed);
    }

    if (fileName == null || fileName.isEmpty) {
      return const DesignSaveResult(DesignSaveStatus.writeFailed);
    }

    // Durable, provider-free record. Even if the screen is long gone, the
    // album will find this name on its next load. A failure here is *not* a
    // lost design: the file is on disk and its name is derivable.
    try {
      await _index?.setDesignImage(designId, fileName);
    } catch (_) {
      // Absorbed on purpose — see the table above.
    }

    return DesignSaveResult(DesignSaveStatus.saved, fileName: fileName);
  }

  /// House-keeping: drop `.tmp_*` files left behind by a killed app.
  /// Never throws; a failure just means the cleanup happens next time.
  Future<void> cleanupTempFiles() async {
    try {
      await _files?.cleanupTempFiles();
    } catch (_) {
      // Nothing to do — the next album visit tries again.
    }
  }

  /// Design ids that really exist on disk right now (empty set if unreadable).
  Future<Set<String>> designIdsOnDisk() async {
    try {
      return await _files?.designIdsOnDisk() ?? <String>{};
    } catch (_) {
      return <String>{};
    }
  }
}
