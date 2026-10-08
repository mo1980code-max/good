import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'motion_tokens.dart';

/// The one transition every route in the game uses.
///
/// Fade + a whisper of scale, forward 340 ms and back 240 ms: inside the
/// 250-400 ms window from the brief, and identical on every screen so the
/// child never has to re-learn what "going somewhere" looks like.
CustomTransitionPage<void> softPage(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionDuration: MotionTokens.screenTransition,
    reverseTransitionDuration: MotionTokens.screenTransitionReverse,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final Animation<double> curved = CurvedAnimation(
        parent: animation,
        curve: MotionTokens.soft,
        reverseCurve: MotionTokens.gentle,
      );

      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}
