import 'package:flutter/animation.dart';

/// Every duration, curve and distance the game animates with.
///
/// The ranges are fixed by the Phase 2.3 brief and locked by tests in
/// `test/motion_policy_test.dart`, so a future tweak can never silently push
/// the game outside "calm for a 3-year-old" territory:
///
///   * screen transitions ... 250-400 ms
///   * element entrances .... 300-600 ms
///   * selection feedback ... 150-250 ms
///   * reveal celebration ... ~2-3 s
abstract final class MotionTokens {
  // --- Screen transitions --------------------------------------------------
  static const Duration screenTransition = Duration(milliseconds: 340);
  static const Duration screenTransitionReverse = Duration(milliseconds: 240);

  // --- Element entrances ---------------------------------------------------
  static const Duration entrance = Duration(milliseconds: 420);
  static const Duration entranceSlow = Duration(milliseconds: 560);
  static const Duration stagger = Duration(milliseconds: 90);

  /// Never make a child wait longer than this many stagger steps.
  static const int maxStaggerSteps = 8;

  // --- Selection / press ---------------------------------------------------
  static const Duration selection = Duration(milliseconds: 180);
  static const Duration press = Duration(milliseconds: 120);

  // --- Reveal celebration --------------------------------------------------
  /// Total choreography length (design -> glow -> stars -> confetti -> saved).
  static const Duration revealSequence = Duration(milliseconds: 2600);
  static const Duration starStep = Duration(milliseconds: 300);
  static const int starCount = 3;
  static const Duration starsBegin = Duration(milliseconds: 900);
  static const Duration glowBegin = Duration(milliseconds: 400);
  static const Duration confettiBegin = Duration(milliseconds: 600);

  // --- Idle / ambient (kept slow on purpose: battery friendly) -------------
  static const Duration breathe = Duration(milliseconds: 2400);
  static const Duration sparkleCycle = Duration(seconds: 3);

  // --- Curves --------------------------------------------------------------
  static const Curve soft = Curves.easeOutCubic;
  static const Curve bounce = Curves.easeOutBack;
  static const Curve gentle = Curves.easeInOut;
  static const Curve pop = Curves.elasticOut;

  // --- Distances -----------------------------------------------------------
  static const double slideDistance = 0.14;
  static const double slideDistanceSmall = 0.08;
  static const double scaleFrom = 0.92;
}
