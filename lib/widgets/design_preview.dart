import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/models/nail_item_model.dart';
import 'safe_asset_image.dart';

/// Fallback icons so stickers and rings look cute even before art ships.
IconData stickerIcon(String id) {
  return switch (id) {
    'star' => Icons.star_rounded,
    'heart' => Icons.favorite_rounded,
    'flower' => Icons.local_florist_rounded,
    'candy' => Icons.icecream_rounded,
    'rainbow' => Icons.gradient_rounded,
    'sparkle' => Icons.auto_awesome_rounded,
    'cloud' => Icons.cloud_rounded,
    'moon' => Icons.dark_mode_rounded,
    'cherry' => Icons.eco_rounded,
    'bow' => Icons.redeem_rounded,
    'gem' => Icons.hexagon_rounded,
    'butterfly' => Icons.filter_vintage,
    _ => Icons.star_rounded,
  };
}

IconData ringIcon(String id) {
  return switch (id) {
    'ring_1' => Icons.circle_outlined,
    'ring_2' => Icons.favorite_border_rounded,
    'ring_3' => Icons.star_border_rounded,
    'ring_4' => Icons.hexagon_outlined,
    'ring_5' => Icons.square_outlined,
    'ring_6' => Icons.change_history_rounded,
    'ring_7' => Icons.auto_awesome_rounded,
    'ring_8' => Icons.filter_vintage,
    _ => Icons.circle_outlined,
  };
}

/// The star of the whole game: a cute hand wearing the child's design.
///
/// Renders from the *recipe* (shape, color, pattern, sticker, ring) so the
/// album, the studio and the reveal always agree — and no bitmap is required.
class DesignPreview extends StatelessWidget {
  const DesignPreview({
    this.shape,
    this.colorOption,
    this.pattern,
    this.sticker,
    this.ring,
    this.showSticker = true,
    this.showRing = true,
    this.showSparkles = true,
    this.padding = 16,
    super.key,
  });

  final NailShape? shape;
  final NailColorOption? colorOption;
  final NailPattern? pattern;
  final DecorItem? sticker;
  final DecorItem? ring;
  final bool showSticker;
  final bool showRing;
  final bool showSparkles;
  final double padding;

  static const Color _skin = Color(0xFFFFD9BE);
  static const Color _skinDeep = Color(0xFFF5C4A4);
  static const Color _outline = Color(0xFFE0A783);
  static const Color _bare = Color(0xFFFFF0E4);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth - padding * 2;
        final double h = constraints.maxHeight - padding * 2;

        final double nailW = w * 0.135;
        final double nailH = h * 0.26;

        return Padding(
          padding: EdgeInsets.all(padding),
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                if (showSparkles)
                  Positioned.fill(child: _SparkleLayer(show: showSparkles)),
                // Palm
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: w * 0.70,
                    height: h * 0.36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[_skin, _skinDeep],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(w * 0.16),
                        topRight: Radius.circular(w * 0.16),
                        bottomLeft: Radius.circular(w * 0.20),
                        bottomRight: Radius.circular(w * 0.20),
                      ),
                      border: Border.all(color: _outline, width: 2.4),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 14,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                ),
                // Fingers with their nails
                Positioned(
                  top: 0,
                  bottom: h * 0.20,
                  left: w * 0.06,
                  right: w * 0.06,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List<Widget>.generate(4, (int index) {
                      final bool isStickerFinger = index == 1;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: w * 0.012),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[_skin, _skinDeep],
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(nailW),
                                topRight: Radius.circular(nailW),
                                bottomLeft: Radius.circular(w * 0.05),
                                bottomRight: Radius.circular(w * 0.05),
                              ),
                              border: Border.all(color: _outline, width: 2.4),
                            ),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: EdgeInsets.only(top: h * 0.02),
                                child: SizedBox(
                                  width: nailW,
                                  height: nailH,
                                  child: NailSwatch(
                                    shape: shape ?? NailShape.round,
                                    color: colorOption?.color ?? _bare,
                                    patternId: pattern?.id,
                                    sticker: isStickerFinger && showSticker
                                        ? sticker
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // Ring on the middle finger, right above the palm
                if (showRing && ring != null)
                  Positioned(
                    bottom: h * 0.30,
                    left: w * 0.30,
                    child: Transform.rotate(
                      angle: 0.12,
                      child: _Ring(ring: ring!, size: w * 0.10),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A single painted nail (used by the hand and by the option tiles).
class NailSwatch extends StatelessWidget {
  const NailSwatch({
    required this.shape,
    required this.color,
    this.patternId,
    this.sticker,
    this.showGloss = true,
    super.key,
  });

  final NailShape shape;
  final Color color;
  final String? patternId;
  final DecorItem? sticker;
  final bool showGloss;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(
      shape == NailShape.almond ? 999.0 : (shape == NailShape.round ? 18.0 : 8.0),
    );
    final bool isBare = color == DesignPreview._bare;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.lerp(color, AppColors.white, isBare ? 0.2 : 0.35)!,
            color,
          ],
        ),
        borderRadius: radius,
        border: Border.all(
          color: isBare
              ? AppColors.white.withValues(alpha: 0.85)
              : AppColors.white,
          width: 2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: isBare ? 0.10 : 0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (patternId != null && !isBare)
              CustomPaint(
                painter: _PatternPainter(
                  patternId: patternId!,
                  baseColor: color,
                ),
              ),
            if (showGloss)
              Align(
                alignment: const Alignment(-0.45, -0.55),
                child: FractionallySizedBox(
                  widthFactor: 0.34,
                  heightFactor: 0.20,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            if (sticker != null)
              Center(
                child: FractionallySizedBox(
                  widthFactor: 0.82,
                  heightFactor: 0.60,
                  child: SafeAssetImage(
                    asset: sticker!.asset,
                    width: null,
                    height: null,
                    fallbackIcon: stickerIcon(sticker!.id),
                    fallbackColor: Color.lerp(color, AppColors.pink, 0.35)!,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.ring, required this.size});

  final DecorItem ring;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 0.62,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.yellow, width: 2.4),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          ringIcon(ring.id),
          size: size * 0.42,
          color: AppColors.lavender,
        ),
      ),
    );
  }
}

/// Soft sparkles that make a finished design feel special.
class _SparkleLayer extends StatelessWidget {
  const _SparkleLayer({required this.show});

  final bool show;

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    return CustomPaint(painter: _SparklePainter());
  }
}

class _SparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const List<Offset> spots = <Offset>[
      Offset(0.14, 0.18),
      Offset(0.86, 0.24),
      Offset(0.24, 0.86),
      Offset(0.78, 0.78),
      Offset(0.50, 0.08),
    ];
    const List<Color> colors = <Color>[
      AppColors.yellow,
      AppColors.pink,
      AppColors.sky,
      AppColors.mint,
      AppColors.lavender,
    ];

    for (int i = 0; i < spots.length; i++) {
      final Offset center = Offset(spots[i].dx * size.width, spots[i].dy * size.height);
      final double radius = size.shortestSide * 0.028;
      final Paint paint = Paint()
        ..color = colors[i].withValues(alpha: 0.85)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = radius * 0.5;
      canvas.drawLine(center.translate(-radius, 0), center.translate(radius, 0), paint);
      canvas.drawLine(center.translate(0, -radius), center.translate(0, radius), paint);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) => false;
}

class _PatternPainter extends CustomPainter {
  _PatternPainter({required this.patternId, required this.baseColor});

  final String patternId;
  final Color baseColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Path clip = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.6)),
      );
    canvas.save();
    canvas.clipPath(clip);

    switch (patternId) {
      case 'glitter':
        _glitter(canvas, size);
      case 'stripes':
        _stripes(canvas, size);
      case 'stars':
        _stars(canvas, size);
      case 'rainbow':
        _rainbow(canvas, size);
      case 'french':
        _french(canvas, size);
      default:
        break;
    }

    canvas.restore();
  }

  void _glitter(Canvas canvas, Size size) {
    final math.Random random = math.Random(9);
    const List<Color> palette = <Color>[
      AppColors.white,
      AppColors.yellow,
      Color(0xFFFFB3D1),
      AppColors.sky,
    ];
    for (int i = 0; i < 22; i++) {
      final Offset point = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      canvas.drawCircle(
        point,
        size.width * (0.03 + random.nextDouble() * 0.05),
        Paint()
          ..color = palette[i % palette.length].withValues(alpha: 0.9),
      );
    }
  }

  void _stripes(Canvas canvas, Size size) {
    canvas.save();
    canvas.rotate(-0.6);
    final Paint paint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.6)
      ..strokeWidth = size.width * 0.14
      ..strokeCap = StrokeCap.round;
    for (double y = -size.height; y < size.height * 2; y += size.height * 0.34) {
      canvas.drawLine(
        Offset(-size.width, y),
        Offset(size.width * 2, y),
        paint,
      );
    }
    canvas.restore();
  }

  void _stars(Canvas canvas, Size size) {
    const List<Offset> spots = <Offset>[
      Offset(0.32, 0.20),
      Offset(0.68, 0.38),
      Offset(0.38, 0.62),
      Offset(0.62, 0.82),
    ];
    for (int i = 0; i < spots.length; i++) {
      final Offset center =
          Offset(spots[i].dx * size.width, spots[i].dy * size.height);
      final double radius = size.width * 0.14;
      final Paint paint = Paint()
        ..color = (i.isEven ? AppColors.white : AppColors.yellow)
            .withValues(alpha: 0.95)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = radius * 0.42;
      canvas.drawLine(center.translate(-radius, 0), center.translate(radius, 0), paint);
      canvas.drawLine(center.translate(0, -radius), center.translate(0, radius), paint);
    }
  }

  void _rainbow(Canvas canvas, Size size) {
    const List<Color> bands = <Color>[
      AppColors.pink,
      AppColors.yellow,
      AppColors.mint,
      AppColors.sky,
      AppColors.lavender,
    ];
    final double bandHeight = size.height / bands.length;
    for (int i = 0; i < bands.length; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * bandHeight, size.width, bandHeight),
        Paint()..color = bands[i].withValues(alpha: 0.75),
      );
    }
  }

  void _french(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.30),
      Paint()..color = AppColors.white.withValues(alpha: 0.92),
    );
  }

  @override
  bool shouldRepaint(_PatternPainter oldDelegate) =>
      oldDelegate.patternId != patternId ||
      oldDelegate.baseColor != baseColor;
}
