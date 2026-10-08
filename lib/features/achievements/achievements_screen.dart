import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/achievements/achievement.dart';
import '../../core/achievements/achievement_engine.dart';
import '../../core/achievements/game_facts.dart';
import '../../core/animations/entrances.dart';
import '../../core/gift_rooms/gift_room_engine.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/progress_state.dart';
import '../../features/game/game_providers.dart';
import '../../widgets/big_button.dart';
import '../../widgets/counter_pill.dart';
import '../../widgets/kid_screen.dart';
import '../../widgets/motion.dart';

/// 🏆 Star Wall — the child's progress, made visible.
///
/// Three parts, all read-only:
///   1. the star counter + how many wall rows (10 designs each) are complete,
///   2. the badges: earned ones glow, the rest show *how close* they are,
///   3. the wall itself: a star per finished design.
///
/// Nothing here can be lost and nothing punishes: a locked badge shows
/// progress (3/6), never a lock or a fee.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  static const int starsPerRow = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProgressState progress = ref.watch(progressControllerProvider);
    final GameFacts facts = GameFacts.fromProgress(progress);

    final List<AchievementProgress> badges = AchievementEngine.snapshot(
      facts: facts,
      earnedIds: progress.achievements,
    );
    final int earnedCount =
        badges.where((AchievementProgress b) => b.earned).length;
    final ({int rows, int inRow, int starsShown}) wall =
        AchievementEngine.wallLayout(facts.designs, perRow: starsPerRow);

    // Badges open the last box of every gift room — so the wall also shows
    // the gift trail: how many boxes are opened, and how many are waiting.
    final int openedGifts = GiftRoomEngine.openedCount(progress.openedGiftBoxes);
    final bool giftWaiting = GiftRoomEngine.hasReadyGift(
      stars: progress.stars,
      badges: earnedCount,
      openedBoxes: progress.openedGiftBoxes,
    );

    return KidScreen(
      roomId: 'gallery',
      center: CounterPill(
        icon: Icons.workspace_premium_rounded,
        value: earnedCount,
        color: AppColors.lavender,
        size: 44,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: <Widget>[
          _StarSummary(progress: progress, rows: wall.rows),
          const SizedBox(height: 12),
          const EntranceItem(
            index: 1,
            child: _SectionTitle(
              icon: Icons.emoji_events_rounded,
              color: AppColors.yellow,
            ),
          ),
          const SizedBox(height: 6),
          for (int i = 0; i < badges.length; i++)
            EntranceItem(
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _BadgeTile(progress: badges[i]),
              ),
            ),
          const SizedBox(height: 8),
          const EntranceItem(
            index: 2,
            child: _SectionTitle(
              icon: Icons.grid_view_rounded,
              color: AppColors.mint,
            ),
          ),
          const SizedBox(height: 6),
          EntranceItem(
            index: 3,
            child: _StarWall(
              rows: wall.rows,
              inRow: wall.inRow,
              perRow: starsPerRow,
            ),
          ),
          const SizedBox(height: 12),
          EntranceItem(
            index: 4,
            child: Row(
              children: <Widget>[
                CounterPill(
                  icon: Icons.card_giftcard_rounded,
                  value: openedGifts,
                  color: AppColors.pink,
                  size: 42,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: BigButton(
                    icon: Icons.redeem_rounded,
                    label: 'Rooms',
                    color: giftWaiting ? AppColors.pink : AppColors.lavender,
                    height: 78,
                    onPressed: () => context.go(AppRoutes.gifts),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StarSummary extends StatelessWidget {
  const _StarSummary({required this.progress, required this.rows});

  final ProgressState progress;
  final int rows;

  @override
  Widget build(BuildContext context) {
    return EntranceItem(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.white, width: 3),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 14,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            CounterPill(
              icon: Icons.star_rounded,
              value: progress.stars,
              color: AppColors.yellow,
            ),
            CounterPill(
              icon: Icons.workspace_premium_rounded,
              value: progress.achievements.length,
              color: AppColors.lavender,
            ),
            CounterPill(
              icon: Icons.grid_view_rounded,
              value: rows,
              color: AppColors.mint,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        IdleBreathe(
          scale: 1.12,
          child: Icon(icon, size: 34, color: color),
        ),
      ],
    );
  }
}

/// One badge row: icon in a bubble, a progress bar, and a gentle check when
/// it has been earned. No locks, no prices, no deadlines.
class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.progress});

  final AchievementProgress progress;

  @override
  Widget build(BuildContext context) {
    final Achievement badge = progress.achievement;
    final bool earned = progress.earned;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: earned ? 0.95 : 0.72),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: earned ? (badge.color ?? AppColors.yellow) : AppColors.white,
          width: earned ? 3 : 2.5,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (badge.color ?? AppColors.yellow)
                  .withValues(alpha: earned ? 0.26 : 0.14),
            ),
            child: Icon(
              badge.icon,
              size: 28,
              color: earned
                  ? (badge.color ?? AppColors.yellow)
                  : AppColors.textSoft,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  badge.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  badge.hint,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSoft,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress.fraction,
                    minHeight: 10,
                    backgroundColor: AppColors.locked.withValues(alpha: 0.6),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      badge.color ?? AppColors.mint,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (earned)
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.mint,
              size: 30,
            )
          else
            Text(
              '${progress.current}/${progress.target}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textSoft,
              ),
            ),
        ],
      ),
    );
  }
}

/// The wall: one row per ten finished designs, filled with stars.
class _StarWall extends StatelessWidget {
  const _StarWall({
    required this.rows,
    required this.inRow,
    required this.perRow,
  });

  final int rows;
  final int inRow;
  final int perRow;

  @override
  Widget build(BuildContext context) {
    final int shownRows = rows + 1; // always show the row in progress

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.white, width: 3),
      ),
      child: Column(
        children: <Widget>[
          for (int row = 0; row < shownRows; row++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (int slot = 0; slot < perRow; slot++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Icon(
                        row < rows || slot < inRow
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 20,
                        color: row < rows || slot < inRow
                            ? AppColors.yellow
                            : AppColors.locked,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
