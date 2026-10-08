import 'package:flutter_test/flutter_test.dart';
import 'package:sparkle_nail_spa/core/achievements/achievement.dart';
import 'package:sparkle_nail_spa/core/achievements/achievement_engine.dart';
import 'package:sparkle_nail_spa/core/achievements/game_facts.dart';
import 'package:sparkle_nail_spa/data/models/gallery_item.dart';
import 'package:sparkle_nail_spa/data/models/progress_state.dart';

/// The achievements engine is pure: no widgets, no storage, no timers.
/// These tests therefore need nothing but Dart — they can run on CI too.
void main() {
  GalleryItem design({
    String id = '1',
    String character = 'kitty',
    String color = 'pink',
    String sticker = 'star',
    String ring = 'ring_1',
    String pattern = 'plain',
  }) {
    return GalleryItem(
      id: id,
      characterId: character,
      shapeId: 'round',
      colorId: color,
      patternId: pattern,
      stickerId: sticker,
      ringId: ring,
      createdAtMs: 0,
    );
  }

  group('newlyEarned', () {
    test('an empty child has earned nothing', () {
      final List<Achievement> earned = AchievementEngine.newlyEarned(
        facts: GameFacts.empty,
        earnedIds: const <String>{},
      );
      expect(earned, isEmpty);
    });

    test('the first finished design unlocks First Sparkle only', () {
      final List<Achievement> earned = AchievementEngine.newlyEarned(
        facts: GameFacts.empty.copyWith(designs: 1),
        earnedIds: const <String>{},
      );
      expect(earned.map((Achievement a) => a.id), <String>['first_sparkle']);
    });

    test('an already-earned badge is never returned twice', () {
      final List<Achievement> earned = AchievementEngine.newlyEarned(
        facts: GameFacts.empty.copyWith(designs: 30, spaSteps: 30),
        earnedIds: const <String>{
          'first_sparkle',
          'master_artist',
          'gallery_wall',
          'spa_beginner',
          'spa_master',
        },
      );
      expect(earned, isEmpty);
    });

    test('several badges can land in one round', () {
      final List<Achievement> earned = AchievementEngine.newlyEarned(
        facts: GameFacts.empty.copyWith(designs: 1, spaSteps: 5),
        earnedIds: const <String>{},
      );
      expect(
        earned.map((Achievement a) => a.id),
        containsAll(<String>['first_sparkle', 'spa_beginner']),
      );
    });

    test('targets are respected exactly at the boundary', () {
      // 4 colours = not yet, 5 colours = earned
      expect(
        AchievementEngine.newlyEarned(
          facts: GameFacts.empty.copyWith(distinctColors: 4),
          earnedIds: const <String>{},
        ),
        isEmpty,
      );
      expect(
        AchievementEngine.newlyEarned(
          facts: GameFacts.empty.copyWith(distinctColors: 5),
          earnedIds: const <String>{},
        ).map((Achievement a) => a.id),
        contains('color_explorer'),
      );
    });

    test('evaluation is deterministic', () {
      final GameFacts facts = GameFacts.empty.copyWith(designs: 7, spaSteps: 12);
      final List<Achievement> first = AchievementEngine.newlyEarned(
        facts: facts,
        earnedIds: const <String>{},
      );
      final List<Achievement> second = AchievementEngine.newlyEarned(
        facts: facts,
        earnedIds: const <String>{},
      );
      expect(
        first.map((Achievement a) => a.id).toList(),
        second.map((Achievement a) => a.id).toList(),
      );
    });
  });

  group('GameFacts.fromProgress', () {
    test('counts distinct choices from the album, not the number of designs', () {
      final ProgressState progress = ProgressState(
        gallery: <GalleryItem>[
          design(id: '1', color: 'pink', sticker: 'star'),
          design(id: '2', color: 'pink', sticker: 'heart'),
          design(id: '3', color: 'mint', sticker: 'star'),
        ],
      );

      final GameFacts facts = GameFacts.fromProgress(progress);

      expect(facts.designs, 3);
      expect(facts.distinctColors, 2);
      expect(facts.distinctStickers, 2);
      expect(facts.distinctRings, 1);
      expect(facts.distinctCharacters, 1);
    });

    test('uses the saved counters for spa steps and boxes', () {
      const ProgressState progress = ProgressState(
        spaStepsCompleted: 17,
        boxesOpened: 2,
        dailyStreak: 4,
      );

      final GameFacts facts = GameFacts.fromProgress(progress);

      expect(facts.spaSteps, 17);
      expect(facts.boxesOpened, 2);
      expect(facts.dailyStreak, 4);
    });

    test('valueOf maps every metric (no metric can silently read the wrong number)',
        () {
      const GameFacts facts = GameFacts(
        designs: 1,
        spaSteps: 2,
        distinctColors: 3,
        distinctStickers: 4,
        distinctRings: 5,
        distinctPatterns: 6,
        distinctCharacters: 7,
        dailyStreak: 8,
        boxesOpened: 9,
      );

      expect(facts.valueOf(AchievementMetric.designs), 1);
      expect(facts.valueOf(AchievementMetric.spaSteps), 2);
      expect(facts.valueOf(AchievementMetric.distinctColors), 3);
      expect(facts.valueOf(AchievementMetric.distinctStickers), 4);
      expect(facts.valueOf(AchievementMetric.distinctRings), 5);
      expect(facts.valueOf(AchievementMetric.distinctPatterns), 6);
      expect(facts.valueOf(AchievementMetric.distinctCharacters), 7);
      expect(facts.valueOf(AchievementMetric.dailyStreak), 8);
      expect(facts.valueOf(AchievementMetric.boxesOpened), 9);
    });
  });

  group('rewards', () {
    test('a batch sums its coins and stars', () {
      final List<Achievement> batch = <Achievement>[
        AchievementCatalog.byId('first_sparkle')!,
        AchievementCatalog.byId('master_artist')!,
      ];

      final ({int coins, int stars}) reward =
          AchievementEngine.rewardFor(batch);

      expect(reward.coins, 10 + 25);
      expect(reward.stars, 1 + 2);
    });

    test('an empty batch pays nothing', () {
      final ({int coins, int stars}) reward =
          AchievementEngine.rewardFor(const <Achievement>[]);
      expect(reward.coins, 0);
      expect(reward.stars, 0);
    });

    test('every badge pays at least something (no dead rewards)', () {
      for (final Achievement achievement in AchievementCatalog.all) {
        expect(achievement.coinReward, greaterThan(0));
        expect(achievement.starReward, greaterThan(0));
      }
    });

    test('badge ids are unique', () {
      final Set<String> ids =
          AchievementCatalog.all.map((Achievement a) => a.id).toSet();
      expect(ids.length, AchievementCatalog.all.length);
    });
  });

  group('snapshot (star wall data)', () {
    test('reports progress, caps it at the target, and marks earned badges', () {
      final List<AchievementProgress> wall = AchievementEngine.snapshot(
        facts: GameFacts.empty.copyWith(designs: 30, distinctColors: 50),
        earnedIds: const <String>{'first_sparkle'},
      );

      final AchievementProgress first = wall
          .firstWhere((AchievementProgress b) => b.achievement.id == 'first_sparkle');
      expect(first.earned, isTrue);

      final AchievementProgress rainbow = wall.firstWhere(
        (AchievementProgress b) => b.achievement.id == 'rainbow_hands',
      );
      expect(rainbow.current, 12, reason: 'capped at the target, never above');
      expect(rainbow.fraction, 1.0);
    });

    test('a fresh child sees 0 progress everywhere', () {
      final List<AchievementProgress> wall = AchievementEngine.snapshot(
        facts: GameFacts.empty,
        earnedIds: const <String>{},
      );
      expect(wall.every((AchievementProgress b) => b.current == 0), isTrue);
      expect(wall.every((AchievementProgress b) => !b.earned), isTrue);
    });
  });

  group('wall layout maths', () {
    test('0 designs -> no rows, empty current row', () {
      final ({int rows, int inRow, int starsShown}) wall =
          AchievementEngine.wallLayout(0);
      expect(wall.rows, 0);
      expect(wall.inRow, 0);
    });

    test('9 designs -> still the first row', () {
      final ({int rows, int inRow, int starsShown}) wall =
          AchievementEngine.wallLayout(9, perRow: 10);
      expect(wall.rows, 0);
      expect(wall.inRow, 9);
    });

    test('23 designs -> 2 full rows and 3 stars in the third', () {
      final ({int rows, int inRow, int starsShown}) wall =
          AchievementEngine.wallLayout(23, perRow: 10);
      expect(wall.rows, 2);
      expect(wall.inRow, 3);
    });

    test('a zero row size can never divide by zero', () {
      final ({int rows, int inRow, int starsShown}) wall =
          AchievementEngine.wallLayout(5, perRow: 0);
      expect(wall.rows, 0);
      expect(wall.inRow, 0);
    });
  });

  group('stars can never be lost', () {
    test('ProgressState only grows when rewards are added', () {
      const ProgressState before = ProgressState(stars: 12, coins: 40);
      final ProgressState after = before.copyWith(
        stars: before.stars + 3,
        coins: before.coins + 25,
      );
      expect(after.stars, greaterThan(before.stars));
      expect(after.coins, greaterThan(before.coins));
    });

    test('newly earned badges are recorded, never removed', () {
      const ProgressState earned = ProgressState(
        achievements: <String>{'first_sparkle'},
      );
      final ProgressState more = earned.copyWith(
        achievements: <String>{...earned.achievements, 'spa_beginner'},
      );
      expect(more.achievements, containsAll(<String>['first_sparkle', 'spa_beginner']));
    });
  });
}
