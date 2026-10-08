import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparkle_nail_spa/core/gift_rooms/gift_room.dart';
import 'package:sparkle_nail_spa/core/gift_rooms/gift_room_engine.dart';
import 'package:sparkle_nail_spa/data/models/progress_state.dart';
import 'package:sparkle_nail_spa/data/models/nail_item_model.dart';
import 'package:sparkle_nail_spa/data/models/round_state.dart';
import 'package:sparkle_nail_spa/data/repositories/local_storage_service.dart';
import 'package:sparkle_nail_spa/features/game/game_providers.dart';

/// Phase 2.5 — gift rooms, checked from the two angles that matter:
///
/// * the **catalog** is sane (unique ids, prizes that really exist, pastel
///   rooms ordered by the stars they ask for),
/// * and the **rules** hold: a room opens at its milestone, a box opens once,
///   nothing is ever paid twice, and nothing the child earned is ever spent.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    _storage.resetForTests();
    await _storage.init();
    _container = ProviderContainer();
    _controller = _container.read(progressControllerProvider.notifier);
  });

  tearDown(() => _container.dispose());

  Future<void> restart() async {
    _container.dispose();
    _storage.resetForTests();
    await _storage.init();
    _container = ProviderContainer();
    _controller = _container.read(progressControllerProvider.notifier);
  }

  // -------------------------------------------------------------------------
  group('the gift catalog is sane', () {
    test('four pastel rooms, three boxes each', () {
      expect(GiftRoomCatalog.all, hasLength(4));
      expect(GiftRoomCatalog.boxCount, 12);
      for (final GiftRoom room in GiftRoomCatalog.all) {
        expect(room.boxCount, 3, reason: '${room.id} should hold 3 boxes');
        expect(room.boxes.every((GiftBox b) => b.roomId == room.id), isTrue);
      }
    });

    test('every box id is unique and stable', () {
      final Set<String> ids = <String>{};
      for (final GiftBox box in GiftRoomCatalog.everyBox) {
        expect(ids.add(box.id), isTrue, reason: 'duplicate box id ${box.id}');
        expect(box.id, startsWith('${box.roomId}.'));
      }
    });

    test('every item prize is a real, gift-only studio item', () {
      for (final GiftBox box in GiftRoomCatalog.everyBox) {
        final GiftPrize prize = box.prize;
        if (!prize.isItem) continue;

        final String id = prize.itemId!;
        final bool isColour = NailCatalog.colors
            .any((NailColorOption c) => c.id == id && c.giftOnly);
        final bool isRing =
            NailCatalog.rings.any((DecorItem r) => r.id == id && r.giftOnly);

        expect(
          isColour || isRing,
          isTrue,
          reason: '$id must be a gift-only colour or charm',
        );
      }
    });

    test('a room is never priced in a currency that can be lost', () {
      int previous = -1;
      for (final GiftRoom room in GiftRoomCatalog.all) {
        expect(room.starsRequired, greaterThanOrEqualTo(previous));
        previous = room.starsRequired;
      }
      expect(GiftRoomCatalog.all.first.starsRequired, 0,
          reason: 'the first room is open from the very first minute');
    });
  });

  // -------------------------------------------------------------------------
  group('the engine decides, not the widget', () {
    final Set<String> none = <String>{};

    test('a box in a room that is still far away is "roomLocked"', () {
      expect(
        GiftRoomEngine.stateOf(
          box: GiftRoomCatalog.mint.boxes.first,
          stars: 3,
          badges: 9,
          openedBoxes: none,
        ),
        GiftBoxState.roomLocked,
      );
    });

    test('an unlocked box that needs badges says so', () {
      expect(
        GiftRoomEngine.stateOf(
          box: GiftRoomCatalog.blush.boxes[2], // needs 1 badge
          stars: 0,
          badges: 0,
          openedBoxes: none,
        ),
        GiftBoxState.needsBadges,
      );
    });

    test('"opened" wins over everything else', () {
      expect(
        GiftRoomEngine.stateOf(
          box: GiftRoomCatalog.blush.boxes.first,
          stars: 999,
          badges: 99,
          openedBoxes: <String>{'blush.box1'},
        ),
        GiftBoxState.opened,
      );
    });

    test('junk ids in the save can never inflate the counters', () {
      expect(
        GiftRoomEngine.openedCount(<String>{'ghost.box', 'blush.box1'}),
        1,
      );
      expect(GiftRoomEngine.allOpened(<String>{'ghost.box'}), isFalse);
    });

    test('the next room is the first one still out of reach', () {
      expect(GiftRoomEngine.nextRoom(stars: 0)?.id, 'mint');
      expect(GiftRoomEngine.nextRoom(stars: 12)?.id, 'sky');
      expect(GiftRoomEngine.nextRoom(stars: 999), isNull);
    });
  });

  // -------------------------------------------------------------------------
  group('a gift is handed out exactly once', () {
    test('opening a box pays its prize and records the id', () {
      final GiftPrize? prize = _controller.openGiftBox('blush.box1');

      expect(prize, isNotNull);
      expect(_progress.coins, 40);
      expect(_progress.openedGiftBoxes, contains('blush.box1'));
    });

    test('the same box can never pay twice', () {
      _controller.openGiftBox('blush.box1');
      final int coins = _progress.coins;

      expect(_controller.openGiftBox('blush.box1'), isNull);
      expect(_controller.openGiftBox('blush.box1'), isNull);
      expect(_progress.coins, coins);
      expect(_progress.openedGiftBoxes, hasLength(1));
    });

    test('an unknown box id is refused', () {
      expect(_controller.openGiftBox('nope.box9'), isNull);
      expect(_progress.openedGiftBoxes, isEmpty);
    });

    test('a room that is not reached yet refuses, without any loss', () {
      expect(_controller.openGiftBox('mint.box1'), isNull);
      expect(_progress.openedGiftBoxes, isEmpty);
      expect(_progress.keys, 0);
    });

    test('a badge-gated box waits for the badges', () {
      // 0 badges → refused.
      expect(_controller.openGiftBox('blush.box3'), isNull);

      // Earn one badge the honest way: finish a design and claim it.
      _controller.completeRound(_round());
      _controller.claimAchievements(_controller.pendingAchievements());
      expect(_progress.achievements, isNotEmpty);

      final GiftPrize? prize = _controller.openGiftBox('blush.box3');
      expect(prize?.itemId, 'charm_heart');
      expect(_progress.isUnlocked('charm_heart'), isTrue);
    });

    test('an item prize unlocks the studio item for good', () {
      _controller.openGiftBox('blush.box2');

      expect(_progress.isUnlocked('rose_glow'), isTrue);
      expect(_progress.canUse('rose_glow', giftOnly: true), isTrue);

      // Before it was opened it was never usable — and never for sale.
      expect(
        const ProgressState().canUse('rose_glow', giftOnly: true),
        isFalse,
      );
      expect(_progress.unlockedItemIds, contains('rose_glow'));
    });

    test('stars paid by a box add up and are never spent', () {
      // Reach the sunny room (60 stars) by playing, then open its star box.
      for (int i = 0; i < 20; i++) {
        _controller.completeRound(_round(variant: i));
      }
      expect(_progress.stars, greaterThanOrEqualTo(60));

      final int before = _progress.stars;
      final GiftPrize? prize = _controller.openGiftBox('sunny.box1');

      expect(prize?.kind, GiftPrizeKind.stars);
      expect(_progress.stars, before + 3);
    });

    test('opened boxes and unlocks survive closing the app', () async {
      _controller.openGiftBox('blush.box2');
      _controller.openGiftBox('blush.box1');
      await _storage.flushWrites();

      final int coins = _progress.coins;

      await restart();

      expect(_progress.openedGiftBoxes, hasLength(2));
      expect(_progress.isUnlocked('rose_glow'), isTrue);
      expect(_progress.coins, coins);
      // No re-grant on the next visit.
      expect(_controller.openGiftBox('blush.box1'), isNull);
      expect(_progress.coins, coins);
    });

    test('the gated reset is what clears the gift trail', () async {
      _controller.openGiftBox('blush.box1');
      expect(_progress.openedGiftBoxes, isNotEmpty);

      await _controller.resetProgress();
      await _storage.flushWrites();

      expect(_progress.openedGiftBoxes, isEmpty);
      expect(_progress.coins, 0);
    });
  });
}

// --- shared harness ---------------------------------------------------------

late ProviderContainer _container;
late ProgressController _controller;
final LocalStorageService _storage = LocalStorageService.instance;

ProgressState get _progress => _container.read(progressControllerProvider);

RoundState _round({int variant = 0}) {
  final NailColorOption color =
      NailCatalog.colors[variant % NailCatalog.colors.length];
  final DecorItem sticker =
      NailCatalog.stickers[variant % NailCatalog.stickers.length];

  return RoundState(
    characterId: 'kitty',
    studioStep: 4,
    shape: NailShape.round,
    colorId: color.id,
    patternId: 'plain',
    stickerId: sticker.id,
    ringId: 'ring_1',
  );
}
