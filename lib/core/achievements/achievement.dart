import 'package:flutter/widgets.dart';

/// What an achievement measures. Every metric comes from data the game
/// already keeps, so nothing new has to be tracked in the background.
enum AchievementMetric {
  designs,
  spaSteps,
  distinctColors,
  distinctStickers,
  distinctRings,
  distinctPatterns,
  distinctCharacters,
  dailyStreak,
  boxesOpened,
}

/// One badge: an id, a friendly name, an icon and a target.
///
/// `target == 1` reads as "do it once"; anything else is a counter
/// (e.g. "try 6 different stickers").
@immutable
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.hint,
    required this.icon,
    required this.metric,
    required this.target,
    this.color,
    this.coinReward = 10,
    this.starReward = 1,
  });

  final String id;
  final String title;

  /// Short child/parent-friendly description (never required reading).
  final String hint;

  final IconData icon;
  final AchievementMetric metric;
  final int target;

  /// Optional accent; the UI falls back to a pastel rotation when null.
  final Color? color;

  final int coinReward;
  final int starReward;

  /// Progress towards this badge, clamped to the target. Pure maths.
  int progressFrom(int current) => current.clamp(0, target);

  bool isMetBy(int current) => current >= target;

  double completionFrom(int current) =>
      target <= 0 ? 1 : progressFrom(current) / target;
}

/// The full badge list — the only place achievements are defined.
abstract final class AchievementCatalog {
  static const List<Achievement> all = <Achievement>[
    // --- Finishing makeovers -------------------------------------------------
    Achievement(
      id: 'first_sparkle',
      title: 'First Sparkle',
      hint: 'Finish your very first design',
      icon: Icons.auto_awesome_rounded,
      metric: AchievementMetric.designs,
      target: 1,
    ),
    Achievement(
      id: 'master_artist',
      title: 'Master Artist',
      hint: 'Finish 10 designs',
      icon: Icons.palette_rounded,
      metric: AchievementMetric.designs,
      target: 10,
      coinReward: 25,
      starReward: 2,
    ),
    Achievement(
      id: 'gallery_wall',
      title: 'Gallery Wall',
      hint: 'Finish 25 designs',
      icon: Icons.photo_library_rounded,
      metric: AchievementMetric.designs,
      target: 25,
      coinReward: 40,
      starReward: 3,
    ),

    // --- Spa -----------------------------------------------------------------
    Achievement(
      id: 'spa_beginner',
      title: 'Soft Hands',
      hint: 'Complete 5 spa steps',
      icon: Icons.back_hand_rounded,
      metric: AchievementMetric.spaSteps,
      target: 5,
    ),
    Achievement(
      id: 'spa_master',
      title: 'Spa Day Star',
      hint: 'Complete 25 spa steps',
      icon: Icons.spa_rounded,
      metric: AchievementMetric.spaSteps,
      target: 25,
      coinReward: 25,
      starReward: 2,
    ),

    // --- Style exploration ---------------------------------------------------
    Achievement(
      id: 'color_explorer',
      title: 'Color Explorer',
      hint: 'Try 5 different polish colors',
      icon: Icons.color_lens_rounded,
      metric: AchievementMetric.distinctColors,
      target: 5,
    ),
    Achievement(
      id: 'rainbow_hands',
      title: 'Rainbow Hands',
      hint: 'Try 12 different polish colors',
      icon: Icons.gradient_rounded,
      metric: AchievementMetric.distinctColors,
      target: 12,
      coinReward: 40,
      starReward: 3,
    ),
    Achievement(
      id: 'sticker_lover',
      title: 'Sticker Lover',
      hint: 'Use 6 different stickers',
      icon: Icons.favorite_rounded,
      metric: AchievementMetric.distinctStickers,
      target: 6,
    ),
    Achievement(
      id: 'sticker_master',
      title: 'Sticker Master',
      hint: 'Use every sticker',
      icon: Icons.star_rounded,
      metric: AchievementMetric.distinctStickers,
      target: 12,
      coinReward: 40,
      starReward: 3,
    ),
    Achievement(
      id: 'ring_collector',
      title: 'Ring Collector',
      hint: 'Try 4 different rings',
      icon: Icons.circle_outlined,
      metric: AchievementMetric.distinctRings,
      target: 4,
      coinReward: 20,
    ),
    Achievement(
      id: 'pattern_player',
      title: 'Pattern Player',
      hint: 'Try 4 different patterns',
      icon: Icons.brush_rounded,
      metric: AchievementMetric.distinctPatterns,
      target: 4,
      coinReward: 20,
    ),

    // --- Friends -------------------------------------------------------------
    Achievement(
      id: 'best_friends',
      title: 'Best Friends',
      hint: 'Make a design for all six friends',
      icon: Icons.people_alt_rounded,
      metric: AchievementMetric.distinctCharacters,
      target: 6,
      coinReward: 30,
      starReward: 2,
    ),

    // --- Coming back ---------------------------------------------------------
    Achievement(
      id: 'regular_visitor',
      title: 'Regular Visitor',
      hint: 'Open the daily gift 3 days in a row',
      icon: Icons.card_giftcard_rounded,
      metric: AchievementMetric.dailyStreak,
      target: 3,
      coinReward: 25,
    ),
    Achievement(
      id: 'surprise_opener',
      title: 'Surprise Opener',
      hint: 'Open 3 surprise boxes',
      icon: Icons.vpn_key_rounded,
      metric: AchievementMetric.boxesOpened,
      target: 3,
      coinReward: 25,
    ),
  ];

  static Achievement? byId(String id) {
    for (final Achievement achievement in all) {
      if (achievement.id == id) return achievement;
    }
    return null;
  }
}
