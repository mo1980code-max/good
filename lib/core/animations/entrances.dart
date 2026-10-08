import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'motion_policy.dart';
import 'motion_tokens.dart';

/// Slides + fades a widget in, optionally staggered by its position
/// in a list. Use it instead of repeating `.animate()` calls per screen.
///
/// ```dart
/// Column(children: [
///   for (int i = 0; i < doors.length; i++)
///     EntranceItem(index: i, child: doors[i]),
/// ])
/// ```
class EntranceItem extends ConsumerWidget {
  const EntranceItem({
    required this.child,
    this.index = 0,
    this.slide = MotionTokens.slideDistance,
    this.curve = MotionTokens.soft,
    this.duration = MotionTokens.entrance,
    super.key,
  });

  final Widget child;

  /// Position in the list — drives the stagger delay.
  final int index;

  /// How far (as a fraction of the widget height) it travels up.
  final double slide;

  final Curve curve;
  final Duration duration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MotionPolicy policy = MotionPolicy.of(context, ref);
    if (policy.reduceMotion) return child;

    final Duration delay = policy.staggerFor(index);

    return child
        .animate()
        .fadeIn(
          delay: delay,
          duration: policy.scaled(duration),
          curve: MotionTokens.soft,
        )
        .slideY(
          begin: policy.distance(slide),
          end: 0,
          delay: delay,
          duration: policy.scaled(duration),
          curve: curve,
        );
  }
}

/// A friendly pop-in: fade + elastic scale. Perfect for badges, prizes,
/// stars and the greeting mascot.
class PopIn extends ConsumerWidget {
  const PopIn({
    required this.child,
    this.delay = Duration.zero,
    this.from = 0.4,
    this.duration = MotionTokens.entranceSlow,
    super.key,
  });

  final Widget child;
  final Duration delay;
  final double from;
  final Duration duration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MotionPolicy policy = MotionPolicy.of(context, ref);
    if (policy.reduceMotion) return child;

    return child
        .animate()
        .fadeIn(
          delay: delay,
          duration: policy.scaled(MotionTokens.entrance),
          curve: MotionTokens.soft,
        )
        .scale(
          begin: Offset(from, from),
          end: const Offset(1, 1),
          delay: delay,
          duration: policy.scaled(duration),
          curve: MotionTokens.pop,
        );
  }
}

/// A whole screen settling in. Used once per route, so screens do not
/// hand-roll their own entrance.
class ScreenEntrance extends ConsumerWidget {
  const ScreenEntrance({
    required this.child,
    this.slide = MotionTokens.slideDistanceSmall,
    super.key,
  });

  final Widget child;
  final double slide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MotionPolicy policy = MotionPolicy.of(context, ref);
    if (policy.reduceMotion) return child;

    return child
        .animate()
        .fadeIn(
          duration: policy.scaled(MotionTokens.entrance),
          curve: MotionTokens.soft,
        )
        .slideY(
          begin: policy.distance(slide),
          end: 0,
          duration: policy.scaled(MotionTokens.entrance),
          curve: MotionTokens.soft,
        );
  }
}
