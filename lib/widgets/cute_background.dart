import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'motion.dart';

/// The pastel world every screen lives in: soft gradient, floating colour
/// blobs and gentle twinkles.
class CuteBackground extends StatelessWidget {
  const CuteBackground({
    required this.child,
    this.sparkles = true,
    this.blobs = true,
    super.key,
  });

  final Widget child;
  final bool sparkles;
  final bool blobs;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.background),
      child: Stack(
        children: <Widget>[
          if (blobs) ...const <Widget>[
            Positioned(top: -80, left: -60, child: _Blob(AppColors.pink)),
            Positioned(top: 140, right: -90, child: _Blob(AppColors.sky)),
            Positioned(bottom: -110, left: 40, child: _Blob(AppColors.mint)),
          ],
          if (sparkles) const Positioned.fill(child: SparkleBurst()),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.16),
        ),
      ),
    );
  }
}
