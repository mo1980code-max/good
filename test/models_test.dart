import 'package:flutter_test/flutter_test.dart';
import 'package:sparkle_nail_spa/data/models/gallery_item.dart';
import 'package:sparkle_nail_spa/data/models/nail_item_model.dart';
import 'package:sparkle_nail_spa/data/models/progress_state.dart';
import 'package:sparkle_nail_spa/data/models/round_state.dart';
import 'package:sparkle_nail_spa/data/models/settings_model.dart';

/// Pure-logic tests: no widgets, no storage, no audio needed.
void main() {
  group('RoundState', () {
    test('a fresh round still needs every required pick', () {
      final RoundState round = RoundState.fresh('kitty');
      expect(round.hasAllRequiredPicks, isFalse);
      expect(round.canAdvanceFromStudioStep, isFalse);
    });

    test('copyWith can also CLEAR a choice (null)', () {
      RoundState round =
          const RoundState(characterId: 'kitty', colorId: 'pink');
      expect(round.colorId, 'pink');

      round = round.copyWith(colorId: () => null);
      expect(round.colorId, isNull);
    });

    test('the pattern step stays optional', () {
      const RoundState round = RoundState(
        characterId: 'kitty',
        shape: NailShape.round,
        colorId: 'pink',
        stickerId: 'star',
        ringId: 'ring_1',
      );
      expect(round.hasAllRequiredPicks, isTrue);
      expect(round.patternId, isNull);
    });
  });

  group('NailCatalog', () {
    test('ids resolve and unknown ids fall back safely', () {
      expect(NailShape.fromId('square'), NailShape.square);
      expect(NailShape.fromId('nope'), NailShape.round);
      expect(NailCatalog.colorById('nope').id, NailCatalog.colors.first.id);
      expect(NailCatalog.stickerById(null).id, NailCatalog.stickers.first.id);
      expect(NailCatalog.ringById('nope').id, NailCatalog.rings.first.id);
    });

    test('catalog sizes match the GDD (41,472 possible designs)', () {
      final int combinations = NailCatalog.colors.length *
          NailCatalog.patterns.length *
          NailCatalog.stickers.length *
          NailCatalog.rings.length *
          NailShape.values.length;

      expect(combinations, 41472);
    });
  });

  group('ProgressState', () {
    test('survives a json round trip', () {
      const GalleryItem item = GalleryItem(
        id: '1',
        characterId: 'kitty',
        shapeId: 'round',
        colorId: 'pink',
        patternId: 'plain',
        stickerId: 'star',
        ringId: 'ring_1',
        createdAtMs: 42,
      );
      const ProgressState state = ProgressState(
        stars: 9,
        coins: 100,
        keys: 2,
        unlockedItemIds: <String>{'pink'},
        gallery: <GalleryItem>[item],
      );

      final ProgressState restored = ProgressState.fromJson(state.toJson());

      expect(restored.stars, 9);
      expect(restored.coins, 100);
      expect(restored.keys, 2);
      expect(restored.gallery.single.id, '1');
      expect(restored.isUnlocked('pink'), isTrue);
    });

    test('tolerates corrupted save data instead of crashing', () {
      final ProgressState restored = ProgressState.fromJson(
        const <String, dynamic>{'stars': 'not-a-number', 'gallery': 'nope'},
      );

      expect(restored.stars, 0);
      expect(restored.gallery, isEmpty);
    });

    test('broken gallery entries are skipped, good ones survive', () {
      final ProgressState restored = ProgressState.fromJson(
        <String, dynamic>{
          'gallery': <Object?>[
            'garbage',
            <String, dynamic>{'id': 'kept', 'characterId': 'bunny'},
          ],
        },
      );

      expect(restored.gallery.length, 1);
      expect(restored.gallery.single.characterId, 'bunny');
      expect(restored.gallery.single.colorId, 'pink'); // safe default
    });

    test('free items are always usable, paid ones need an unlock', () {
      const ProgressState state = ProgressState();
      expect(state.canUse('pink', price: 0), isTrue);
      expect(state.canUse('lilac', price: 30), isFalse);
    });
  });

  group('SettingsModel', () {
    test('missing fields fall back to the defaults', () {
      final SettingsModel settings =
          SettingsModel.fromJson(const <String, dynamic>{});

      expect(settings.soundOn, isTrue);
      expect(settings.musicOn, isTrue);
      expect(settings.hapticsOn, isTrue);
      expect(settings.reduceMotion, isFalse);
    });

    test('round trip keeps every flag', () {
      const SettingsModel settings = SettingsModel(
        soundOn: false,
        musicOn: true,
        hapticsOn: false,
        reduceMotion: true,
      );

      final SettingsModel restored = SettingsModel.fromJson(settings.toJson());

      expect(restored.soundOn, isFalse);
      expect(restored.musicOn, isTrue);
      expect(restored.hapticsOn, isFalse);
      expect(restored.reduceMotion, isTrue);
    });
  });
}
