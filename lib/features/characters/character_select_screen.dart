import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../art/art_or_fallback.dart';
import '../../core/router/app_routes.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/sound_helper.dart';
import '../../data/models/character_model.dart';
import '../../features/game/game_providers.dart';
import '../../widgets/big_button.dart';
import '../../widgets/kid_screen.dart';
import '../../widgets/option_tile.dart';

/// Pick your friend — six originals, each with its own look and mood.
class CharacterSelectScreen extends ConsumerWidget {
  const CharacterSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String selectedId =
        ref.watch(roundControllerProvider.select((r) => r.characterId));

    return KidScreen(
      roomId: 'characters',
      center: const Text(
        'Pick a friend',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Fits both a small phone and a tablet without overflowing.
                final double tile =
                    ((constraints.maxWidth / 2) - 16).clamp(88.0, 190.0).toDouble();
                final double faceSize =
                    (tile * 0.72).clamp(60.0, 140.0).toDouble();

                return GridView.count(
                  crossAxisCount: Responsive.characterColumns(context),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.86,
                  children: <Widget>[
                    for (final CharacterModel character in CharacterModel.all)
                      Center(
                        child: OptionTile(
                          size: tile,
                          selected: character.id == selectedId,
                          accent: character.accent,
                          semanticLabel: character.name,
                          onTap: () {
                            ref
                                .read(roundControllerProvider.notifier)
                                .startRound(character.id);
                            SoundHelper.success();
                          },
                          child: CharacterArt(
                            character: character,
                            size: faceSize,
                            mood: character.id == selectedId
                                ? FaceMood.happy
                                : FaceMood.calm,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          BigButton(
            icon: Icons.auto_awesome_rounded,
            label: 'Start',
            onPressed: () {
              SoundHelper.sparkle();
              context.go(AppRoutes.spa);
            },
          ).animate().slideY(begin: 0.4, end: 0).fadeIn(duration: 300.ms),
        ],
      ),
    );
  }
}
