import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/audio/sound_helper.dart';
import '../core/theme/app_colors.dart';
import '../features/game/game_providers.dart';
import 'icon_bubble_button.dart';

/// One tap silences (or restores) sound **and** music — the GDD requires a mute
/// button a child can find instantly, without opening any menu.
///
/// It lives in its own file so **every** screen can put it in the same corner:
/// `KidScreen` uses it, and Home — which builds its own top bar — uses the very
/// same widget. One implementation, one behaviour, one position.
class QuickMuteButton extends ConsumerWidget {
  const QuickMuteButton({this.size = 58, super.key});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool soundOn =
        ref.watch(settingsControllerProvider.select((s) => s.soundOn));
    final bool musicOn =
        ref.watch(settingsControllerProvider.select((s) => s.musicOn));
    final bool quiet = !soundOn && !musicOn;

    final SettingsController controller =
        ref.read(settingsControllerProvider.notifier);

    return IconBubbleButton(
      icon: quiet ? Icons.volume_off_rounded : Icons.volume_up_rounded,
      semanticLabel: quiet ? 'Unmute' : 'Mute',
      size: size,
      iconColor: AppColors.lavender,
      onPressed: () {
        controller.setSoundOn(quiet);
        controller.setMusicOn(quiet);
        if (quiet) {
          SoundHelper.tap();
        }
      },
    );
  }
}
