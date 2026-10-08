import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations/entrances.dart';
import '../../core/audio/sound_helper.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/parent_gate.dart';
import '../../data/models/settings_model.dart';
import '../../features/game/game_providers.dart';
import '../../widgets/big_button.dart';
import '../../widgets/kid_screen.dart';

/// Grown-ups corner: sound, music, haptics, motion — and a protected reset.
///
/// This screen is only reachable through [ParentGate], and the destructive
/// action has its own gate on top.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SettingsModel settings = ref.watch(settingsControllerProvider);
    final SettingsController controller =
        ref.read(settingsControllerProvider.notifier);

    return KidScreen(
      roomId: 'settings',
      center: const Text(
        'Grown-ups',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
      sparkles: false,
      body: EntranceItem(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: <Widget>[
            _ToggleRow(
              icon: Icons.volume_up_rounded,
              color: AppColors.sky,
              label: 'Sound',
              value: settings.soundOn,
              onChanged: (bool value) {
                controller.setSoundOn(value);
                if (value) SoundHelper.tap();
              },
            ),
            _ToggleRow(
              icon: Icons.music_note_rounded,
              color: AppColors.lavender,
              label: 'Music',
              value: settings.musicOn,
              onChanged: controller.setMusicOn,
            ),
            _ToggleRow(
              icon: Icons.vibration_rounded,
              color: AppColors.mint,
              label: 'Vibration',
              value: settings.hapticsOn,
              onChanged: controller.setHapticsOn,
            ),
            _ToggleRow(
              icon: Icons.motion_photos_off_rounded,
              color: AppColors.peach,
              label: 'Calm motion',
              value: settings.reduceMotion,
              onChanged: controller.setReduceMotion,
            ),
            const SizedBox(height: 20),
            BigButton(
              icon: Icons.restart_alt_rounded,
              label: 'Reset progress',
              color: AppColors.peach,
              height: 80,
              onPressed: () => _resetProgress(context, ref),
            ),
            const SizedBox(height: 10),
            BigButton(
              icon: Icons.home_rounded,
              height: 76,
              onPressed: () => context.go(AppRoutes.home),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Icon(
                Icons.favorite_rounded,
                color: AppColors.pink,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetProgress(BuildContext context, WidgetRef ref) async {
    final bool allowed = await showParentGateDialog(
      context,
      title: 'Reset everything?',
      actionLabel: 'Hold the star for 3 seconds to erase the album and rewards',
    );
    if (!allowed || !context.mounted) return;

    // Images first, then the save data.
    await ref.read(galleryRepositoryProvider).deleteAllDesignImages();
    await ref.read(progressControllerProvider.notifier).resetProgress();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.white,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: <Widget>[
            Icon(Icons.check_circle_rounded, color: AppColors.mint),
            SizedBox(width: 10),
            Icon(Icons.auto_awesome_rounded, color: AppColors.pink),
          ],
        ),
      ),
    );
    context.go(AppRoutes.home);
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color color;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.white, width: 3),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.20),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Transform.scale(
            scale: 1.35,
            child: Switch(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}
