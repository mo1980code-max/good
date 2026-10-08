import 'package:flutter/material.dart';

/// Splash — logo, sparkles, short chime, then auto-advance to Home.
///
/// TODO(screens-phase): built in the next phase (screens & widgets).
/// The route and the transition are already wired in `AppRouter`.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.expand());
  }
}
