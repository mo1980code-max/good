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

/// Modal version of the gate, for destructive actions (reset progress).
///
/// Returns `true` only when a grown-up held the star long enough.
Future<bool> showParentGateDialog(
  BuildContext context, {
  String title = 'Grown-ups only',
  String actionLabel = 'Hold the star for 3 seconds',
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(actionLabel, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ParentGate(
              onUnlocked: () => Navigator.of(context).pop(true),
              child: Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.yellow,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.star_rounded,
                  size: 54,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
