import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/feedback_helper.dart';
import '../../core/utils/sound_helper.dart';
import '../../data/models/character_model.dart';
import '../../data/models/round_state.dart';
import '../../features/game/game_providers.dart';
import '../../widgets/big_button.dart';
import '../../widgets/character_face.dart';
import '../../widgets/hand_illustration.dart';
import '../../widgets/icon_bubble_button.dart';
import '../../widgets/kid_screen.dart';
import '../../widgets/motion.dart';

/// Spa room — five rub-to-win steps: clean, soap, rinse, dry, cream.
///
/// One single gesture (rub anywhere) works for every step: impossible to fail,
/// and each stage answers with its own sound and a visible change.
class SpaScreen extends ConsumerWidget {
  const SpaScreen({super.key});

  static const List<IconData> _toolIcons = <IconData>[
    Icons.back_hand,
    Icons.bubble_chart_rounded,
    Icons.water_drop_rounded,
    Icons.air_rounded,
    Icons.spa_rounded,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RoundState round = ref.watch(roundControllerProvider);
    final SpaStage stage =
        SpaStage.values[round.spaStep.clamp(0, SpaStage.values.length - 1)];
    final CharacterModel character = ref.watch(selectedCharacterProvider);

    // Celebrate the exact moment a step reaches 100%.
    ref.listen(
      roundControllerProvider.select((r) => r.spaProgress),
      (double? previous, double next) {
        if (previous != null && previous < 1 && next >= 1) {
          SoundHelper.success();
          FeedbackHelper.success();
        }
      },
    );

    return KidScreen(
      center: StepDots(
        count: RoundState.spaStepCount,
        current: round.spaStep,
      ),
      sparkles: false,
      body: Column(
        children: <Widget>[
          _FaceAndProgress(character: character, progress: round.spaProgress),
          const SizedBox(height: 10),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _rub(ref, stage),
              onPanUpdate: (_) => _rub(ref, stage),
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
                      padding: const EdgeInsets.all(18),
                      child: HandIllustration(
                        stage: stage,
                        progress: round.spaProgress,
                      ),
                    ),
                    // Textless hint: a hand sliding side to side until the
                    // child starts rubbing.
                    if (round.spaProgress <= 0.01) const HintHand(size: 84),
                    if (round.isSpaStepComplete)
                      const Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.mint,
                            size: 44,
                          ),
                        ),
                      ).animate().scale(
                            duration: 400.ms,
                            curve: Curves.elasticOut,
                          ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _ToolRow(icons: _toolIcons, current: round.spaStep),
          const SizedBox(height: 10),
          BigButton(
            icon: round.isLastSpaStep
                ? Icons.brush_rounded
                : Icons.arrow_forward_rounded,
            label: round.isLastSpaStep ? 'Nails' : 'Next',
            enabled: round.isSpaStepComplete,
            height: 88,
            onPressed: () {
              if (round.isLastSpaStep) {
                SoundHelper.sparkle();
                context.go(AppRoutes.studio);
              } else {
                ref.read(roundControllerProvider.notifier).advanceSpaStep();
                SoundHelper.sparkle();
              }
            },
          ),
        ],
      ),
    );
  }

  void _rub(WidgetRef ref, SpaStage stage) {
    ref.read(roundControllerProvider.notifier).rub();
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
          child: CharacterFace(character: character, size: 92, mood: mood),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: <Widget>[
              CuteProgressBar(value: progress, height: 30),
              const SizedBox(height: 6),
              Icon(
                progress >= 1
                    ? Icons.check_circle_rounded
                    : Icons.touch_app_rounded,
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
            size: 56,
            selected: i == current,
            color: i <= current ? null : AppColors.locked,
            iconColor: i <= current ? AppColors.lavender : AppColors.textSoft,
            // Not tappable: the tools are a progress map, not a menu.
            onPressed: null,
            semanticLabel: 'Step ${i + 1}',
          ),
      ],
    );
  }
}
