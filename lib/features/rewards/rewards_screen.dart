import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/sound_helper.dart';
import '../../data/models/nail_item_model.dart';
import '../../features/game/game_providers.dart';
import '../../features/game/progress_controller.dart';
import '../../widgets/big_button.dart';
import '../../widgets/counter_pill.dart';
import '../../widgets/design_preview.dart';
import '../../widgets/kid_screen.dart';
import '../../widgets/motion.dart';

/// Rewards — the daily gift and the surprise box.
class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final int coins =
        ref.watch(progressControllerProvider.select((p) => p.coins));
    final int keys =
        ref.watch(progressControllerProvider.select((p) => p.keys));
    final int streak =
        ref.watch(progressControllerProvider.select((p) => p.dailyStreak));

    final ProgressController controller =
        ref.read(progressControllerProvider.notifier);
    final bool canClaim = controller.canClaimDailyReward();

    return KidScreen(
      center: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CounterPill(
            icon: Icons.monetization_on_rounded,
            value: coins,
            color: AppColors.mint,
            size: 44,
          ),
          const SizedBox(width: 8),
          CounterPill(
            icon: Icons.vpn_key_rounded,
            value: keys,
            color: AppColors.peach,
            size: 44,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _StreakRow(streak: streak),
          const SizedBox(height: 10),
          Expanded(
            child: _GiftCard(
              canClaim: canClaim,
              busy: _busy,
              onOpen: _claimDailyGift,
            ),
          ),
          const SizedBox(height: 10),
          BigButton(
            icon: keys > 0
                ? Icons.card_giftcard_rounded
                : Icons.lock_rounded,
            label: 'Surprise',
            color: AppColors.lavender,
            height: 84,
            enabled: keys > 0 && !_busy,
            onPressed: _openSurpriseBox,
          ),
          const SizedBox(height: 10),
          BigButton(
            icon: Icons.home_rounded,
            height: 70,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
    );
  }

  // --- Daily gift ----------------------------------------------------------

  Future<void> _claimDailyGift() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bool claimed =
          await ref.read(progressControllerProvider.notifier).claimDailyReward();
      if (!mounted) return;
      if (!claimed) return;

      await SoundHelper.sparkle();
      if (!mounted) return;
      await _celebrate(
        icon: Icons.card_giftcard_rounded,
        color: AppColors.pink,
        badge: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // --- Surprise box --------------------------------------------------------

  Future<void> _openSurpriseBox() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final ProgressController controller =
          ref.read(progressControllerProvider.notifier);
      if (!controller.spendKeys(1)) return;

      final _Prize prize = _rollPrize();
      if (prize.itemId != null) {
        controller.grantUnlock(prize.itemId!);
      } else {
        controller.addCoins(60);
      }

      await SoundHelper.sparkle();
      if (!mounted) return;
      await _celebrate(
        icon: prize.icon,
        color: prize.color,
        badge: prize.itemId == null,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  _Prize _rollPrize() {
    final Set<String> unlocked =
        ref.read(progressControllerProvider).unlockedItemIds;

    final List<_Prize> pool = <_Prize>[
      for (final NailColorOption option in NailCatalog.colors)
        if (option.price > 0 && !unlocked.contains(option.id))
          _Prize(
            itemId: option.id,
            icon: Icons.palette_rounded,
            color: option.color,
          ),
      for (final DecorItem item in NailCatalog.stickers)
        if (item.price > 0 && !unlocked.contains(item.id))
          _Prize(
            itemId: item.id,
            icon: stickerIcon(item.id),
            color: AppColors.pink,
          ),
      for (final DecorItem item in NailCatalog.rings)
        if (item.price > 0 && !unlocked.contains(item.id))
          _Prize(
            itemId: item.id,
            icon: ringIcon(item.id),
            color: AppColors.lavender,
          ),
    ];

    if (pool.isEmpty) {
      return const _Prize(
        icon: Icons.monetization_on_rounded,
        color: AppColors.yellow,
      );
    }
    return pool[math.Random().nextInt(pool.length)];
  }

  Future<void?> _celebrate({
    required IconData icon,
    required Color color,
    required bool badge,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IdleBreathe(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: <Color>[color, AppColors.white],
                    ),
                  ),
                  child: Icon(icon, size: 64, color: AppColors.white),
                ),
              )
                  .animate()
                  .scale(
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                    begin: const Offset(0.3, 0.3),
                    end: const Offset(1, 1),
                  )
                  .then()
                  .shake(duration: 600.ms),
              const SizedBox(height: 14),
              if (badge)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.monetization_on_rounded,
                      color: AppColors.yellow,
                      size: 36,
                    ),
                    Icon(
                      Icons.vpn_key_rounded,
                      color: AppColors.peach,
                      size: 36,
                    ),
                  ],
                ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Icon(
                Icons.star_rounded,
                size: 40,
                color: AppColors.yellow,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Prize {
  const _Prize({required this.icon, required this.color, this.itemId});

  final IconData icon;
  final Color color;
  final String? itemId;
}

class _StreakRow extends StatelessWidget {
  const _StreakRow({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final int filled = streak.clamp(0, 7);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < 7; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Icon(
              i < filled ? Icons.star_rounded : Icons.star_border_rounded,
              color: i < filled ? AppColors.yellow : AppColors.locked,
              size: 26,
            ),
          ),
      ],
    );
  }
}

class _GiftCard extends StatelessWidget {
  const _GiftCard({
    required this.canClaim,
    required this.busy,
    required this.onOpen,
  });

  final bool canClaim;
  final bool busy;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: AppColors.white, width: 3),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (canClaim)
            IdleBreathe(
              scale: 1.08,
              child: const Icon(
                Icons.card_giftcard_rounded,
                size: 110,
                color: AppColors.pink,
              ),
            )
          else
            const Icon(
              Icons.nightlight_round,
              size: 100,
              color: AppColors.lavender,
            ),
          const SizedBox(height: 12),
          BigButton(
            icon: canClaim ? Icons.redeem_rounded : Icons.check_rounded,
            height: 84,
            color: canClaim ? AppColors.pink : AppColors.locked,
            enabled: canClaim && !busy,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}
