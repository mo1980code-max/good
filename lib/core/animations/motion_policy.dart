import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/game/game_providers.dart';
import 'motion_tokens.dart';

/// Decides how much motion the game is allowed to show.
///
/// Two independent switches, either one is enough to calm everything down:
///   1. the in-game "Calm motion" toggle (grown-ups screen), and
///   2. the **system** setting (Android "Remove animations" /
///      iOS "Reduce Motion"), surfaced by `MediaQuery.disableAnimations`.
///
/// The logic is deliberately pure so it can be unit-tested without a device.
/// Starts or stops a looping ticker to match the motion policy.
///
/// `run: false` really **stops** the ticker instead of only hiding the effect:
/// a loop left running under "calm motion" would keep rebuilding an invisible
/// widget on every frame — the exact battery cost this policy exists to avoid.
void syncLoopTicker(
  AnimationController controller, {
  required bool run,
  bool reverse = false,
}) {
  if (run) {
    if (!controller.isAnimating) controller.repeat(reverse: reverse);
  } else if (controller.isAnimating) {
    controller.stop();
  }
}

@immutable
class MotionPolicy {
  const MotionPolicy({required this.reduceMotion});

  /// Full motion (default).
  static const MotionPolicy full = MotionPolicy(reduceMotion: false);

  /// Everything calmed down.
  static const MotionPolicy calm = MotionPolicy(reduceMotion: true);

  final bool reduceMotion;

  /// Pure resolution rule — the part that is unit-tested.
  static MotionPolicy resolve({
    required bool appSetting,
    required bool systemDisablesAnimations,
  }) {
    return MotionPolicy(
      reduceMotion: appSetting || systemDisablesAnimations,
    );
  }

  /// Reads both switches from the widget tree.
  static MotionPolicy of(BuildContext context, WidgetRef ref) {
    final bool appSetting =
        ref.watch(settingsControllerProvider.select((s) => s.reduceMotion));
    final bool systemDisablesAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return resolve(
      appSetting: appSetting,
      systemDisablesAnimations: systemDisablesAnimations,
    );
  }

  /// A duration that respects the policy: calmed motion becomes instant.
  Duration scaled(Duration base) =>
      reduceMotion ? const Duration(milliseconds: 1) : base;

  /// A distance that respects the policy: calmed motion never travels.
  double distance(double base) => reduceMotion ? 0.0 : base;

  /// Looping decorations (sparkles, breathing) are off when calmed —
  /// this is also what keeps the battery happy.
  bool get allowLoopingMotion => !reduceMotion;

  /// Stagger delays are capped so a long list never feels slow.
  Duration staggerFor(int index) {
    if (reduceMotion) return Duration.zero;
    final int step = index.clamp(0, MotionTokens.maxStaggerSteps);
    return MotionTokens.stagger * step;
  }
}
