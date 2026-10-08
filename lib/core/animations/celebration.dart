import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import 'motion_policy.dart';
import 'motion_tokens.dart';

/// The soft halo that wraps the finished design on the reveal screen.
/// Breathes slowly; completely static when motion is calmed.
class GlowHalo extends ConsumerStatefulWidget {
  const GlowHalo({
    required this.child,
    this.color = AppColors.yellow,
    this.strength = 0.55,
    super.key,
  });

  final Widget child;
  final Color color;
  final double strength;

  @override
  ConsumerState<GlowHalo> createState() => _GlowHaloState();
}

class _GlowHaloState extends ConsumerState<GlowHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: MotionTokens.breathe,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MotionPolicy policy = MotionPolicy.of(context, ref);
    syncLoopTicker(_controller, run: !policy.reduceMotion, reverse: true);
    if (policy.reduceMotion) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double t = Curves.easeInOut.transform(_controller.value);
        final double blur = 18 + 26 * t;
        final double alpha = (0.22 + 0.33 * t) * widget.strength;

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: widget.color.withValues(alpha: alpha),
                blurRadius: blur,
                spreadRadius: 2 + 4 * t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// One star of the reveal: pops in after [index] steps of the celebration.
class StarPop extends ConsumerWidget {
  const StarPop({
    required this.index,
    this.size = 46,
    this.color = AppColors.yellow,
    super.key,
  });

  final int index;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MotionPolicy policy = MotionPolicy.of(context, ref);
    final Duration delay =
        MotionTokens.starsBegin + MotionTokens.starStep * index;

    final Widget star = Icon(Icons.star_rounded, size: size, color: color);

    if (policy.reduceMotion) return star;

    return star
        .animate()
        .fadeIn(
          delay: delay,
          duration: policy.scaled(MotionTokens.entrance),
        )
        .scale(
          begin: const Offset(0.2, 0.2),
          end: const Offset(1, 1),
          delay: delay,
          duration: policy.scaled(MotionTokens.entranceSlow),
          curve: MotionTokens.pop,
        );
  }
}

/// The "design saved on this device" confirmation.
///
/// It fades in whenever [visible] flips to true — which happens when the
/// **actual** file write finishes, never on a timer. Nothing about saving
/// depends on the celebration animation.
class SavedBadge extends StatelessWidget {
  const SavedBadge({
    required this.visible,
    this.icon = Icons.cloud_done_rounded,
    this.color = AppColors.mint,
    super.key,
  });

  final bool visible;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: MotionTokens.selection,
      curve: MotionTokens.soft,
      child: AnimatedScale(
        scale: visible ? 1 : 0.8,
        duration: MotionTokens.selection,
        curve: MotionTokens.bounce,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.white, width: 2),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }
}

/// Slow, subtle rotation + scale used by the surprise box before it opens.
/// Under calmed motion the child is returned untouched (no shaking at all).
class BoxWiggle extends ConsumerStatefulWidget {
  const BoxWiggle({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<BoxWiggle> createState() => _BoxWiggleState();
}

class _BoxWiggleState extends ConsumerState<BoxWiggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MotionPolicy policy = MotionPolicy.of(context, ref);
    syncLoopTicker(_controller, run: !policy.reduceMotion);
    if (policy.reduceMotion) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double t = _controller.value;
        return Transform.rotate(
          angle: math.sin(t * math.pi * 4) * 0.05,
          child: Transform.scale(
            scale: 1 + math.sin(t * math.pi * 2) * 0.03,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
