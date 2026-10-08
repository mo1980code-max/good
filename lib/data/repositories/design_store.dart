import 'dart:typed_data';

/// The **filesystem** half of the durable save path.
///
/// An interface (not a concrete class) only so the save logic can be unit
/// tested with a fake — the production implementation is [GalleryRepository].
abstract interface class DesignFileStore {
  /// Writes the PNG atomically and returns its file name, or `null` on failure.
  Future<String?> saveDesignImage(Uint8List bytes, {required String designId});

  /// Design ids that already have a **non-empty** PNG on disk.
  /// Used to repair a missing picture reference without any index at all.
  Future<Set<String>> designIdsOnDisk();

  /// Deletes `.tmp_*` leftovers from a save that was interrupted by the app
  /// closing. Called once when the album loads.
  Future<void> cleanupTempFiles();
}

/// The **key/value** half of the durable save path: `designId -> PNG name`.
///
/// The production implementation is [LocalStorageService]. Keeping it behind
/// an interface lets the saver be tested without any plugin.
abstract interface class DesignImageIndex {
  Map<String, String> loadDesignImages();

  Future<void> setDesignImage(String designId, String fileName);

  Future<void> removeDesignImage(String designId);
}
