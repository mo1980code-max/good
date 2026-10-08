import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/audio/sound_helper.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/feedback_helper.dart';
import 'data/models/settings_model.dart';
import 'features/game/game_providers.dart';

/// Root widget: theme + router + app-wide audio/haptics wiring.
class SparkleNailApp extends ConsumerStatefulWidget {
  const SparkleNailApp({super.key});

  @override
  ConsumerState<SparkleNailApp> createState() => _SparkleNailAppState();
}

class _SparkleNailAppState extends ConsumerState<SparkleNailApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();

    // Music politely pauses when the app goes to the background.
    _lifecycle = AppLifecycleListener(
      onPause: () => unawaited(SoundHelper.pauseMusic()),
      onResume: () => unawaited(SoundHelper.resumeMusic()),
    );

    // First frame is up -> apply the saved settings (music on/off, haptics).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settings = ref.read(settingsControllerProvider);
      SoundHelper.configure(sound: settings.soundOn, music: settings.musicOn);
      FeedbackHelper.enabled = settings.hapticsOn && settings.soundOn;
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep the low-level helpers in sync whenever settings change.
    ref.listen<SettingsModel>(settingsControllerProvider, (previous, next) {
      SoundHelper.configure(sound: next.soundOn, music: next.musicOn);
      FeedbackHelper.enabled = next.hapticsOn && next.soundOn;
    });

    return MaterialApp.router(
      title: 'Sparkle Nail Spa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}
