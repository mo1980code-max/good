import 'achievement.dart';
import 'game_facts.dart';

/// Decides which achievements a child has just earned.
///
/// **Pure by design.** No widgets, no storage, no timers, no randomness:
/// the same facts + the same already-earned set always produce the same result.
/// That is what allows the whole reward system to be tested without launching
/// Flutter's UI (`test/achievement_engine_test.dart`).
///
/// The engine also owns the "never pay twice" rule: anything already in
/// [earnedIds] is filtered out *before* any reward is granted.
abstract final class AchievementEngine {
  /// Achievements the child just reached, in catalog order.
  static List<Achievement> newlyEarned({
    required GameFacts facts,
    required Set<String> earnedIds,
    List<Achievement> catalog = AchievementCatalog.all,
  }) {
    return catalog
        .where((Achievement achievement) => !earnedIds.contains(achievement.id))
        .where(
          (Achievement achievement) =>
              achievement.isMetBy(facts.valueOf(achievement.metric)),
        )
        .toList();
  }

  /// Progress towards every badge — used by the star wall.
  /// Never mutates anything; safe to call on each rebuild cheaply.
  static List<AchievementProgress> snapshot({
    required GameFacts facts,
    required Set<String> earnedIds,
    List<Achievement> catalog = AchievementCatalog.all,
  }) {
    return catalog
        .map(
          (Achievement achievement) => AchievementProgress(
            achievement: achievement,
            current: achievement.progressFrom(
              facts.valueOf(achievement.metric),
            ),
            earned: earnedIds.contains(achievement.id),
          ),
        )
        .toList();
  }

  /// Total rewards for a batch of newly earned badges.
  static ({int coins, int stars}) rewardFor(List<Achievement> achievements) {
    int coins = 0;
    int stars = 0;
    for (final Achievement achievement in achievements) {
      coins += achievement.coinReward;
      stars += achievement.starReward;
    }
    return (coins: coins, stars: stars);
  }

  /// Star-wall maths: how many wall rows are complete (10 designs per row) and
  /// how many stars are in the partial row. Pure, so the wall maths is tested.
  static ({int rows, int inRow, int starsShown}) wallLayout(
    int designs, {
    int perRow = 10,
  }) {
    if (perRow <= 0) return (rows: 0, inRow: 0, starsShown: 0);
    return (
      rows: designs ~/ perRow,
      inRow: designs % perRow,
      starsShown: designs,
    );
  }
}

/// One badge plus its live progress — a plain value object for the UI.
class AchievementProgress {
  const AchievementProgress({
    required this.achievement,
    required this.current,
    required this.earned,
  });

  final Achievement achievement;
  final int current;
  final bool earned;

  double get fraction => achievement.completionFrom(current);

  int get target => achievement.target;
}
