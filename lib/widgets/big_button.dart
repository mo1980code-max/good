import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/feedback_helper.dart';

/// The one and only button style in the game: tall, round, glossy, bouncy.
///
/// * Never smaller than [height] — designed for a 3-year-old finger.
/// * A shine sweeps across it so it *looks* tappable.
/// * Tapping squishes it slightly (kid-friendly confirmation).
class BigButton extends StatefulWidget {
  const BigButton({
    required this.icon,
    required this.onPressed,
    this.label,
    this.color,
    this.gradient,
    this.enabled = true,
    this.height = 84,
    this.iconSize = 34,
    super.key,
  });

  final IconData icon;
  final String? label;
  final VoidCallback? onPressed;
  final Color? color;
  final Gradient? gradient;
  final bool enabled;
  final double height;
  final double iconSize;

  @override
  State<BigButton> createState() => _BigButtonState();
}

class _BigButtonState extends State<BigButton> {
  bool _pressed = false;

  bool get _active => widget.enabled && widget.onPressed != null;

  void _setPressed(bool value) {
    if (!_active || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final Gradient gradient = widget.gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            widget.color ?? AppColors.lavender,
            Color.lerp(widget.color ?? AppColors.lavender, AppColors.white, 0.28)!,
          ],
        );

    return Semantics(
      button: true,
      enabled: _active,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: _active
            ? () {
                FeedbackHelper.tap();
                widget.onPressed!.call();
              }
            : null,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutBack,
          child: Opacity(
            opacity: _active ? 1 : 0.45,
            child: Container(
              height: widget.height,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(widget.height / 3),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.65),
                  width: 2.5,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: (widget.color ?? AppColors.lavender)
                        .withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.height / 3),
                child: Stack(
                  children: <Widget>[
                    if (_active)
                      Positioned.fill(child: _Shine(height: widget.height)),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            widget.icon,
                            size: widget.iconSize,
                            color: AppColors.white,
                          ),
                          if (widget.label != null) ...<Widget>[
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                widget.label!,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A slow diagonal shine that sells the "press me" feeling.
class _Shine extends StatefulWidget {
  const _Shine({required this.height});

  final double height;

  @override
  State<_Shine> createState() => _ShineState();
}

class _ShineState extends State<_Shine> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double t = _controller.value;
          return Align(
            alignment: Alignment(-1.6 + t * 3.2, 0),
            child: Transform.rotate(
              angle: 0.38,
              child: Container(
                width: 26,
                height: widget.height * 2.4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      AppColors.white.withValues(alpha: 0),
                      AppColors.white.withValues(alpha: 0.22),
                      AppColors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
