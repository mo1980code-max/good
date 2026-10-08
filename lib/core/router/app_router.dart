import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../animations/screen_transitions.dart';

import '../../features/achievements/achievements_screen.dart';
import '../../features/characters/character_select_screen.dart';
import '../../features/gallery/gallery_screen.dart';
import '../../features/gift_rooms/gift_room_screen.dart';
import '../../features/gift_rooms/gift_rooms_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/reveal/reveal_screen.dart';
import '../../features/rewards/rewards_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/spa/spa_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/studio/nail_studio_screen.dart';
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
        pageBuilder: (_, __) => softPage(const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (_, __) => softPage(const HomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.characters,
        pageBuilder: (_, __) => softPage(const CharacterSelectScreen()),
      ),
      GoRoute(
        path: AppRoutes.spa,
        pageBuilder: (_, __) => softPage(const SpaScreen()),
      ),
      GoRoute(
        path: AppRoutes.studio,
        pageBuilder: (_, __) => softPage(const NailStudioScreen()),
      ),
      GoRoute(
        path: AppRoutes.reveal,
        pageBuilder: (_, __) => softPage(const RevealScreen()),
      ),
      GoRoute(
        path: AppRoutes.gallery,
        pageBuilder: (_, __) => softPage(const GalleryScreen()),
      ),
      GoRoute(
        path: AppRoutes.rewards,
        pageBuilder: (_, __) => softPage(const RewardsScreen()),
      ),
      GoRoute(
        path: AppRoutes.stars,
        pageBuilder: (_, __) => softPage(const AchievementsScreen()),
      ),
      GoRoute(
        path: AppRoutes.gifts,
        pageBuilder: (_, __) => softPage(const GiftRoomsScreen()),
        routes: <RouteBase>[
          GoRoute(
            path: ':roomId',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                softPage(
              GiftRoomScreen(roomId: state.pathParameters['roomId'] ?? ''),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (_, __) => softPage(const SettingsScreen()),
      ),
    ],
  );

}
