import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/assets.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/parent_gate.dart';
import '../../data/models/character_model.dart';
import '../../features/game/game_providers.dart';
import '../../widgets/big_button.dart';
import '../../widgets/character_face.dart';
import '../../widgets/counter_pill.dart';
import '../../widgets/cute_background.dart';
import '../../widgets/icon_bubble_button.dart';
import '../../widgets/motion.dart';
import '../../widgets/safe_asset_image.dart';

/// Home — three big doors: Play, Album, Gifts (+ the grown-ups corner).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int stars =
        ref.watch(progressControllerProvider.select((p) => p.stars));
    final int coins =
        ref.watch(progressControllerProvider.select((p) => p.coins));
    final int keys =
        ref.watch(progressControllerProvider.select((p) => p.keys));
    final CharacterModel character = ref.watch(selectedCharacterProvider);

    return KidPopScope(
      // The system back button must not close the game from Home.
      onBack: () {},
      child: CuteBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          _TopBar(stars: stars, coins: coins, keys: keys),
                          _Greeting(character: character),
                          const _Doors(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.stars, required this.coins, required this.keys});

  final int stars;
  final int coins;
  final int keys;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        CounterPill(
          icon: Icons.star_rounded,
          value: stars,
          color: AppColors.yellow,
        ),
        const SizedBox(width: 8),
        CounterPill(
          icon: Icons.monetization_on_rounded,
          value: coins,
          color: AppColors.mint,
        ),
        const SizedBox(width: 8),
        CounterPill(
          icon: Icons.vpn_key_rounded,
          value: keys,
          color: AppColors.peach,
        ),
        const Spacer(),
        // Settings stays behind the grown-ups gate (hold the star for 3s).
        ParentGate(
          onUnlocked: () => context.push(AppRoutes.settings),
          child: const IconBubbleButton(
            icon: Icons.settings_rounded,
            size: 58,
            iconColor: AppColors.lavender,
            // The gate owns the gesture; this button is only the visual.
            onPressed: null,
            appearsEnabled: true,
            semanticLabel: 'Grown-ups settings',
          ),
        ),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.character});

  final CharacterModel character;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        IdleBreathe(
          child: SafeAssetImage(
            asset: Assets.logo,
            width: 120,
            height: 120,
            fallbackIcon: Icons.auto_awesome_rounded,
            fallbackColor: AppColors.pink,
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(
              begin: const Offset(0.7, 0.7),
              end: const Offset(1, 1),
              duration: 600.ms,
              curve: Curves.elasticOut,
            ),
        const SizedBox(height: 2),
        const Text(
          'Sparkle Nail Spa',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            color: AppColors.textDeep,
          ),
        ),
        const SizedBox(height: 6),
        // The child's friend waves hello; tapping goes to the character picker.
        GestureDetector(
          onTap: () => context.go(AppRoutes.characters),
          child: IdleBreathe(
            scale: 1.04,
            child: CharacterFace(
              character: character,
              size: 132,
              mood: FaceMood.happy,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms);
  }
}

class _Doors extends StatelessWidget {
  const _Doors();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        BigButton(
          icon: Icons.play_arrow_rounded,
          label: 'Play',
          height: 96,
          iconSize: 44,
          onPressed: () => context.go(AppRoutes.characters),
        ).animate().slideY(begin: 0.35, end: 0).fadeIn(duration: 350.ms),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: BigButton(
                icon: Icons.photo_library_rounded,
                label: 'Album',
                color: AppColors.pink,
                height: 84,
                onPressed: () => context.go(AppRoutes.gallery),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BigButton(
                icon: Icons.card_giftcard_rounded,
                label: 'Gifts',
                color: AppColors.mint,
                height: 84,
                onPressed: () => context.go(AppRoutes.rewards),
              ),
            ),
          ],
        )
            .animate()
            .slideY(begin: 0.35, end: 0, delay: 100.ms)
            .fadeIn(delay: 100.ms, duration: 350.ms),
      ],
    );
  }
}
