import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/models/nail_item_model.dart';
import '../data/models/skin_tone.dart';
import 'realistic_hand.dart';

/// The five spa steps, from cleaning to moisturising.
enum SpaStage { clean, soap, rinse, dry, cream }

/// A spa scene built around the photographic hand asset.
///
/// The hand image is real artwork with natural fingers and nail beds. The
/// stage layers are effects only: dirt, foam, water and cream are painted over
/// the skin and respond to the same continuous drag used by the controller.
class HandIllustration extends StatelessWidget {
  const HandIllustration({
    required this.stage,
    required this.progress,
    this.polish,
    this.skinTone = SkinTone.natural,
    this.toolPosition,
    super.key,
  });

  final SpaStage stage;
  final double progress;
  final Color? polish;
  final SkinTone skinTone;
  final Offset? toolPosition;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 360.0;
        final double height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : width * 1.45;
        final double handWidth = math.max(
          1.0,
          math.min(width * 0.76, height * 0.495),
        ).toDouble();
        final double handHeight = handWidth / 0.5;
        final double handLeft = (width - handWidth) / 2;
        final double handTop = math.max(0.0, (height - handHeight) * 0.10).toDouble();
        final Offset tool = toolPosition ?? Offset(width * 0.80, height * 0.80);
        final double clippedProgress = progress.clamp(0.0, 1.0).toDouble();

        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            const Positioned.fill(child: CustomPaint(painter: SpaTablePainter())),
            Positioned(
              left: handLeft,
              top: handTop,
              width: handWidth,
              height: handHeight,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  RealisticHandPreview(
                    colorOption: polish == null
                        ? null
                        : _singleColourOption(polish!),
                    nailProgress: polish == null
                        ? const <int, double>{}
                        : const <int, double>{
                            0: 1,
                            1: 1,
                            2: 1,
                            3: 1,
                            4: 1,
                          },
                    skinTone: skinTone,
                    showSparkles: stage == SpaStage.dry && clippedProgress > 0.8,
                    padding: 0,
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _SpaEffectPainter(
                          stage: stage,
                          progress: clippedProgress,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: tool.dx - 56,
              top: tool.dy - 45,
              child: IgnorePointer(
                child: SpaToolVisual(stage: stage, progress: clippedProgress),
              ),
            ),
          ],
        );
      },
    );
  }

  NailColorOption _singleColourOption(Color value) => NailColorOption(
        id: 'spa-polish',
        label: 'Spa polish',
        color: value,
      );
}

/// A lightly brushed spa counter behind the hand. It gives the real asset a
/// place to sit without hiding it behind a flat white card.
class SpaTablePainter extends CustomPainter {
  const SpaTablePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFFF7FC), Color(0xFFEDE7FF)],
        ).createShader(bounds),
    );

    final Rect tray = Rect.fromCenter(
      center: Offset(size.width * 0.50, size.height * 0.70),
      width: size.width * 0.80,
      height: size.height * 0.52,
    );
    canvas.drawOval(
      tray,
      Paint()..color = AppColors.lavender.withValues(alpha: 0.07),
    );
    canvas.drawOval(
      tray,
      Paint()
        ..color = AppColors.white.withValues(alpha: 0.78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.50, size.height * 0.84),
        width: size.width * 0.70,
        height: size.height * 0.07,
      ),
      Paint()..color = AppColors.shadow.withValues(alpha: 0.45),
    );

    for (final Offset point in <Offset>[
      Offset(size.width * 0.12, size.height * 0.16),
      Offset(size.width * 0.88, size.height * 0.22),
      Offset(size.width * 0.14, size.height * 0.86),
      Offset(size.width * 0.88, size.height * 0.88),
    ]) {
      canvas.drawCircle(
        point,
        size.shortestSide * 0.018,
        Paint()..color = AppColors.white.withValues(alpha: 0.76),
      );
    }
  }

  @override
  bool shouldRepaint(SpaTablePainter oldDelegate) => false;
}

class _SpaEffectPainter extends CustomPainter {
  _SpaEffectPainter({required this.stage, required this.progress});

  final SpaStage stage;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    switch (stage) {
      case SpaStage.clean:
        _dirt(canvas, size);
      case SpaStage.soap:
        _bubbles(canvas, size);
      case SpaStage.rinse:
        _water(canvas, size);
      case SpaStage.dry:
        _dry(canvas, size);
      case SpaStage.cream:
        _cream(canvas, size);
    }
  }

  void _dirt(Canvas canvas, Size size) {
    final double alpha = (1 - progress).clamp(0.0, 1.0).toDouble();
    if (alpha < 0.01) return;
    final Paint paint = Paint()
      ..color = const Color(0xFF8C665A).withValues(alpha: 0.48 * alpha);
    const List<Offset> spots = <Offset>[
      Offset(0.31, 0.31),
      Offset(0.46, 0.26),
      Offset(0.59, 0.36),
      Offset(0.39, 0.56),
      Offset(0.57, 0.62),
      Offset(0.48, 0.75),
      Offset(0.68, 0.51),
      Offset(0.28, 0.70),
    ];
    for (int i = 0; i < spots.length; i++) {
      final Offset point = Offset(spots[i].dx * size.width, spots[i].dy * size.height);
      final double radius = size.width * (0.018 + (i % 3) * 0.006);
      canvas.drawCircle(point, radius, paint);
      canvas.drawLine(
        point.translate(-radius * 1.5, radius * 0.7),
        point.translate(radius * 1.2, -radius * 0.7),
        Paint()
          ..color = const Color(0xFF6E4C42).withValues(alpha: 0.38 * alpha)
          ..strokeWidth = radius * 0.55
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _bubbles(Canvas canvas, Size size) {
    const List<Offset> spots = <Offset>[
      Offset(0.20, 0.29),
      Offset(0.38, 0.40),
      Offset(0.60, 0.32),
      Offset(0.75, 0.48),
      Offset(0.27, 0.60),
      Offset(0.51, 0.68),
      Offset(0.70, 0.76),
      Offset(0.39, 0.22),
      Offset(0.81, 0.30),
    ];
    for (int i = 0; i < spots.length; i++) {
      final double appear =
          ((progress * 1.45) - i * 0.06).clamp(0.0, 1.0).toDouble();
      if (appear <= 0.01) continue;
      final double radius = size.width * (0.026 + (i % 3) * 0.010) * appear;
      final Offset center = Offset(
        spots[i].dx * size.width,
        spots[i].dy * size.height - radius,
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = Colors.white.withValues(alpha: 0.57 * appear),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = AppColors.sky.withValues(alpha: 0.72 * appear)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, size.width * 0.006).toDouble(),
      );
      canvas.drawCircle(
        center.translate(-radius * 0.32, -radius * 0.32),
        radius * 0.20,
        Paint()..color = Colors.white.withValues(alpha: 0.90 * appear),
      );
    }
  }

  void _water(Canvas canvas, Size size) {
    final double alpha = progress.clamp(0.0, 1.0).toDouble();
    final Paint stream = Paint()
      ..color = AppColors.sky.withValues(alpha: 0.52 * alpha)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(2.0, size.width * 0.018).toDouble();
    for (final double x in <double>[0.20, 0.35, 0.50, 0.65, 0.79]) {
      final Path path = Path()
        ..moveTo(size.width * x, -size.height * 0.06)
        ..cubicTo(
          size.width * (x - 0.05),
          size.height * 0.16,
          size.width * (x + 0.04),
          size.height * 0.30,
          size.width * x,
          size.height * 0.47,
        );
      canvas.drawPath(path, stream);
    }
    for (int i = 0; i < 8; i++) {
      final Offset point = Offset(
        size.width * (0.16 + i * 0.095),
        size.height * (0.64 + math.sin(i * 1.7) * 0.06),
      );
      canvas.drawCircle(
        point,
        size.width * 0.014,
        Paint()..color = AppColors.sky.withValues(alpha: 0.54 * alpha),
      );
    }
  }

  void _dry(Canvas canvas, Size size) {
    final double alpha = progress.clamp(0.0, 1.0).toDouble();
    final Paint line = Paint()
      ..color = Colors.white.withValues(alpha: 0.48 * alpha)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(2.0, size.width * 0.022).toDouble();
    for (int i = 0; i < 5; i++) {
      final double x = size.width * (0.27 + i * 0.11);
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(x, size.height * 0.54),
          width: size.width * 0.13,
          height: size.height * 0.13,
        ),
        -0.6,
        1.35,
        false,
        line,
      );
    }
  }

  void _cream(Canvas canvas, Size size) {
    final double alpha = progress.clamp(0.0, 1.0).toDouble();
    final Paint glow = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          Colors.white.withValues(alpha: 0.48 * alpha),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.48, size.height * 0.57),
          radius: size.width * 0.38,
        ),
      );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.49, size.height * 0.58),
        width: size.width * 0.58,
        height: size.height * 0.38,
      ),
      glow,
    );
    for (int i = 0; i < 5; i++) {
      final Offset point = Offset(
        size.width * (0.29 + i * 0.11),
        size.height * (0.37 + math.sin(i * 1.2) * 0.14),
      );
      final double radius = size.width * 0.015 * alpha;
      canvas.drawCircle(point, radius, Paint()..color = AppColors.pink.withValues(alpha: 0.46 * alpha));
    }
  }

  @override
  bool shouldRepaint(_SpaEffectPainter oldDelegate) =>
      oldDelegate.stage != stage || oldDelegate.progress != progress;
}

/// The object the child sees following the finger in each stage.
class SpaToolVisual extends StatelessWidget {
  const SpaToolVisual({required this.stage, required this.progress, super.key});

  final SpaStage stage;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 90,
      child: CustomPaint(
        painter: _SpaToolPainter(stage: stage, progress: progress),
      ),
    );
  }
}

class _SpaToolPainter extends CustomPainter {
  _SpaToolPainter({required this.stage, required this.progress});

  final SpaStage stage;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.50, h * 0.90), width: w * 0.68, height: h * 0.12),
      Paint()..color = Colors.black.withValues(alpha: 0.14),
    );
    switch (stage) {
      case SpaStage.clean:
        _sponge(canvas, size);
      case SpaStage.soap:
        _soap(canvas, size);
      case SpaStage.rinse:
        _rinse(canvas, size);
      case SpaStage.dry:
        _towel(canvas, size);
      case SpaStage.cream:
        _cream(canvas, size);
    }
  }

  void _sponge(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(size.width * 0.16, size.height * 0.16, size.width * 0.68, size.height * 0.58);
    final RRect sponge = RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.20));
    canvas.drawRRect(
      sponge,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFFF5A8), Color(0xFFFFC94D), Color(0xFFE9A12D)],
        ).createShader(rect),
    );
    final math.Random random = math.Random(4);
    for (int i = 0; i < 20; i++) {
      final Offset point = Offset(
        rect.left + random.nextDouble() * rect.width,
        rect.top + random.nextDouble() * rect.height,
      );
      canvas.drawCircle(
        point,
        size.width * (0.012 + random.nextDouble() * 0.018),
        Paint()..color = const Color(0xFFB77C29).withValues(alpha: 0.25),
      );
    }
    canvas.drawRRect(
      sponge,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.46)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _soap(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Rect body = Rect.fromLTWH(w * 0.28, h * 0.31, w * 0.44, h * 0.48);
    final RRect bottle = RRect.fromRectAndRadius(body, Radius.circular(w * 0.09));
    canvas.drawRRect(
      bottle,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFFFFFFFF), Color(0xFFB7E9FF), Color(0xFF62BDEB)],
        ).createShader(body),
    );
    canvas.drawRRect(
      bottle,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    final Rect pump = Rect.fromLTWH(w * 0.39, h * 0.18, w * 0.22, h * 0.18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(pump, Radius.circular(w * 0.04)),
      Paint()..color = const Color(0xFF8CCEEB),
    );
    canvas.drawLine(
      Offset(w * 0.50, h * 0.18),
      Offset(w * 0.67, h * 0.12),
      Paint()
        ..color = const Color(0xFF8CCEEB)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    for (int i = 0; i < 3; i++) {
      final Offset point = Offset(w * (0.17 + i * 0.30), h * (0.20 + i * 0.08));
      canvas.drawCircle(point, w * (0.06 - i * 0.01), Paint()..color = Colors.white.withValues(alpha: 0.78));
      canvas.drawCircle(
        point,
        w * (0.06 - i * 0.01),
        Paint()
          ..color = AppColors.sky.withValues(alpha: 0.68)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  void _rinse(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint blue = Paint()
      ..color = AppColors.sky
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(w * 0.16, h * 0.12, w * 0.63, h * 0.62),
      0.4,
      2.7,
      false,
      blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.10,
    );
    canvas.drawLine(
      Offset(w * 0.62, h * 0.58),
      Offset(w * 0.78, h * 0.78),
      blue..strokeWidth = w * 0.06,
    );
    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(w * (0.32 + i * 0.12), h * (0.76 + (i % 2) * 0.06)),
        w * 0.025,
        Paint()..color = AppColors.sky.withValues(alpha: 0.58),
      );
    }
  }

  void _towel(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(size.width * 0.09, size.height * 0.18, size.width * 0.78, size.height * 0.58);
    final RRect towel = RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.10));
    canvas.drawRRect(
      towel,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFFFFFF), Color(0xFFE5D9FF), Color(0xFFC5B1EF)],
        ).createShader(rect),
    );
    for (int i = 0; i < 6; i++) {
      final double x = rect.left + rect.width * (0.12 + i * 0.15);
      canvas.drawLine(
        Offset(x, rect.top + rect.height * 0.15),
        Offset(x - size.width * 0.03, rect.bottom - rect.height * 0.12),
        Paint()
          ..color = AppColors.lavender.withValues(alpha: 0.24)
          ..strokeWidth = 2,
      );
    }
    canvas.drawRRect(
      towel,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _cream(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Path tube = Path()
      ..moveTo(w * 0.22, h * 0.23)
      ..quadraticBezierTo(w * 0.50, h * 0.12, w * 0.77, h * 0.23)
      ..lineTo(w * 0.70, h * 0.76)
      ..quadraticBezierTo(w * 0.50, h * 0.85, w * 0.30, h * 0.76)
      ..close();
    canvas.drawPath(
      tube,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFFFFFEFF), Color(0xFFFFB8DB), Color(0xFFE889BA)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      tube,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.41, h * 0.13, w * 0.18, h * 0.13),
      Paint()..color = AppColors.pink,
    );
    canvas.drawCircle(
      Offset(w * 0.55, h * 0.20),
      w * 0.075,
      Paint()..color = Colors.white.withValues(alpha: 0.82),
    );
  }

  @override
  bool shouldRepaint(_SpaToolPainter oldDelegate) =>
      oldDelegate.stage != stage || oldDelegate.progress != progress;
}
