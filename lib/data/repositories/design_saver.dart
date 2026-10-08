import 'dart:typed_data';

import 'gallery_repository.dart';
import 'local_storage_service.dart';

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
///   2. write the file (`GalleryRepository`),
///   3. persist the file name in the storage map (`LocalStorageService`).
///
/// Steps 2 and 3 only touch long-lived singletons. The album merges that map
/// back into its items when it loads (`ProgressState.withDesignImages`), so an
/// image saved *after* the child left the reveal screen still appears.
///
/// Nothing here reads the clock, the UI or a provider → fully unit-testable by
/// injecting a fake capture callback, a fake repository and a fake storage.
class DesignSaver {
  const DesignSaver({
    GalleryRepository? repository,
    LocalStorageService? storage,
  })  : _repository = repository,
        _storage = storage;

  final GalleryRepository? _repository;
  final LocalStorageService? _storage;

  GalleryRepository get _files => _repository ?? GalleryRepository();
  LocalStorageService get _store => _storage ?? LocalStorageService.instance;

  /// Runs the whole save. Never throws: any failure is reported as a status.
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

    final String? fileName;
    try {
      fileName = await _files.saveDesignImage(bytes, designId: designId);
    } catch (_) {
      return const DesignSaveResult(DesignSaveStatus.writeFailed);
    }

    if (fileName == null) {
      return const DesignSaveResult(DesignSaveStatus.writeFailed);
    }

    // Durable, provider-free record. Even if the screen is long gone, the
    // album will find this name on its next load.
    try {
      await _store.setDesignImage(designId, fileName);
    } catch (_) {
      // The PNG is on disk; the album can still repair the name later.
      return DesignSaveResult(DesignSaveStatus.saved, fileName: fileName);
    }

    return DesignSaveResult(DesignSaveStatus.saved, fileName: fileName);
  }
}
