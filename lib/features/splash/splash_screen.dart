import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/assets.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/audio/sound_helper.dart';
import '../../features/game/game_providers.dart';
import '../../widgets/motion.dart';
import '../../widgets/safe_asset_image.dart';

/// Splash — logo, chime, a sprinkle of sparkles, then off to Home.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Music + a soft chime (both respect the saved settings).
    final bool musicOn =
        ref.read(settingsControllerProvider.select((s) => s.musicOn));
    if (musicOn) {
      unawaited(SoundHelper.startMusic());
    }
    unawaited(SoundHelper.sparkle());

    _timer = Timer(const Duration(milliseconds: 2300), () {
      if (mounted) context.go(AppRoutes.home);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CuteBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IdleBreathe(
                scale: 1.06,
                child: SafeAssetImage(
                  asset: Assets.logo,
                  width: 190,
                  height: 190,
                  fallbackIcon: Icons.auto_awesome_rounded,
                  fallbackColor: AppColors.pink,
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1, 1),
                    duration: 700.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: 14),
              const Text(
                'Sparkle Nail Spa',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDeep,
                  letterSpacing: 0.5,
                ),
              )
                  .animate()
                  .fadeIn(delay: 250.ms, duration: 500.ms)
                  .slideY(begin: 0.4, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.star_rounded, color: AppColors.yellow, size: 26)
                      .animate(onPlay: _cycle)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.2, 1.2),
                        duration: 800.ms,
                        curve: Curves.easeInOut,
                      ),
                  SizedBox(width: 8),
                  Icon(Icons.favorite_rounded, color: AppColors.pink, size: 26)
                      .animate(onPlay: _cycle)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.2, 1.2),
                        duration: 800.ms,
                        curve: Curves.easeInOut,
                      ),
                  SizedBox(width: 8),
                  Icon(Icons.auto_awesome_rounded, color: AppColors.sky, size: 26)
                      .animate(onPlay: _cycle)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.2, 1.2),
                        duration: 800.ms,
                        curve: Curves.easeInOut,
                      ),
                ],
              ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}

/// Repeats forever, ping-pong (flutter_animate helper).
void _cycle(AnimationController controller) => controller.repeat(reverse: true);
