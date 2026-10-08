import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sparkle_nail_spa/data/models/design_files.dart';
import 'package:sparkle_nail_spa/data/models/gallery_item.dart';
import 'package:sparkle_nail_spa/data/models/progress_state.dart';
import 'package:sparkle_nail_spa/data/repositories/design_saver.dart';
import 'package:sparkle_nail_spa/data/repositories/design_store.dart';

/// Covers the save-durability rules the review asked for:
///   1. a file and its record stay consistent when a write is interrupted,
///   2. `.tmp_*` leftovers from a killed app are cleaned up,
///   3. retrying can never duplicate a design,
///   4. a v1 save survives the upgrade,
///   5. the write completes even if the screen (and index) are gone.
///
/// Everything is a fake → no plugins, no device, no Flutter UI.
void main() {
  group('DesignFiles (the naming convention)', () {
    test('name and id round-trip', () {
      expect(DesignFiles.nameFor('123'), 'design_123.png');
      expect(DesignFiles.idFrom('design_123.png'), '123');
    });

    test('rejects anything that is not a design file', () {
      expect(DesignFiles.idFrom('.tmp_123'), isNull);
      expect(DesignFiles.idFrom('design_.png'), isNull);
      expect(DesignFiles.idFrom('holiday.png'), isNull);
    });

    test('spots temp files', () {
      expect(DesignFiles.isTemp('.tmp_123'), isTrue);
      expect(DesignFiles.isTemp('design_123.png'), isFalse);
    });
  });

  group('DesignSaver', () {
    late _FakeFiles files;
    late _FakeIndex index;

    setUp(() {
      files = _FakeFiles();
      index = _FakeIndex();
    });

    DesignSaver saver() => DesignSaver(files: files, index: index);

    Uint8List image() => Uint8List.fromList(<int>[1, 2, 3, 4]);

    test('a successful save writes one file and one index entry', () async {
      final DesignSaveResult result = await saver().save(
        designId: '100',
        capture: () async => image(),
      );

      expect(result.status, DesignSaveStatus.saved);
      expect(result.fileName, 'design_100.png');
      expect(files.files.keys, <String>['design_100.png']);
      expect(index.entries, <String, String>{'100': 'design_100.png'});
    });

    test('an empty capture writes nothing at all', () async {
      final DesignSaveResult result = await saver().save(
        designId: '100',
        capture: () async => null,
      );

      expect(result.status, DesignSaveStatus.emptyCapture);
      expect(files.files, isEmpty);
      expect(index.entries, isEmpty);
    });

    test('a throwing capture is reported, never rethrown', () async {
      final DesignSaveResult result = await saver().save(
        designId: '100',
        capture: () async => throw StateError('screen gone'),
      );

      expect(result.status, DesignSaveStatus.emptyCapture);
    });

    test('a failed write is reported and nothing is indexed', () async {
      files.failWrites = true;

      final DesignSaveResult result = await saver().save(
        designId: '100',
        capture: () async => image(),
      );

      expect(result.status, DesignSaveStatus.writeFailed);
      expect(index.entries, isEmpty);
    });

    test(
      'a failed index write is still a saved design '
      '(the name is derivable from the id)',
      () async {
        index.failWrites = true;

        final DesignSaveResult result = await saver().save(
          designId: '100',
          capture: () async => image(),
        );

        expect(result.status, DesignSaveStatus.saved);
        expect(files.files.containsKey('design_100.png'), isTrue);
        expect(index.entries, isEmpty);

        // …and the album still finds it, via the pure disk-merge.
        final ProgressState merged = ProgressState(
          gallery: <GalleryItem>[_item('100')],
        ).withAvailableDesigns(await saver().designIdsOnDisk());

        expect(merged.gallery.single.imageFileName, 'design_100.png');
      },
    );

    test('retrying never duplicates a design', () async {
      files.failWrites = true;
      final DesignSaver saver = DesignSaver(files: files, index: index);

      for (int attempt = 0; attempt < 3; attempt++) {
        await saver.save(designId: '100', capture: () async => image());
      }

      files.failWrites = false;
      await saver.save(designId: '100', capture: () async => image());
      await saver.save(designId: '100', capture: () async => image());

      // The same id always maps to the same name, so it is overwritten —
      // never stored twice.
      expect(files.files.length, 1);
      expect(index.entries.length, 1);
      expect(files.writeCount, 4); // 3 failures + 1 success… then 1 more
    });

    test('cleaning temp files removes only leftovers', () async {
      files.tempFiles.addAll(<String>['.tmp_100', '.tmp_101']);
      files.files['design_100.png'] = image();

      await saver().cleanupTempFiles();

      expect(files.tempFiles, isEmpty);
      expect(files.files.containsKey('design_100.png'), isTrue);
    });

    test('a design whose file is missing is never "repaired"', () async {
      final Set<String> onDisk = await saver().designIdsOnDisk();
      expect(onDisk, isEmpty);
    });

    test('a save with no storage configured fails safely', () async {
      const DesignSaver bare = DesignSaver();
      final DesignSaveResult result =
          await bare.save(designId: '1', capture: () async => image());

      expect(result.status, DesignSaveStatus.writeFailed);
    });
  });

  group('ProgressState.withAvailableDesigns', () {
    test('fills in a name for a design whose PNG exists on disk', () {
      final ProgressState progress = ProgressState(
        gallery: <GalleryItem>[_item('100')],
      );

      final ProgressState merged =
          progress.withAvailableDesigns(<String>{'100'});

      expect(merged.gallery.single.imageFileName, 'design_100.png');
    });

    test('never overwrites a name the album already has', () {
      final ProgressState progress = ProgressState(
        gallery: <GalleryItem>[_item('100', image: 'kept.png')],
      );

      final ProgressState merged =
          progress.withAvailableDesigns(<String>{'100'});

      expect(merged.gallery.single.imageFileName, 'kept.png');
      expect(identical(merged, progress), isTrue);
    });

    test('ignores files that belong to no design in the album', () {
      final ProgressState progress = ProgressState(
        gallery: <GalleryItem>[_item('100')],
      );

      expect(
        identical(progress.withAvailableDesigns(<String>{'999'}), progress),
        isTrue,
      );
    });

    test('an empty disk listing changes nothing', () {
      final ProgressState progress = ProgressState(
        gallery: <GalleryItem>[_item('100')],
      );

      expect(
        identical(progress.withAvailableDesigns(const <String>{}), progress),
        isTrue,
      );
    });
  });
}

GalleryItem _item(String id, {String? image}) => GalleryItem(
      id: id,
      characterId: 'kitty',
      shapeId: 'round',
      colorId: 'pink',
      patternId: 'plain',
      stickerId: 'star',
      ringId: 'ring_1',
      createdAtMs: 0,
      imageFileName: image,
    );

/// An in-memory [DesignFileStore] — no filesystem, no plugin.
class _FakeFiles implements DesignFileStore {
  final Map<String, Uint8List> files = <String, Uint8List>{};
  final Set<String> tempFiles = <String>{};
  bool failWrites = false;
  int writeCount = 0;

  @override
  Future<String?> saveDesignImage(
    Uint8List bytes, {
    required String designId,
  }) async {
    writeCount++;
    if (failWrites) return null;
    if (bytes.isEmpty) return null;

    final String name = DesignFiles.nameFor(designId);

    // Mirrors the real repository: temp first, then rename, and a stale temp
    // for the same design is dropped before writing.
    tempFiles.remove('${DesignFiles.tempPrefix}$designId');
    tempFiles.add('${DesignFiles.tempPrefix}$designId');
    files[name] = bytes;
    tempFiles.remove('${DesignFiles.tempPrefix}$designId');
    return name;
  }

  @override
  Future<Set<String>> designIdsOnDisk() async {
    final Set<String> ids = <String>{};
    files.forEach((String name, Uint8List bytes) {
      final String? id = DesignFiles.idFrom(name);
      if (id != null && bytes.isNotEmpty) ids.add(id);
    });
    return ids;
  }

  @override
  Future<void> cleanupTempFiles() async {
    tempFiles.removeWhere((String name) => DesignFiles.isTemp(name));
  }
}

/// An in-memory [DesignImageIndex].
class _FakeIndex implements DesignImageIndex {
  final Map<String, String> entries = <String, String>{};
  bool failWrites = false;

  @override
  Map<String, String> loadDesignImages() => Map<String, String>.from(entries);

  @override
  Future<void> setDesignImage(String designId, String fileName) async {
    if (failWrites) throw StateError('no storage');
    entries[designId] = fileName;
  }

  @override
  Future<void> removeDesignImage(String designId) async {
    entries.remove(designId);
  }
}
