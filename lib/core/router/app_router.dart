import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/characters/character_select_screen.dart';
import '../../features/gallery/gallery_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/reveal/reveal_screen.dart';
import '../../features/rewards/rewards_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/spa/spa_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/studio/nail_studio_screen.dart';
import '../constants/game_constants.dart';
import 'app_routes.dart';

/// One place for navigation.
///
/// Every screen change fades in with a whisper of scale — soft, never jumpy
/// (law #1 of the GDD: the UI must feel calm and instant).
abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (_, __) => _soft(const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (_, __) => _soft(const HomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.characters,
        pageBuilder: (_, __) => _soft(const CharacterSelectScreen()),
      ),
      GoRoute(
        path: AppRoutes.spa,
        pageBuilder: (_, __) => _soft(const SpaScreen()),
      ),
      GoRoute(
        path: AppRoutes.studio,
        pageBuilder: (_, __) => _soft(const NailStudioScreen()),
      ),
      GoRoute(
        path: AppRoutes.reveal,
        pageBuilder: (_, __) => _soft(const RevealScreen()),
      ),
      GoRoute(
        path: AppRoutes.gallery,
        pageBuilder: (_, __) => _soft(const GalleryScreen()),
      ),
      GoRoute(
        path: AppRoutes.rewards,
        pageBuilder: (_, __) => _soft(const RewardsScreen()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (_, __) => _soft(const SettingsScreen()),
      ),
    ],
  );

  static CustomTransitionPage<void> _soft(Widget child) {
    return CustomTransitionPage<void>(
      child: child,
      transitionDuration: GameConstants.screenAnim,
      reverseTransitionDuration: GameConstants.fastAnim,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final Animation<double> curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
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
}
