import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../art/art_or_fallback.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/responsive.dart';
import '../widgets/cute_background.dart';
import '../widgets/icon_bubble_button.dart';
import '../widgets/motion.dart';
import '../widgets/quick_mute_button.dart';

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

  /// Optional "one level up" action (shown as a small arrow next to Home).
  /// Home itself is always available, on every screen.
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
                      // Home never moves and never disappears: whatever else a
                      // screen offers, the same corner always leads back to the
                      // three big doors.
                      if (showLeading)
                        IconBubbleButton(
                          icon: Icons.home_rounded,
                          semanticLabel: 'Home',
                          size: 58,
                          iconColor: AppColors.lavender,
                          onPressed: () => goHome(context),
                        ),
                      // An extra step back (e.g. gift room -> gift hall) sits
                      // beside it, so "up one level" and "all the way home"
                      // can never be confused.
                      if (showLeading && onBack != null) ...<Widget>[
                        const SizedBox(width: 8),
                        IconBubbleButton(
                          icon: Icons.arrow_back_rounded,
                          semanticLabel: 'Back',
                          size: 50,
                          iconColor: AppColors.mint,
                          onPressed: onBack!,
                        ),
                      ],
                      Expanded(
                        child: Center(child: center ?? const SizedBox.shrink()),
                      ),
                      if (showSound) const QuickMuteButton(),
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
