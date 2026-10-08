import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Stores the finished design as a PNG **on this device only**
/// (the app's documents folder) — never uploaded, never auto-shared.
///
/// The album itself lives in [ProgressState]; this repository only deals with
/// the image files.
class GalleryRepository {
  static const String _folderName = 'sparkle_designs';

  /// Saves [bytes] and returns the file name, or `null` if saving failed.
  Future<String?> saveDesignImage(
    Uint8List bytes, {
    required String designId,
  }) async {
    try {
      final Directory dir = await _designsDir();
      final String fileName = 'design_$designId.png';
      final File file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return fileName;
    } catch (_) {
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
