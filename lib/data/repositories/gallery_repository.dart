import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/design_files.dart';
import 'design_store.dart';

/// Stores the finished design as a PNG **on this device only**
/// (the app's documents folder) — never uploaded, never auto-shared.
///
/// The album itself lives in `ProgressState`; this repository only deals with
/// the image files.
///
/// Durability rules implemented here (see `docs/save-durability.md`):
/// * **Atomic writes.** Bytes go to `.tmp_<id>` first and are then renamed, so
///   an interrupted save can never leave a half-written PNG under the final
///   name. Either the old picture or the new one is on disk — never a mixture.
/// * **Self-healing names.** [designIdsOnDisk] lists what really exists, so a
///   save that finished *after* the album index was written is still found.
/// * **Temp hygiene.** Leftovers from a killed app are removed
///   ([cleanupTempFiles]) and a stale temp for the same design is dropped
///   before every write.
class GalleryRepository implements DesignFileStore {
  static const String _folderName = 'sparkle_designs';

  /// Saves [bytes] and returns the file name, or `null` if saving failed.
  ///
  /// Re-running this with the same `designId` is **idempotent**: the same file
  /// is overwritten, so a retry can never create a second copy.
  @override
  Future<String?> saveDesignImage(
    Uint8List bytes, {
    required String designId,
  }) async {
    if (bytes.isEmpty) return null;

    try {
      final Directory dir = await _designsDir();
      final String fileName = DesignFiles.nameFor(designId);
      final File file = File('${dir.path}/$fileName');
      final File temp = File('${dir.path}/${DesignFiles.tempPrefix}$designId');

      // Drop a stale temp from an earlier interrupted attempt (same design).
      if (await temp.exists()) {
        await temp.delete();
      }

      await temp.writeAsBytes(bytes, flush: true);
      await temp.rename(file.path);

      // Paranoia, cheap: never report success for a file that is not there.
      final int size = await file.exists() ? await file.length() : 0;
      if (size <= 0) return null;

      return fileName;
    } catch (error) {
      debugPrint('GalleryRepository: image write failed ($error)');
      return null;
    }
  }

  Future<File?> fileFor(String fileName) async {
    try {
      final Directory dir = await _designsDir();
      final File file = File('${dir.path}/$fileName');
      return await file.exists() ? file : null;
    } catch (_) {
      return null;
    }
  }

  /// Design ids with a real (non-empty) PNG on disk. Pure listing — no index
  /// needed, which is exactly why a lost index is never a lost design.
  @override
  Future<Set<String>> designIdsOnDisk() async {
    final Set<String> ids = <String>{};
    try {
      final Directory dir = await _designsDir();
      await for (final FileSystemEntity entity in dir.list()) {
        if (entity is! File) continue;
        final String fileName = _baseName(entity.path);
        final String? id = DesignFiles.idFrom(fileName);
        if (id == null) continue;
        if (await entity.length() > 0) ids.add(id);
      }
    } catch (error) {
      debugPrint('GalleryRepository: listing failed ($error)');
    }
    return ids;
  }

  /// Removes `.tmp_*` leftovers — safe to call on every album visit.
  @override
  Future<void> cleanupTempFiles() async {
    try {
      final Directory dir = await _designsDir();
      await for (final FileSystemEntity entity in dir.list()) {
        if (entity is! File) continue;
        final String fileName = _baseName(entity.path);
        if (DesignFiles.isTemp(fileName)) {
          await entity.delete();
        }
      }
    } catch (error) {
      debugPrint('GalleryRepository: temp cleanup skipped ($error)');
    }
  }

  Future<bool> deleteDesignImage(String fileName) async {
    try {
      final Directory dir = await _designsDir();
      final File file = File('${dir.path}/$fileName');
      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Used together with a full progress reset.
  Future<void> deleteAllDesignImages() async {
    try {
      final Directory dir = await _designsDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {
      // Nothing to clean up.
    }
  }

  Future<Directory> _designsDir() async {
    final Directory base = await getApplicationDocumentsDirectory();
    final Directory dir = Directory('${base.path}/$_folderName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}

/// Last path segment of a file path, without importing a path package.
String _baseName(String path) {
  final int slash = path.lastIndexOf('/');
  final int backslash = path.lastIndexOf(r'\');
  final int cut = slash > backslash ? slash : backslash;
  return cut < 0 ? path : path.substring(cut + 1);
}
