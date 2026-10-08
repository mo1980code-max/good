import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations/entrances.dart';
import '../../core/animations/motion_tokens.dart';
import '../../core/audio/sound_helper.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/feedback_helper.dart';
import '../../data/models/character_model.dart';
import '../../data/models/round_state.dart';
import '../../data/models/skin_tone.dart';
import '../../features/game/game_providers.dart';
import '../../widgets/big_button.dart';
import '../../widgets/character_face.dart';
import '../../widgets/hand_illustration.dart';
import '../../widgets/icon_bubble_button.dart';
import '../../widgets/kid_screen.dart';
import '../../widgets/motion.dart';
import '../../widgets/skin_tone_picker.dart';

/// Spa room — five continuous, movement-based gestures:
/// clean, soap, rinse, dry and cream.
class SpaScreen extends ConsumerStatefulWidget {
  const SpaScreen({super.key});

  @override
  ConsumerState<SpaScreen> createState() => _SpaScreenState();
}

class _SpaScreenState extends ConsumerState<SpaScreen> {
  Offset? _lastPoint;
  Offset? _toolPoint;

  static const List<IconData> _toolIcons = <IconData>[
    Icons.back_hand,
    Icons.bubble_chart_rounded,
    Icons.water_drop_rounded,
    Icons.air_rounded,
    Icons.spa_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final RoundState round = ref.watch(roundControllerProvider);
    final SpaStage stage =
        SpaStage.values[round.spaStep.clamp(0, SpaStage.values.length - 1).toInt()];
    final CharacterModel character = ref.watch(selectedCharacterProvider);
    final SkinTone skinTone = SkinTone.fromId(round.skinToneId);

    ref.listen<double>(
      roundControllerProvider.select((RoundState value) => value.spaProgress),
      (double? previous, double next) {
        if (previous != null && previous < 1 && next >= 1) {
          SoundHelper.success();
          FeedbackHelper.success();
        }
      },
    );

    return KidScreen(
      roomId: 'spa',
      center: StepDots(
        count: RoundState.spaStepCount,
        current: round.spaStep,
      ),
      sparkles: false,
      body: Column(
        children: <Widget>[
          _FaceAndProgress(character: character, progress: round.spaProgress),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final Size gestureSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (DragStartDetails details) {
                    _lastPoint = details.localPosition;
                    setState(() => _toolPoint = details.localPosition);
                  },
                  onPanUpdate: (DragUpdateDetails details) {
                    final Offset current = details.localPosition;
                    final Offset previous = _lastPoint ?? current;
                    _lastPoint = current;
                    final RoundController controller =
                        ref.read(roundControllerProvider.notifier);
                    final bool changed =
                        controller.rubAlong(previous, current, gestureSize);
                    setState(() => _toolPoint = current);
                    if (changed) _playDragCue(stage);
                  },
                  onPanEnd: (_) => _lastPoint = null,
                  onPanCancel: () => _lastPoint = null,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.72),
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
                      alignment: Alignment.center,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: AnimatedSwitcher(
                            duration: MotionTokens.screenTransition,
                            switchInCurve: MotionTokens.soft,
                            switchOutCurve: MotionTokens.gentle,
                            child: HandIllustration(
                              key: ValueKey<SpaStage>(stage),
                              stage: stage,
                              progress: round.spaProgress,
                              skinTone: skinTone,
                              toolPosition: _toolPoint,
                            ),
                          ),
                        ),
                        if (round.spaProgress <= 0.01 && _toolPoint == null)
                          const HintHand(size: 84),
                        if (round.isSpaStepComplete)
                          const Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: PopIn(
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.mint,
                                  size: 44,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          left: 12,
                          top: 12,
                          child: SkinTonePicker(
                            selected: skinTone,
                            compact: true,
                            onChanged: (SkinTone value) {
                              ref
                                  .read(roundControllerProvider.notifier)
                                  .selectSkinTone(value.id);
                              SoundHelper.tap();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          EntranceItem(
            index: 1,
            child: _ToolRow(icons: _toolIcons, current: round.spaStep),
          ),
          const SizedBox(height: 7),
          Row(
            children: <Widget>[
              TextButton.icon(
                onPressed: () => _skipStage(context, round),
                icon: const Icon(Icons.fast_forward_rounded),
                label: const Text('Skip'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSoft,
                  minimumSize: const Size(92, 64),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: BigButton(
                  icon: round.isLastSpaStep
                      ? Icons.brush_rounded
                      : Icons.arrow_forward_rounded,
                  label: round.isLastSpaStep ? 'Nails' : 'Next',
                  enabled: round.isSpaStepComplete,
                  height: 78,
                  onPressed: () => _completeStage(context, round),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _playDragCue(SpaStage stage) {
    switch (stage) {
      case SpaStage.clean:
      case SpaStage.dry:
        SoundHelper.brush();
      case SpaStage.soap:
        SoundHelper.bubble();
      case SpaStage.rinse:
        SoundHelper.water();
      case SpaStage.cream:
        SoundHelper.sparkle();
    }
  }

  void _completeStage(BuildContext context, RoundState round) {
    final RoundController controller = ref.read(roundControllerProvider.notifier);
    ref.read(progressControllerProvider.notifier).recordSpaSteps(1);
    if (round.isLastSpaStep) {
      SoundHelper.sparkle();
      context.go(AppRoutes.studio);
      return;
    }
    controller.advanceSpaStep();
    setState(() {
      _toolPoint = null;
      _lastPoint = null;
    });
    SoundHelper.sparkle();
  }

  void _skipStage(BuildContext context, RoundState round) {
    final RoundController controller = ref.read(roundControllerProvider.notifier);
    if (round.isLastSpaStep) {
      // Skipping is a safe exit, not a completed achievement.
      context.go(AppRoutes.studio);
      return;
    }
    controller.skipSpaStep();
    setState(() {
      _toolPoint = null;
      _lastPoint = null;
    });
    SoundHelper.tap();
  }
}

class _FaceAndProgress extends StatelessWidget {
  const _FaceAndProgress({required this.character, required this.progress});

  final CharacterModel character;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final FaceMood mood = progress >= 1
        ? FaceMood.amazed
        : (progress > 0.35 ? FaceMood.happy : FaceMood.calm);

    return Row(
      children: <Widget>[
        IdleBreathe(
          child: CharacterFace(character: character, size: 82, mood: mood),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: <Widget>[
              CuteProgressBar(value: progress, height: 28),
              const SizedBox(height: 4),
              Icon(
                progress >= 1
                    ? Icons.check_circle_rounded
                    : Icons.swipe_rounded,
                size: 22,
                color: progress >= 1 ? AppColors.mint : AppColors.lavender,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({required this.icons, required this.current});

  final List<IconData> icons;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        for (int i = 0; i < icons.length; i++)
          IconBubbleButton(
            icon: i < current ? Icons.check_rounded : icons[i],
            size: 52,
            selected: i == current,
            color: i <= current ? null : AppColors.locked,
            iconColor: i <= current ? AppColors.lavender : AppColors.textSoft,
            onPressed: null,
            semanticLabel: 'Spa step ${i + 1}',
          ),
      ],
    );
  }
}
