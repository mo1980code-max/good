import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';

/// An image that can never break the game.
///
/// When the file is missing (or art is not shipped yet) it draws a friendly
/// pastel badge with an icon instead — so every screen looks intentional,
/// never like a broken placeholder.
class SafeAssetImage extends StatelessWidget {
  const SafeAssetImage({
    required this.asset,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.fallbackIcon,
    this.fallbackColor,
    this.fallbackRadius = 22,
    this.semanticLabel,
    super.key,
  });

  final String asset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData? fallbackIcon;
  final Color? fallbackColor;
  final double fallbackRadius;
  final String? semanticLabel;

  /// Never decode a 2000-px file to paint a 120-px badge: the image cache
  /// gets exactly the pixels the screen needs (one copy per size, not per
  /// widget), which is what keeps the album and the reveal smooth on phones.
  int? _cacheSide(BuildContext context, double? logical) {
    if (logical == null || logical <= 0) return null;
    final double scale = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    final int pixels = (logical * scale).ceil();
    return pixels <= 0 ? null : pixels;
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: _cacheSide(context, width),
      cacheHeight: _cacheSide(context, height),
      semanticLabel: semanticLabel,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) => _Fallback(
        width: width,
        height: height,
        icon: fallbackIcon ?? Icons.auto_awesome_rounded,
        color: fallbackColor ?? AppColors.lavender,
        radius: fallbackRadius,
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({
    required this.icon,
    required this.color,
    required this.radius,
    this.width,
    this.height,
  });

  final IconData icon;
  final Color color;
  final double radius;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final double side = _sideOf(width, height, radius);
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: Container(
          width: side,
          height: side,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                AppColors.white,
                Color.lerp(color, AppColors.white, 0.55) ?? color,
              ],
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(icon, size: side * 0.55, color: color),
          ),
        ),
      ),
    );
  }

  static double _sideOf(double? width, double? height, double radius) {
    final double? smallest = switch ((width, height)) {
      (final double w, final double h) => w < h ? w : h,
      (final double w, null) => w,
      (null, final double h) => h,
      _ => null,
    };
    return smallest != null ? smallest.clamp(24.0, 200.0).toDouble() : radius * 2;
  }
}

/// Haptic + click feedback helper used by tappable decorations.
void performSoftClick() => HapticFeedback.selectionClick();
