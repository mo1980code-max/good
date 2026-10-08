import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations/motion_tokens.dart';
import '../../core/audio/sound_helper.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/character_model.dart';
import '../../data/models/nail_item_model.dart';
import '../../data/models/progress_state.dart';
import '../../data/models/round_state.dart';
import '../../data/models/skin_tone.dart';
import '../../features/game/game_providers.dart';
import '../../widgets/big_button.dart';
import '../../widgets/character_face.dart';
import '../../widgets/counter_pill.dart';
import '../../widgets/design_preview.dart';
import '../../widgets/kid_screen.dart';
import '../../widgets/option_tile.dart';
import '../../widgets/realistic_hand.dart';
import '../../widgets/safe_asset_image.dart';
import '../../widgets/skin_tone_picker.dart';

/// Nail studio — shape, live brush paint, pattern, sticker, ring.
///
/// The first color step is now a real five-nail painting interaction. A bottle
/// loads the brush; only a continuous drag over a nail grows its coverage.
class NailStudioScreen extends ConsumerStatefulWidget {
  const NailStudioScreen({super.key});

  @override
  ConsumerState<NailStudioScreen> createState() => _NailStudioScreenState();
}

class _NailStudioScreenState extends ConsumerState<NailStudioScreen> {
  Offset? _brushPoint;
  int _activeNail = 0;

  @override
  Widget build(BuildContext context) {
    final RoundState round = ref.watch(roundControllerProvider);
    final ProgressState progress = ref.watch(progressControllerProvider);
    final CharacterModel character = ref.watch(selectedCharacterProvider);
    final RoundController controller =
        ref.read(roundControllerProvider.notifier);
    final NailColorOption selectedColour = NailCatalog.colorById(round.colorId);

    final Map<int, Color> paintedColours = <int, Color>{
      for (final MapEntry<int, String> entry in round.nailColors.entries)
        entry.key: NailCatalog.colorById(entry.value).color,
    };
    final bool showLegacyBase =
        round.studioStep > 1 && round.nailColors.isEmpty && round.colorId != null;

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
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.74),
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
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned.fill(
                    child: RealisticHandPreview(
                      shape: round.shape ?? NailShape.round,
                      nailLength: NailLength.fromId(round.nailLengthId),
                      colorOption: showLegacyBase ? selectedColour : null,
                      nailColors: paintedColours,
                      nailProgress: round.nailCoverage,
                      pattern: round.patternId == null
                          ? null
                          : NailCatalog.patternById(round.patternId),
                      sticker: round.stickerId == null
                          ? null
                          : NailCatalog.stickerById(round.stickerId),
                      ring: round.ringId == null
                          ? null
                          : NailCatalog.ringById(round.ringId),
                      showSticker: round.studioStep >= 3,
                      showRing: round.studioStep >= 4,
                      showSparkles: round.studioStep >= 2,
                      skinTone: SkinTone.fromId(round.skinToneId),
                      brushPosition: _brushPoint,
                      brushColor: selectedColour.color,
                      showBrush: round.studioStep == 1 && round.colorId != null,
                      onBrushMove: round.studioStep == 1
                          ? _paintWithBrush
                          : null,
                      onBrushEnd: round.studioStep == 1
                          ? () => setState(() => _brushPoint = null)
                          : null,
                      onNailSelected: round.studioStep == 1
                          ? (int index) => setState(() => _activeNail = index)
                          : null,
                      onNailLongPress: round.studioStep == 1
                          ? (int index) {
                              controller.clearNail(index);
                              setState(() => _activeNail = index);
                              SoundHelper.pop();
                            }
                          : null,
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: SkinTonePicker(
                      selected: SkinTone.fromId(round.skinToneId),
                      compact: true,
                      onChanged: (SkinTone value) {
                        controller.selectSkinTone(value.id);
                        SoundHelper.tap();
                      },
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 14,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (round.studioStep == 1)
                          IgnorePointer(
                            child: PolishBottleVisual(
                              color: selectedColour.color,
                              open: _brushPoint != null,
                              size: 92,
                            ),
                          ),
                        IgnorePointer(
                          child: CharacterFace(
                            character: character,
                            size: 66,
                            mood: FaceMood.happy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (round.studioStep == 1)
                    Positioned(
                      left: 14,
                      bottom: 14,
                      child: _PaintProgressBadge(
                        activeNail: _activeNail,
                        coverage: round.nailCoverage[_activeNail] ?? 0,
                        complete: round.allNailsPainted,
                        onClear: () {
                          controller.clearNail(_activeNail);
                          SoundHelper.pop();
                        },
                      ),
                    ),
                  Positioned(
                    right: 12,
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
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: round.studioStep == 1 ? 116 : 108,
            child: AnimatedSwitcher(
              duration: MotionTokens.screenTransition,
              switchInCurve: MotionTokens.soft,
              switchOutCurve: MotionTokens.gentle,
              child: _StepOptions(
                key: ValueKey<int>(round.studioStep),
                round: round,
                progress: progress,
                controller: controller,
              ),
            ),
          ),
          if (round.studioStep == 1) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              round.allNailsPainted
                  ? 'Beautiful! Every nail is glossy.'
                  : 'Drag the brush over all five nails',
              style: const TextStyle(
                color: AppColors.textSoft,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 6),
          _ContinueButton(round: round, controller: controller),
        ],
      ),
    );
  }

  void _paintWithBrush(NailBrushEvent event) {
    setState(() {
      _brushPoint = event.position;
      if (event.nailIndex != null) _activeNail = event.nailIndex!;
    });
    final int? nail = event.nailIndex;
    if (nail == null || event.distance <= 0) return;
    ref
        .read(roundControllerProvider.notifier)
        .paintNail(nail, distance: event.distance);
    SoundHelper.brush();
  }
}

class _PaintProgressBadge extends StatelessWidget {
  const _PaintProgressBadge({
    required this.activeNail,
    required this.coverage,
    required this.complete,
  });

  final int activeNail;
  final double coverage;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              complete ? Icons.check_circle_rounded : Icons.brush_rounded,
              size: 20,
              color: complete ? AppColors.mint : AppColors.pink,
            ),
            const SizedBox(width: 5),
            Text(
              '${activeNail + 1}/5  ${(coverage * 100).round()}%',
              style: const TextStyle(
                color: AppColors.textDeep,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
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

/// Gift-only items are **never bought**: they come from a gift box.
/// Tapping a locked one shows a textless gift hint — no price, no penalty,
/// and the tile stays exactly where it is.
bool _giftReady(WidgetRef ref, String id) =>
    ref.read(progressControllerProvider).isUnlocked(id);

void _showGiftHint(BuildContext context) {
  SoundHelper.pop();
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.card_giftcard_rounded,
            size: 64,
            color: AppColors.pink,
          ),
          SizedBox(height: 6),
          Icon(
            Icons.auto_awesome_rounded,
            size: 40,
            color: AppColors.yellow,
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
                color: NailCatalog.colorById(round.colorId).color,
              ),
            ),
          ),
        for (final NailLength length in NailLength.values)
          OptionTile(
            size: 88,
            selected: round.nailLengthId == length.id,
            semanticLabel: length.label,
            onTap: () {
              controller.selectNailLength(length);
              SoundHelper.tap();
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.height_rounded,
                  size: 34,
                  color: length == NailLength.long
                      ? AppColors.pink
                      : AppColors.lavender,
                ),
                Text(
                  length.label,
                  style: const TextStyle(
                    color: AppColors.textDeep,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
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
            locked: !progress.canUse(
              option.id,
              price: option.price,
              giftOnly: option.giftOnly,
            ),
            price: option.giftOnly ? 0 : option.price,
            lockedIcon: option.giftOnly ? Icons.card_giftcard_rounded : null,
            semanticLabel: option.label,
            onTap: () {
              if (option.giftOnly && !_giftReady(ref, option.id)) {
                _showGiftHint(context);
                return;
              }
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
            locked: !progress.canUse(
              item.id,
              price: item.price,
              giftOnly: item.giftOnly,
            ),
            price: item.giftOnly ? 0 : item.price,
            lockedIcon: item.giftOnly ? Icons.card_giftcard_rounded : null,
            semanticLabel: item.label,
            onTap: () {
              if (item.giftOnly && !_giftReady(ref, item.id)) {
                _showGiftHint(context);
                return;
              }
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
