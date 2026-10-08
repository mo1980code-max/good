import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../art/art_or_fallback.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/responsive.dart';
import '../core/utils/sound_helper.dart';
import '../features/game/game_providers.dart';
import '../widgets/cute_background.dart';
import '../widgets/icon_bubble_button.dart';
import '../widgets/motion.dart';

/// Every screen shares the same skeleton:
/// [home/back] ... [step dots or title] ... [quick mute], then the content.
///
/// That consistency is the reason a 3-year-old never gets lost: the two most
/// important controls (get out, mute) are always in the same corner.
class KidScreen extends ConsumerWidget {
  const KidScreen({
    required this.body,
    this.onBack,
    this.showLeading = true,
    this.center,
    this.showSound = true,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 12),
    this.scrollable = false,
    this.sparkles = true,
    this.roomId,
    super.key,
  });

  final Widget body;

  /// `null` while [showLeading] is true means "back to Home".
  final VoidCallback? onBack;
  final bool showLeading;

  /// Small widget shown in the middle of the top bar (step dots, counters...).
  final Widget? center;
  final bool showSound;
  final EdgeInsets padding;
  final bool scrollable;
  final bool sparkles;

  /// Optional illustrated backdrop for this room (see `lib/art/asset_slots.dart`).
  /// `null` keeps the plain pastel gradient.
  final String? roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return KidPopScope(
      onBack: onBack ?? () => goHome(context),
      child: CuteBackground(
        sparkles: sparkles,
        backdrop: roomId == null ? null : RoomBackdrop(roomId: roomId!),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: <Widget>[
                      if (showLeading)
                        IconBubbleButton(
                          icon: onBack == null
                              ? Icons.home_rounded
                              : Icons.arrow_back_rounded,
                          semanticLabel: 'Home',
                          size: 58,
                          iconColor: AppColors.lavender,
                          onPressed: onBack ?? () => goHome(context),
                        ),
                      Expanded(
                        child: Center(child: center ?? const SizedBox.shrink()),
                      ),
                      if (showSound) const _QuickMuteButton(),
                    ],
                  ),
                ),
                Expanded(
                  // Tablets never get a stretched layout: content stays
                  // inside a comfortable width, centred.
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: Responsive.contentMaxWidth,
                      ),
                      child: scrollable
                          ? SingleChildScrollView(
                              padding: padding,
                              child: body,
                            )
                          : Padding(padding: padding, child: body),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One tap silences (or restores) sound **and** music — GDD requires a mute
/// button that a child can find instantly, without opening any menu.
class _QuickMuteButton extends ConsumerWidget {
  const _QuickMuteButton();

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
      size: 58,
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
