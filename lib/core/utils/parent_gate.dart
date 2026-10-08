import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/game_constants.dart';
import '../theme/app_colors.dart';

/// A **textless** grown-ups gate (GDD section 12).
///
/// The child would have to *hold* the widget for 3 seconds on purpose —
/// something a 3-5 year old almost never does by accident.
/// Wrap any sensitive button with it:
///
/// ```dart
/// ParentGate(
///   onUnlocked: () => context.push(AppRoutes.settings),
///   child: const SettingsStarButton(),
/// )
/// ```
class ParentGate extends StatefulWidget {
  const ParentGate({
    required this.child,
    required this.onUnlocked,
    this.holdDuration = GameConstants.parentGateHold,
    this.showProgress = true,
    super.key,
  });

  final Widget child;
  final VoidCallback onUnlocked;
  final Duration holdDuration;
  final bool showProgress;

  @override
  State<ParentGate> createState() => _ParentGateState();
}

class _ParentGateState extends State<ParentGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.holdDuration,
  );
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startHold() {
    _controller.forward(from: 0);
    _timer?.cancel();
    _timer = Timer(widget.holdDuration, () {
      if (!mounted) return;
      _controller.value = 1;
      widget.onUnlocked();
    });
  }

  void _cancelHold() {
    _timer?.cancel();
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _startHold(),
      onTapUp: (_) => _cancelHold(),
      onTapCancel: _cancelHold,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final bool holding = _controller.value > 0 && _controller.value < 1;
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              widget.child,
              if (widget.showProgress && holding)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: SizedBox(
                        width: 96,
                        height: 96,
                        child: CircularProgressIndicator(
                          value: _controller.value,
                          strokeWidth: 7,
                          strokeCap: StrokeCap.round,
                          color: AppColors.lavender,
                          backgroundColor: AppColors.highlight,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Modal, **textless** gate for irreversible actions (GDD: *no text a child
/// must read* — and the destructive dialog is no exception).
///
/// The grown-up holds the star for three seconds; the ring fills. When
/// [doubleHold] is true the star then **jumps to the other side and turns
/// peach** and asks for a second hold — a small hand resting on the screen
/// does not do two displaced holds by accident.
///
/// This does not *prove* an adult is present (nothing offline can); it makes
/// an accidental erase as unlikely as a kids game reasonably can.
///
/// Returns `true` only when the required hold(s) were completed.
Future<bool> showParentGateDialog(
  BuildContext context, {
  bool doubleHold = false,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) =>
        _ParentGateDialog(doubleHold: doubleHold),
  );
  return result ?? false;
}

class _ParentGateDialog extends StatefulWidget {
  const _ParentGateDialog({required this.doubleHold});

  /// `true` for the irreversible ones: erase the album, reset everything.
  final bool doubleHold;

  @override
  State<_ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<_ParentGateDialog> {
  /// `0` = the first hold, `1` = the confirmation hold of an erase.
  int _step = 0;

  void _advance() {
    if (_step == 0 && widget.doubleHold) {
      setState(() => _step = 1);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bool confirm = _step == 1;
    // A functional cue still calms down for families who asked for it.
    final bool calm = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Icon-only cancel: an adult can always back out, a child has
            // nothing to read.
            Align(
              alignment: Alignment.centerRight,
              child: Semantics(
                label: 'Cancel',
                button: true,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close_rounded),
                  iconSize: 30,
                  color: AppColors.textSoft,
                  padding: const EdgeInsets.all(10),
                ),
              ),
            ),
            AnimatedAlign(
                duration: calm
                    ? Duration.zero
                    : const Duration(milliseconds: 280),
                curve: Curves.easeOutBack,
                alignment: !widget.doubleHold
                    ? Alignment.center
                    : (confirm ? Alignment.centerRight : Alignment.centerLeft),
                child: ParentGate(
                  onUnlocked: _advance,
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: confirm ? AppColors.peach : AppColors.yellow,
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      confirm
                          ? Icons.delete_forever_rounded
                          : Icons.star_rounded,
                      size: 52,
                      color: AppColors.white,
                    ),
                  ),
                ),
            ),
          ],
        ),
      ),
    );
  }
}
