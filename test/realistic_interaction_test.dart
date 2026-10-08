import 'package:flutter_test/flutter_test.dart';
import 'package:sparkle_nail_spa/data/models/gallery_item.dart';
import 'package:sparkle_nail_spa/data/models/nail_item_model.dart';
import 'package:sparkle_nail_spa/data/models/round_state.dart';

void main() {
  group('movement-based nail recipe', () {
    test('the paint step cannot advance from a colour pick alone', () {
      const RoundState colourLoaded = RoundState(
        characterId: 'kitty',
        studioStep: 1,
        colorId: 'pink',
      );

      expect(colourLoaded.canAdvanceFromStudioStep, isFalse);
    });

    test('all five covered nail masks unlock the next step', () {
      const Map<int, String> colours = <int, String>{
        0: 'pink',
        1: 'lavender',
        2: 'sky',
        3: 'mint',
        4: 'peach',
      };
      const Map<int, double> coverage = <int, double>{
        0: 1,
        1: 1,
        2: 1,
        3: 1,
        4: 1,
      };
      const RoundState painted = RoundState(
        characterId: 'kitty',
        studioStep: 1,
        colorId: 'peach',
        nailColors: colours,
        nailCoverage: coverage,
      );

      expect(painted.allNailsPainted, isTrue);
      expect(painted.canAdvanceFromStudioStep, isTrue);
    });
  });

  test('old gallery data and the new per-nail recipe round-trip safely', () {
    const GalleryItem item = GalleryItem(
      id: '42',
      characterId: 'kitty',
      shapeId: 'almond',
      colorId: 'peach',
      patternId: 'glitter',
      stickerId: 'star',
      ringId: 'ring_1',
      createdAtMs: 42,
      nailLengthId: 'long',
      nailColors: <int, String>{
        0: 'pink',
        1: 'lavender',
        2: 'sky',
        3: 'mint',
        4: 'peach',
      },
    );

    final GalleryItem restored = GalleryItem.tryParse(item.toJson())!;
    expect(restored.nailLengthId, 'long');
    expect(restored.nailColors[1], 'lavender');
    expect(NailLength.fromId(restored.nailLengthId), NailLength.long);

    final GalleryItem old = GalleryItem.tryParse(<String, dynamic>{
      'id': 'old',
      'characterId': 'kitty',
    })!;
    expect(old.nailLengthId, 'medium');
    expect(old.nailColors, isEmpty);
  });
}
