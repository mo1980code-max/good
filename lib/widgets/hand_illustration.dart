import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// The five spa steps, from dirty hand to glossy cream.
enum SpaStage { clean, soap, rinse, dry, cream }

/// A cartoon hand that changes as the child rubs it.
///
/// 100% procedural: dirt fades out, bubbles grow, water runs, cream shines —
/// no art files needed, and the change is *immediately* visible
/// (GDD: "before/after must feel dramatic").
class HandIllustration extends StatelessWidget {
  const HandIllustration({
    required this.stage,
    required this.progress,
    this.polish, // optional nail color, used by the reveal/studio screens
    super.key,
  });

  final SpaStage stage;

  /// 0..1 progress of the current step.
  final double progress;

  final Color? polish;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.86,
      child: CustomPaint(
        painter: _HandPainter(
          stage: stage,
          progress: progress.clamp(0.0, 1.0),
          polish: polish,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _HandPainter extends CustomPainter {
  _HandPainter({
    required this.stage,
    required this.progress,
    this.polish,
  });

  final SpaStage stage;
  final double progress;
  final Color? polish;

  static const Color _skin = Color(0xFFFFD9BE);
  static const Color _skinDeep = Color(0xFFF0BE9C);
  static const Color _outline = Color(0xFFE0A783);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    _paintShadow(canvas, w, h);
    _paintFingers(canvas, w, h);
    _paintPalm(canvas, w, h);
    _paintStageLayer(canvas, w, h);
  }

  void _paintShadow(Canvas canvas, double w, double h) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.95),
        width: w * 0.72,
        height: h * 0.08,
      ),
      Paint()..color = AppColors.lavender.withValues(alpha: 0.12),
    );
  }

  void _paintFingers(Canvas canvas, double w, double h) {
    // Four fingers + thumb, drawn as rounded columns.
    final double fingerW = w * 0.155;
    final double gap = w * 0.018;
    const List<double> heights = <double>[0.60, 0.70, 0.66, 0.52];
    const List<double> tops = <double>[0.20, 0.11, 0.16, 0.28];

    final Paint body = Paint()..color = _skin;
    final Paint line = Paint()
      ..color = _outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    double x = w * 0.5 - (fingerW * 2 + gap * 1.5);
    for (int i = 0; i < 4; i++) {
      final Rect finger = Rect.fromLTWH(
        x,
        h * tops[i],
        fingerW,
        h * heights[i],
      );
      final RRect rrect = RRect.fromRectAndCorners(
        finger,
        topLeft: Radius.circular(fingerW),
        topRight: Radius.circular(fingerW),
        bottomLeft: const Radius.circular(10),
        bottomRight: const Radius.circular(10),
      );
      canvas.drawRRect(rrect, body);
      canvas.drawRRect(rrect, line);

      // Nail on the fingertip.
      final Rect nail = Rect.fromCenter(
        center: Offset(finger.center.dx, finger.top + fingerW * 0.62),
        width: fingerW * 0.68,
        height: fingerW * 0.86,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(nail, Radius.circular(fingerW * 0.34)),
        Paint()..color = (polish ?? const Color(0xFFFFF1E6)).withValues(alpha: 0.95),
      );
      if (polish == null) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(nail, Radius.circular(fingerW * 0.34)),
          Paint()
            ..color = AppColors.white.withValues(alpha: 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      }

      x += fingerW + gap;
    }

    // Thumb
    canvas.save();
    canvas.translate(w * 0.16, h * 0.62);
    canvas.rotate(-0.55);
    final RRect thumb = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: fingerW * 1.02,
        height: h * 0.34,
      ),
      Radius.circular(fingerW),
    );
    canvas.drawRRect(thumb, body);
    canvas.drawRRect(thumb, line);
    canvas.restore();
  }

  void _paintPalm(Canvas canvas, double w, double h) {
    final RRect palm = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.17, h * 0.52, w * 0.66, h * 0.38),
      Radius.circular(w * 0.20),
    );

    canvas.drawRRect(
      palm,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[_skin, _skinDeep],
        ).createShader(palm.outerRect),
    );
    canvas.drawRRect(
      palm,
      Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );

    // Soft inner shadow line for depth.
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.5, h * 0.72), radius: w * 0.22),
      0.35,
      2.45,
      false,
      Paint()
        ..color = _outline.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  // --- Stage-specific layers ----------------------------------------------

  void _paintStageLayer(Canvas canvas, double w, double h) {
    switch (stage) {
      case SpaStage.clean:
        _paintDirt(canvas, w, h, fade: progress);
      case SpaStage.soap:
        _paintBubbles(canvas, w, h, amount: progress);
      case SpaStage.rinse:
        _paintWater(canvas, w, h, amount: progress);
      case SpaStage.dry:
        _paintDrySparkles(canvas, w, h, amount: progress);
      case SpaStage.cream:
        _paintCream(canvas, w, h, amount: progress);
    }
  }

  void _paintDirt(Canvas canvas, double w, double h, {required double fade}) {
    final double alpha = (1 - fade).clamp(0.0, 1.0);
    if (alpha <= 0.01) return;

    final Paint dirt = Paint()..color = const Color(0xFF8D6E63).withValues(alpha: alpha * 0.85);
    const List<Offset> spots = <Offset>[
      Offset(0.32, 0.30),
      Offset(0.48, 0.22),
      Offset(0.63, 0.33),
      Offset(0.40, 0.62),
      Offset(0.60, 0.70),
      Offset(0.30, 0.78),
      Offset(0.52, 0.86),
      Offset(0.72, 0.60),
    ];
    for (int i = 0; i < spots.length; i++) {
      final double scale = 0.5 + (i % 3) * 0.25;
      canvas.drawCircle(
        Offset(spots[i].dx * w, spots[i].dy * h),
        w * 0.035 * scale,
        dirt,
      );
    }
  }

  void _paintBubbles(Canvas canvas, double w, double h, {required double amount}) {
    const List<Offset> spots = <Offset>[
      Offset(0.28, 0.28),
      Offset(0.52, 0.42),
      Offset(0.70, 0.30),
      Offset(0.38, 0.68),
      Offset(0.62, 0.76),
      Offset(0.44, 0.20),
      Offset(0.76, 0.58),
      Offset(0.24, 0.52),
    ];
    for (int i = 0; i < spots.length; i++) {
      final double appear = ((amount * 1.35) - i * 0.06).clamp(0.0, 1.0);
      if (appear <= 0.02) continue;
      final double radius = w * 0.055 * appear;
      final Offset center = Offset(spots[i].dx * w, spots[i].dy * h - radius);
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = AppColors.white.withValues(alpha: 0.72),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = AppColors.sky.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
      canvas.drawCircle(
        Offset(center.dx - radius * 0.35, center.dy - radius * 0.35),
        radius * 0.22,
        Paint()..color = AppColors.white,
      );
    }
  }

  void _paintWater(Canvas canvas, double w, double h, {required double amount}) {
    final double alpha = amount.clamp(0.0, 1.0);
    final Paint stream = Paint()
      ..color = AppColors.sky.withValues(alpha: 0.55 * alpha)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.03;

    for (final double dx in <double>[0.30, 0.44, 0.58, 0.70]) {
      final Path path = Path()
        ..moveTo(w * dx, h * 0.08)
        ..quadraticBezierTo(w * (dx - 0.03), h * 0.34, w * dx, h * 0.60);
      canvas.drawPath(path, stream);
    }

    for (int i = 0; i < 7; i++) {
      final double dx = 0.22 + i * 0.10;
      final double dy = 0.66 + math.sin(i * 1.3) * 0.06;
      canvas.drawCircle(
        Offset(w * dx, h * dy),
        w * 0.028,
        Paint()..color = AppColors.sky.withValues(alpha: 0.5 * alpha),
      );
    }
  }

  void _paintDrySparkles(Canvas canvas, double w, double h, {required double amount}) {
    const List<Offset> spots = <Offset>[
      Offset(0.32, 0.30),
      Offset(0.55, 0.26),
      Offset(0.68, 0.46),
      Offset(0.42, 0.60),
      Offset(0.60, 0.72),
      Offset(0.30, 0.74),
    ];
    for (int i = 0; i < spots.length; i++) {
      final double appear = ((amount * 1.4) - i * 0.08).clamp(0.0, 1.0);
      if (appear <= 0.05) continue;
      _star(
        canvas,
        Offset(spots[i].dx * w, spots[i].dy * h),
        w * 0.035 * appear,
        AppColors.yellow.withValues(alpha: appear),
      );
    }
  }

  void _paintCream(Canvas canvas, double w, double h, {required double amount}) {
    final double alpha = amount.clamp(0.0, 1.0);

    // Glossy highlight sweeping over the palm.
    final RRect palm = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.24, h * 0.56, w * 0.52, h * 0.30),
      Radius.circular(w * 0.16),
    );
    canvas.drawRRect(
      palm,
      Paint()..color = AppColors.white.withValues(alpha: 0.45 * alpha),
    );

    for (int i = 0; i < 5; i++) {
      final double appear = ((amount * 1.3) - i * 0.10).clamp(0.0, 1.0);
      if (appear <= 0.05) continue;
      final Offset center = Offset(
        w * (0.30 + i * 0.10),
        h * (0.34 + math.sin(i) * 0.18),
      );
      _heart(canvas, center, w * 0.045 * appear, AppColors.pink.withValues(alpha: 0.65 * appear));
    }
  }

  // --- Small helpers -------------------------------------------------------

  void _star(Canvas canvas, Offset center, double radius, Color color) {
    final Paint paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * 0.45;
    canvas.drawLine(
      center.translate(-radius, 0),
      center.translate(radius, 0),
      paint,
    );
    canvas.drawLine(
      center.translate(0, -radius),
      center.translate(0, radius),
      paint,
    );
  }

  void _heart(Canvas canvas, Offset center, double radius, Color color) {
    final Path path = Path()
      ..moveTo(center.dx, center.dy + radius * 0.8)
      ..cubicTo(
        center.dx - radius * 1.4,
        center.dy - radius * 0.3,
        center.dx - radius * 0.5,
        center.dy - radius * 1.2,
        center.dx,
        center.dy - radius * 0.35,
      )
      ..cubicTo(
        center.dx + radius * 0.5,
        center.dy - radius * 1.2,
        center.dx + radius * 1.4,
        center.dy - radius * 0.3,
        center.dx,
        center.dy + radius * 0.8,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_HandPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.stage != stage ||
      oldDelegate.polish != polish;
}
