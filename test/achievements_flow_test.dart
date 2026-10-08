import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparkle_nail_spa/core/achievements/achievement.dart';
import 'package:sparkle_nail_spa/core/achievements/achievement_engine.dart';
import 'package:sparkle_nail_spa/data/models/gallery_item.dart';
import 'package:sparkle_nail_spa/data/models/nail_item_model.dart';
import 'package:sparkle_nail_spa/data/models/progress_state.dart';
import 'package:sparkle_nail_spa/data/models/round_state.dart';
import 'package:sparkle_nail_spa/data/repositories/local_storage_service.dart';
import 'package:sparkle_nail_spa/features/game/game_providers.dart';

/// The reward questions from the review, answered by running the real
/// controller — no Flutter UI is needed, because the achievements engine is
/// pure and the progress repository is a thin, testable layer.
///
///   1. every achievement is granted exactly once,
///   2. reopening the album never pays extra stars,
///   3. opening a gift box never repeats a reward,
///   4. achievements survive closing the app,
///   5. cumulative goals are counted correctly,
///   6. the gated reset is the only thing that clears progress,
///   7. a v1 save loads unchanged, and a double tap cannot twin a design.
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

  /// Simulates "the app was closed and opened again": the storage singleton
  /// forgets its cache, then a brand-new container reads the save file.
  Future<void> restart() async {
    _container.dispose();
    _storage.resetForTests();
    await _storage.init();
    _container = ProviderContainer();
    _controller = _container.read(progressControllerProvider.notifier);
  }

  // -------------------------------------------------------------------------
  group('1. a badge is granted exactly once', () {
    test('the first design pays once, and a second claim pays nothing',
        () async {
      _controller.completeRound(_round());
      await _storage.flushWrites();

      final List<Achievement> first = _claim();
      expect(first.map((Achievement a) => a.id), contains('first_sparkle'));

      final int starsAfterFirst = _progress.stars;
      final int coinsAfterFirst = _progress.coins;

      expect(_controller.pendingAchievements(), isEmpty);
      expect(_claim(), isEmpty);
      expect(_progress.stars, starsAfterFirst);
      expect(_progress.coins, coinsAfterFirst);
      expect(
        _progress.achievements.where((String id) => id == 'first_sparkle'),
        hasLength(1),
      );
    });

    test('the engine also refuses to hand out an already-earned badge', () {
      final List<Achievement> again = AchievementEngine.newlyEarned(
        facts: _controller.facts.copyWith(designs: 99),
        earnedIds: <String>{'first_sparkle', 'master_artist', 'gallery_wall'},
      );
      expect(again, isEmpty);
    });

    test('a badge is not paid twice in one session', () {
      _controller.recordSpaSteps(25);
      expect(_claim().map((Achievement a) => a.id), contains('spa_master'));

      final int stars = _progress.stars;
      expect(_claim(), isEmpty);
      expect(_progress.stars, stars);
    });
  });

  // -------------------------------------------------------------------------
  group('2. reopening the album never adds stars', () {
    test('reading progress again does not pay anything', () async {
      _controller.completeRound(_round());
      _claim();
      await _storage.flushWrites();

      final int stars = _progress.stars;

      for (int i = 0; i < 5; i++) {
        expect(_claim(), isEmpty);
      }

      // A rebuild of the notifier — what happens when the app is resumed.
      _container.invalidate(progressControllerProvider);
      _container.read(progressControllerProvider);

      expect(_claim(), isEmpty);
      expect(_progress.stars, stars);
    });

    test('pendingAchievements is strictly read-only', () {
      _controller.completeRound(_round());
      final int stars = _progress.stars;
      final int badgeCount = _progress.achievements.length;

      _controller.pendingAchievements();
      _controller.pendingAchievements();

      expect(_progress.stars, stars);
      expect(_progress.achievements.length, badgeCount);
    });
  });

  // -------------------------------------------------------------------------
  group('3. boxes never pay twice', () {
    test('opening more boxes cannot re-earn the badge', () async {
      _controller.recordBoxOpened();
      _controller.recordBoxOpened();
      _controller.recordBoxOpened();
      await _storage.flushWrites();

      expect(_claim().map((Achievement a) => a.id), contains('surprise_opener'));

      final int stars = _progress.stars;
      final int coins = _progress.coins;

      for (int i = 0; i < 3; i++) {
        _controller.recordBoxOpened();
        expect(_claim(), isEmpty);
      }

      expect(_progress.stars, stars);
      expect(_progress.coins, coins);
    });
  });

  // -------------------------------------------------------------------------
  group('4. badges survive closing the app', () {
    test('the same badges come back after a restart, with no extra pay',
        () async {
      _controller.completeRound(_round());
      _controller.recordSpaSteps(5);
      final List<Achievement> earned = _claim();
      await _storage.flushWrites();

      final int stars = _progress.stars;
      final Set<String> ids = Set<String>.from(_progress.achievements);
      expect(ids, isNotEmpty);
      expect(earned.map((Achievement a) => a.id), contains('first_sparkle'));

      await restart();

      expect(_progress.achievements, containsAll(ids));
      expect(_progress.stars, stars);
      expect(_controller.pendingAchievements(), isEmpty);
      expect(_claim(), isEmpty);
      expect(_progress.stars, stars);
    });
  });

  // -------------------------------------------------------------------------
  group('5. cumulative goals are counted correctly', () {
    test('4 steps are not a badge, 5 are, 25 are the second', () {
      _controller.recordSpaSteps(4);
      expect(_claim(), isEmpty, reason: '4 of 5 is not a badge yet');

      _controller.recordSpaSteps(1);
      expect(_claim().map((Achievement a) => a.id), <String>['spa_beginner']);

      _controller.recordSpaSteps(20); // 25 in total
      expect(_claim().map((Achievement a) => a.id), <String>['spa_master']);
      expect(_progress.spaStepsCompleted, 25);
    });

    test('10 designs pay Master Artist, and progress never overshoots', () {
      for (int i = 0; i < 10; i++) {
        _controller.completeRound(_round(variant: i));
      }

      final List<Achievement> earned = _claim();
      expect(earned.map((Achievement a) => a.id), contains('master_artist'));
      expect(_progress.gallery, hasLength(10));

      final List<AchievementProgress> snapshot = AchievementEngine.snapshot(
        facts: _controller.facts,
        earnedIds: _progress.achievements,
      );
      for (final AchievementProgress row in snapshot) {
        expect(row.fraction, lessThanOrEqualTo(1.0));
        expect(row.current, lessThanOrEqualTo(row.target));
      }
    });

    test('designs in different colours drive the colour badge', () {
      for (int i = 0; i < 5; i++) {
        _controller.completeRound(_round(variant: i));
      }
      expect(_claim().map((Achievement a) => a.id), contains('color_explorer'));
    });
  });

  // -------------------------------------------------------------------------
  group('6. only the gated reset clears progress', () {
    test('resetProgress clears badges, stars and counters', () async {
      _controller.completeRound(_round());
      _controller.recordSpaSteps(5);
      _controller.recordBoxOpened();
      _claim();
      await _storage.flushWrites();
      expect(_progress.achievements, isNotEmpty);

      await _controller.resetProgress();
      await _storage.flushWrites();

      expect(_progress.achievements, isEmpty);
      expect(_progress.stars, 0);
      expect(_progress.spaStepsCompleted, 0);
      expect(_progress.boxesOpened, 0);
      expect(_progress.gallery, isEmpty);

      // …and the save file agrees, even after a restart.
      await restart();
      expect(_progress.achievements, isEmpty);
      expect(_progress.stars, 0);
    });

    test('nothing else in the API can drop a badge', () async {
      _controller.completeRound(_round());
      _claim();
      final Set<String> ids = Set<String>.from(_progress.achievements);

      _controller.recordSpaSteps(1);
      _controller.recordBoxOpened();
      _controller.addCoins(5);
      _controller.grantUnlock('lilac');
      _controller.attachImage('does-not-exist', 'x.png');
      await _storage.flushWrites();

      expect(_progress.achievements, containsAll(ids));
    });
  });

  // -------------------------------------------------------------------------
  group('7. save compatibility and no twin designs', () {
    test('a v1 save loads with nothing lost', () async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'sparkle.progress',
        jsonEncode(<String, dynamic>{
          'stars': 7,
          'coins': 12,
          'keys': 1,
          'dailyStreak': 2,
          'unlocked': <String>['lilac'],
          'gallery': <Object?>[
            <String, dynamic>{
              'id': '555',
              'characterId': 'bunny',
              'shapeId': 'round',
              'colorId': 'pink',
              'patternId': 'plain',
              'stickerId': 'star',
              'ringId': 'ring_1',
              'createdAtMs': 1,
              'imageFileName': 'design_555.png',
            },
          ],
        }),
      );

      await restart();

      expect(_progress.stars, 7);
      expect(_progress.coins, 12);
      expect(_progress.keys, 1);
      expect(_progress.dailyStreak, 2);
      expect(_progress.unlockedItemIds, contains('lilac'));
      expect(_progress.gallery, hasLength(1));
      expect(_progress.gallery.single.imageFileName, 'design_555.png');
      // New fields simply start empty — nothing was rewritten or dropped.
      expect(_progress.achievements, isEmpty);
      expect(_progress.openedGiftBoxes, isEmpty);
    });

    test('a double tap on Done cannot create a twin design', () {
      final RoundState round = _round();
      final GalleryItem first = _controller.completeRound(round);
      final GalleryItem second = _controller.completeRound(round);

      expect(second.id, first.id);
      expect(_progress.gallery, hasLength(1));
      expect(_progress.stars, 3, reason: 'one round, one reward');
    });

    test('two different rounds do produce two designs', () {
      _controller.completeRound(_round());
      _controller.completeRound(_round(variant: 1));
      expect(_progress.gallery, hasLength(2));
    });
  });
}

// --- shared harness ---------------------------------------------------------

late ProviderContainer _container;
late ProgressController _controller;
final LocalStorageService _storage = LocalStorageService.instance;

ProgressState get _progress => _container.read(progressControllerProvider);

List<Achievement> _claim() => _controller.claimAchievements(
      _controller.pendingAchievements(),
    );

/// A finished round. [variant] changes the recipe (colour + sticker), which is
/// what makes two rounds two different designs.
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
