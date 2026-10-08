import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Little white pill showing a currency or a counter (stars / coins / keys).
/// The number pops gently whenever it changes — a tiny reward in itself.
class CounterPill extends StatelessWidget {
  const CounterPill({
    required this.icon,
    required this.value,
    required this.color,
    this.size = 46,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final int value;
  final Color color;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget pill = Container(
      height: size,
      padding: EdgeInsets.symmetric(horizontal: size * 0.28),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(size),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: color, size: size * 0.5),
          const SizedBox(width: 6),
          // Keyed by value so the number bounces on every change.
          TweenAnimationBuilder<double>(
            key: ValueKey<int>(value),
            tween: Tween<double>(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.elasticOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Text(
              '$value',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: size * 0.36,
                color: AppColors.textDeep,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return pill;
    return GestureDetector(onTap: onTap, child: pill);
  }
}

/// Five dots that show where the child is in a 5-step mini-game.
/// Completed steps are filled, the active one pulses.
class StepDots extends StatelessWidget {
  const StepDots({
    required this.count,
    required this.current,
    this.color = AppColors.lavender,
    this.size = 16,
    super.key,
  });

  final int count;
  final int current;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(count, (int index) {
        final bool done = index < current;
        final bool active = index == current;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            width: active ? size * 1.6 : size,
            height: size,
            decoration: BoxDecoration(
              color: done || active ? color : AppColors.white,
              borderRadius: BorderRadius.circular(size),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// Rounded progress bar with a travelling bubble at the tip.
class CuteProgressBar extends StatelessWidget {
  const CuteProgressBar({
    required this.value,
    this.height = 26,
    this.color = AppColors.mint,
    super.key,
  });

  final double value;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double clamped = value.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double fill = width * clamped;

        return SizedBox(
          height: height,
          child: Stack(
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(height),
                  border: Border.all(
                    color: AppColors.white,
                    width: 2,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: fill < height ? height : fill,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      color,
                      Color.lerp(color, AppColors.white, 0.35)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
              if (clamped > 0.02 && clamped < 1)
                Positioned(
                  left: (fill - height * 0.72).clamp(0, width - height * 1.4),
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: height * 0.72,
                      height: height * 0.72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
