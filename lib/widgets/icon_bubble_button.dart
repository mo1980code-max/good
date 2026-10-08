import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/feedback_helper.dart';

/// Round tappable bubble — used in top bars, the spa tool row and the home
/// action grid. Big enough for little fingers, with a springy press.
class IconBubbleButton extends StatefulWidget {
  const IconBubbleButton({
    required this.icon,
    required this.onPressed,
    this.size = 64,
    this.color,
    this.iconColor,
    this.selected = false,
    this.badge,
    this.semanticLabel,
    this.gradient,
    this.appearsEnabled = false,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;
  final Color? iconColor;
  final bool selected;
  final Widget? badge;
  final String? semanticLabel;
  final Gradient? gradient;

  /// True when the tap is handled by a parent (e.g. the grown-ups gate) but
  /// the button must still look fully alive.
  final bool appearsEnabled;

  @override
  State<IconBubbleButton> createState() => _IconBubbleButtonState();
}

class _IconBubbleButtonState extends State<IconBubbleButton> {
  bool _pressed = false;

  bool get _active => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final Color tint = widget.color ?? AppColors.white;
    final Color iconColor = widget.iconColor ??
        (widget.color == null ? AppColors.lavender : AppColors.white);

    return Semantics(
      button: true,
      enabled: _active,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => _active ? setState(() => _pressed = true) : null,
        onTapUp: (_) => _active ? setState(() => _pressed = false) : null,
        onTapCancel: () => _active ? setState(() => _pressed = false) : null,
        onTap: _active
            ? () {
                FeedbackHelper.tap();
                widget.onPressed!.call();
              }
            : null,
        child: AnimatedScale(
          scale: _pressed ? 0.9 : (widget.selected ? 1.08 : 1),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutBack,
          child: Opacity(
            opacity: _active || widget.appearsEnabled ? 1 : 0.45,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.gradient == null ? tint : null,
                gradient: widget.gradient ??
                    (widget.color == null
                        ? null
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              widget.color!,
                              Color.lerp(widget.color!, AppColors.white, 0.3)!,
                            ],
                          )),
                border: Border.all(
                  color: widget.selected
                      ? AppColors.yellow
                      : AppColors.white.withValues(alpha: 0.8),
                  width: widget.selected ? 4 : 3,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: (widget.color ?? AppColors.lavender)
                        .withValues(alpha: 0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Icon(
                    widget.icon,
                    size: widget.size * 0.48,
                    color: iconColor,
                  ),
                  if (widget.badge != null)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: widget.badge!,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
