import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'motion.dart';

/// The pastel world every screen lives in: optional room art, soft gradient,
/// floating colour blobs and gentle twinkles.
class CuteBackground extends StatelessWidget {
  const CuteBackground({
    required this.child,
    this.sparkles = true,
    this.blobs = true,
    this.backdrop,
    super.key,
  });

  final Widget child;
  final bool sparkles;
  final bool blobs;

  /// Optional illustrated room backdrop (see `lib/art/`). When it is missing
  /// the gradient + blobs below still make the screen look finished.
  final Widget? backdrop;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.background),
      child: Stack(
        children: <Widget>[
          if (backdrop != null) Positioned.fill(child: backdrop!),
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
