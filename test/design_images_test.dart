import 'package:flutter_test/flutter_test.dart';
import 'package:sparkle_nail_spa/data/models/gallery_item.dart';
import 'package:sparkle_nail_spa/data/models/progress_state.dart';

/// Covers the fix for the "save must survive the screen" rule:
/// the durable design-image map is merged into the album when progress loads,
/// so a capture that finished *after* the reveal screen was closed still shows.
void main() {
  GalleryItem item(String id, {String? image}) => GalleryItem(
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

  group('ProgressState.withDesignImages', () {
    test('fills in a missing file name from the durable map', () {
      final ProgressState progress = ProgressState(
        gallery: <GalleryItem>[item('100')],
      );

      final ProgressState merged =
          progress.withDesignImages(<String, String>{'100': 'design_100.png'});

      expect(merged.gallery.single.imageFileName, 'design_100.png');
    });

    test('never overwrites a file name the album already knows', () {
      final ProgressState progress = ProgressState(
        gallery: <GalleryItem>[item('100', image: 'original.png')],
      );

      final ProgressState merged =
          progress.withDesignImages(<String, String>{'100': 'other.png'});

      expect(merged.gallery.single.imageFileName, 'original.png');
    });

    test('leaves unrelated designs untouched', () {
      final ProgressState progress = ProgressState(
        gallery: <GalleryItem>[item('100'), item('200')],
      );

      final ProgressState merged =
          progress.withDesignImages(<String, String>{'999': 'ghost.png'});

      expect(merged.gallery.every((GalleryItem i) => i.imageFileName == null), isTrue);
      expect(identical(merged, progress), isTrue,
          reason: 'no change means the very same object, so no needless rebuild');
    });

    test('an empty map is a no-op', () {
      final ProgressState progress = ProgressState(
        gallery: <GalleryItem>[item('100')],
      );
      expect(identical(progress.withDesignImages(<String, String>{}), progress), isTrue);
    });

    test('an empty album is a no-op', () {
      const ProgressState progress = ProgressState();
      expect(
        identical(
          progress.withDesignImages(<String, String>{'100': 'design_100.png'}),
          progress,
        ),
        isTrue,
      );
    });
  });

  group('save data backwards compatibility', () {
    test('a v1 save (no achievements, no counters) still loads', () {
      final ProgressState old = ProgressState.fromJson(<String, dynamic>{
        'stars': 5,
        'coins': 30,
        'gallery': <Object?>[
          <String, dynamic>{'id': '1', 'characterId': 'bunny'},
        ],
      });

      expect(old.stars, 5);
      expect(old.gallery.length, 1);
      expect(old.achievements, isEmpty);
      expect(old.spaStepsCompleted, 0);
      expect(old.boxesOpened, 0);
    });

    test('achievements and counters survive a json round trip', () {
      const ProgressState progress = ProgressState(
        achievements: <String>{'first_sparkle', 'color_explorer'},
        spaStepsCompleted: 14,
        boxesOpened: 2,
      );

      final ProgressState restored = ProgressState.fromJson(progress.toJson());

      expect(restored.achievements,
          containsAll(<String>['first_sparkle', 'color_explorer']));
      expect(restored.spaStepsCompleted, 14);
      expect(restored.boxesOpened, 2);
    });

    test('a corrupted achievements field degrades to empty, not a crash', () {
      final ProgressState restored = ProgressState.fromJson(
        const <String, dynamic>{'achievements': 'not-a-list'},
      );
      expect(restored.achievements, isEmpty);
    });
  });
}
