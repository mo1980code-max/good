import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/sound_helper.dart';
import '../../data/models/character_model.dart';
import '../../data/models/nail_item_model.dart';
import '../../data/models/progress_state.dart';
import '../../data/models/round_state.dart';
import '../../features/game/game_providers.dart';
import '../../widgets/big_button.dart';
import '../../widgets/character_face.dart';
import '../../widgets/counter_pill.dart';
import '../../widgets/design_preview.dart';
import '../../widgets/kid_screen.dart';
import '../../widgets/option_tile.dart';
import '../../widgets/safe_asset_image.dart';

/// Nail studio — shape, color, pattern, sticker, ring.
///
/// Locked items stay visible: tapping one buys it with coins (with a friendly
/// nudge when the purse is empty). Long-press clears the current step.
class NailStudioScreen extends ConsumerWidget {
  const NailStudioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RoundState round = ref.watch(roundControllerProvider);
    final ProgressState progress = ref.watch(progressControllerProvider);
    final CharacterModel character = ref.watch(selectedCharacterProvider);
    final RoundController controller =
        ref.read(roundControllerProvider.notifier);

    final NailColorOption color =
        round.colorId == null ? NailCatalog.colors.first : NailCatalog.colorById(round.colorId);
    final NailPattern pattern = NailCatalog.patternById(round.patternId);
    final DecorItem sticker = NailCatalog.stickerById(round.stickerId);
    final DecorItem ring = NailCatalog.ringById(round.ringId);

    return KidScreen(
      roomId: 'studio',
      center: StepDots(
        count: RoundState.studioStepCount,
        current: round.studioStep,
      ),
      sparkles: false,
      body: Column(
        children: <Widget>[
          Expanded(
            child: Stack(
              children: <Widget>[
                // Live preview of the design so far.
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(color: AppColors.white, width: 3),
                    ),
                    child: DesignPreview(
                      shape: round.shape,
                      colorOption: round.colorId == null ? null : color,
                      pattern: round.patternId == null ? null : pattern,
                      sticker: round.stickerId == null ? null : sticker,
                      ring: round.ringId == null ? null : ring,
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: CharacterFace(
                    character: character,
                    size: 74,
                    mood: FaceMood.happy,
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 14,
                  child: CounterPill(
                    icon: Icons.monetization_on_rounded,
                    value: progress.coins,
                    color: AppColors.mint,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 108,
            child: _StepOptions(
              round: round,
              progress: progress,
              controller: controller,
            ),
          ),
          const SizedBox(height: 8),
          _ContinueButton(round: round, controller: controller),
        ],
      ),
    );
  }
}

class _StepOptions extends ConsumerWidget {
  const _StepOptions({
    required this.round,
    required this.progress,
    required this.controller,
  });

  final RoundState round;
  final ProgressState progress;
  final RoundController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (round.studioStep) {
      0 => _ShapeRow(round: round, controller: controller),
      1 => _ColorRow(
          round: round,
          progress: progress,
          controller: controller,
        ),
      2 => _PatternRow(
          round: round,
          progress: progress,
          controller: controller,
        ),
      3 => _StickerRow(
          round: round,
          progress: progress,
          controller: controller,
        ),
      _ => _RingRow(round: round, progress: progress, controller: controller),
    };
  }
}

/// Shared horizontal scroller for every option row.
class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      itemCount: children.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (context, index) => Center(child: children[index]),
    );
  }
}

/// Returns true when the item may be used (free or already unlocked).
/// Handles the purchase + the "not enough coins" nudge.
bool _ensureUnlocked(
  BuildContext context,
  WidgetRef ref,
  String id,
  int price,
) {
  if (price <= 0) return true;

  final ProgressController progress =
      ref.read(progressControllerProvider.notifier);
  if (progress.canUse(id, price: price)) return true;

  if (progress.unlock(id, price: price)) {
    SoundHelper.success();
    return true;
  }

  SoundHelper.pop();
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Need more coins'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.monetization_on_rounded,
            size: 64,
            color: AppColors.yellow,
          ),
          const SizedBox(height: 8),
          Text(
            '$price',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(Icons.star_rounded, color: AppColors.yellow),
        ),
      ],
    ),
  );
  return false;
}

// --- Step 1: shape ----------------------------------------------------------

class _ShapeRow extends StatelessWidget {
  const _ShapeRow({required this.round, required this.controller});

  final RoundState round;
  final RoundController controller;

  @override
  Widget build(BuildContext context) {
    return _OptionRow(
      children: <Widget>[
        for (final NailShape shape in NailShape.values)
          OptionTile(
            size: 88,
            selected: round.shape == shape,
            semanticLabel: shape.label,
            onTap: () {
              controller.selectShape(shape);
              SoundHelper.tap();
            },
            child: SizedBox(
              width: 42,
              height: 58,
              child: NailSwatch(
                shape: shape,
                color: NailCatalog
                    .colorById(round.colorId)
                    .color,
              ),
            ),
          ),
      ],
    );
  }
}

// --- Step 2: color ----------------------------------------------------------

class _ColorRow extends ConsumerWidget {
  const _ColorRow({
    required this.round,
    required this.progress,
    required this.controller,
  });

  final RoundState round;
  final ProgressState progress;
  final RoundController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _OptionRow(
      children: <Widget>[
        for (final NailColorOption option in NailCatalog.colors)
          OptionTile(
            size: 78,
            accent: option.color,
            selected: round.colorId == option.id,
            locked: !progress.canUse(option.id, price: option.price),
            price: option.price,
            semanticLabel: option.label,
            onTap: () {
              if (!_ensureUnlocked(context, ref, option.id, option.price)) {
                return;
              }
              controller.selectColor(option.id);
              SoundHelper.sparkle();
            },
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: option.color,
                border: Border.all(color: AppColors.white, width: 3),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: option.color.withValues(alpha: 0.45),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// --- Step 3: pattern --------------------------------------------------------

class _PatternRow extends ConsumerWidget {
  const _PatternRow({
    required this.round,
    required this.progress,
    required this.controller,
  });

  final RoundState round;
  final ProgressState progress;
  final RoundController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color base = NailCatalog.colorById(round.colorId).color;

    return _OptionRow(
      children: <Widget>[
        for (final NailPattern pattern in NailCatalog.patterns)
          OptionTile(
            size: 84,
            selected: round.patternId == pattern.id,
            locked: !progress.canUse(pattern.id, price: pattern.price),
            price: pattern.price,
            semanticLabel: pattern.label,
            onTap: () {
              if (!_ensureUnlocked(context, ref, pattern.id, pattern.price)) {
                return;
              }
              controller.selectPattern(pattern.id);
              SoundHelper.sparkle();
            },
            child: SizedBox(
              width: 40,
              height: 54,
              child: NailSwatch(
                shape: round.shape ?? NailShape.round,
                color: base,
                patternId: pattern.id,
              ),
            ),
          ),
      ],
    );
  }
}

// --- Step 4: sticker --------------------------------------------------------

class _StickerRow extends ConsumerWidget {
  const _StickerRow({
    required this.round,
    required this.progress,
    required this.controller,
  });

  final RoundState round;
  final ProgressState progress;
  final RoundController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _OptionRow(
      children: <Widget>[
        for (final DecorItem item in NailCatalog.stickers)
          OptionTile(
            size: 84,
            selected: round.stickerId == item.id,
            locked: !progress.canUse(item.id, price: item.price),
            price: item.price,
            semanticLabel: item.label,
            onTap: () {
              if (!_ensureUnlocked(context, ref, item.id, item.price)) return;
              controller.selectSticker(item.id);
              SoundHelper.pop();
            },
            child: SafeAssetImage(
              asset: item.asset,
              width: 46,
              height: 46,
              fallbackIcon: stickerIcon(item.id),
              fallbackColor: AppColors.pink,
            ),
          ),
      ],
    );
  }
}

// --- Step 5: ring -----------------------------------------------------------

class _RingRow extends ConsumerWidget {
  const _RingRow({
    required this.round,
    required this.progress,
    required this.controller,
  });

  final RoundState round;
  final ProgressState progress;
  final RoundController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _OptionRow(
      children: <Widget>[
        for (final DecorItem item in NailCatalog.rings)
          OptionTile(
            size: 84,
            selected: round.ringId == item.id,
            locked: !progress.canUse(item.id, price: item.price),
            price: item.price,
            semanticLabel: item.label,
            onTap: () {
              if (!_ensureUnlocked(context, ref, item.id, item.price)) return;
              controller.selectRing(item.id);
              SoundHelper.tap();
            },
            child: SafeAssetImage(
              asset: item.asset,
              width: 46,
              height: 46,
              fallbackIcon: ringIcon(item.id),
              fallbackColor: AppColors.lavender,
            ),
          ),
      ],
    );
  }
}

// --- Continue / finish ------------------------------------------------------

class _ContinueButton extends ConsumerWidget {
  const _ContinueButton({required this.round, required this.controller});

  final RoundState round;
  final RoundController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool last = round.isLastStudioStep;

    return BigButton(
      icon: last ? Icons.celebration_rounded : Icons.arrow_forward_rounded,
      label: last ? 'Done' : 'Next',
      enabled: round.canAdvanceFromStudioStep,
      color: AppColors.pink,
      height: 88,
      onPressed: () {
        if (!last) {
          controller.advanceStudioStep();
          SoundHelper.tap();
          return;
        }

        // Finish: pay the reward, store the design, celebrate.
        ref.read(progressControllerProvider.notifier).completeRound(round);
        SoundHelper.sparkle();
        context.go(AppRoutes.reveal);
      },
    );
  }
}
