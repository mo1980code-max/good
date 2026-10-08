import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/feedback_helper.dart';

/// A big selectable tile used across the studio (shapes, colors, stickers,
/// rings) and the character picker.
///
/// Locked items show a soft padlock and a coin price instead of being hidden —
/// a locked tile must *invite*, never frustrate.
class OptionTile extends StatefulWidget {
  const OptionTile({
    required this.selected,
    required this.onTap,
    required this.child,
    this.size = 92,
    this.accent = AppColors.lavender,
    this.locked = false,
    this.price = 0,
    this.lockedIcon,
    this.semanticLabel,
    super.key,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final double size;
  final Color accent;
  final bool locked;
  final int price;

  /// Shown instead of the padlock. Gift-only items use a little gift, so the
  /// child reads "a present is waiting", not "you must pay".
  final IconData? lockedIcon;

  final String? semanticLabel;

  @override
  State<OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<OptionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          FeedbackHelper.tap();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.9 : (widget.selected ? 1.07 : 1),
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutBack,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    color: widget.selected
                        ? widget.accent.withValues(alpha: 0.22)
                        : AppColors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(widget.size * 0.30),
                    border: Border.all(
                      color: widget.selected ? widget.accent : AppColors.white,
                      width: 3.5,
                    ),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(child: widget.child),
                ),
                if (widget.selected)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.mint,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                if (widget.locked)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.55),
                        borderRadius:
                            BorderRadius.circular(widget.size * 0.30),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              widget.lockedIcon ?? Icons.lock_rounded,
                              color: AppColors.lavender,
                              size: 30,
                            ),
                            if (widget.price > 0) ...<Widget>[
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Icon(
                                    Icons.monetization_on_rounded,
                                    size: 16,
                                    color: AppColors.yellow,
                                  ),
                                  Text(
                                    '${widget.price}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
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
