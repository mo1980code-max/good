import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/animations/motion_policy.dart';
import '../core/theme/app_colors.dart';
import '../data/models/character_model.dart';

/// How the friend is feeling right now — drives the eyes and the smile.
enum FaceMood { calm, happy, amazed, sleepy }

/// A fully **procedural** cartoon face for each character.
///
/// Why not images? The game must look alive and cute even before any art is
/// delivered, and a painted face can blink, breathe and react instantly —
/// which is exactly what GDD law #6 ("the mascot is alive") asks for.
class CharacterFace extends ConsumerStatefulWidget {
  const CharacterFace({
    required this.character,
    this.size = 150,
    this.mood = FaceMood.calm,
    this.blink = true,
    super.key,
  });

  final CharacterModel character;
  final double size;
  final FaceMood mood;
  final bool blink;

  @override
  ConsumerState<CharacterFace> createState() => _CharacterFaceState();
}

class _CharacterFaceState extends ConsumerState<CharacterFace>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  /// Keeps the looping "alive" ticker in step with the motion setting:
  /// calm mode paints a single still frame (no blink, no breathing).
  void _syncTicker(bool calm) {
    if (calm) {
      if (_controller.value != 0) {
        // Setting `value` also stops the ticker.
        _controller.value = 0;
      } else if (_controller.isAnimating) {
        _controller.stop();
      }
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _syncTicker(MotionPolicy.of(context, ref).reduceMotion);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double t = _controller.value;
          // Blink during a short window at the end of every cycle.
          double openness = 1;
          if (widget.blink && t > 0.90) {
            final double blinkT = (t - 0.90) / 0.10;
            openness =
                (1 - math.sin(blinkT * math.pi)).clamp(0.0, 1.0).toDouble();
          }
          return CustomPaint(
            painter: _FacePainter(
              character: widget.character,
              mood: widget.mood,
              eyeOpenness: openness,
              breath: math.sin(t * 2 * math.pi),
            ),
            size: Size.square(widget.size),
          );
        },
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  _FacePainter({
    required this.character,
    required this.mood,
    required this.eyeOpenness,
    required this.breath,
  });

  final CharacterModel character;
  final FaceMood mood;
  final double eyeOpenness;
  final double breath;

  static const Color _ink = Color(0xFF3B2A5A);
  static const Color _blush = Color(0xFFFF9EC4);

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final Offset head = Offset(s / 2, s * 0.58 + breath * s * 0.006);
    final double r = s * 0.29;

    final Color base = Color.lerp(character.accent, AppColors.white, 0.62)!;
    final Color edge = Color.lerp(character.accent, AppColors.white, 0.18)!;

    _paintBackFeatures(canvas, head, r, edge, base);

    // Head
    final Paint headPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.5),
        colors: <Color>[AppColors.white, base],
      ).createShader(Rect.fromCircle(center: head, radius: r * 1.15));
    canvas.drawCircle(head, r, headPaint);

    _paintFrontFeatures(canvas, head, r, edge);

    // Blush
    final Paint blushPaint = Paint()..color = _blush.withValues(alpha: 0.45);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(head.dx - r * 0.62, head.dy + r * 0.35),
        width: r * 0.5,
        height: r * 0.32,
      ),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(head.dx + r * 0.62, head.dy + r * 0.35),
        width: r * 0.5,
        height: r * 0.32,
      ),
      blushPaint,
    );

    _paintEyes(canvas, head, r);
    _paintMouth(canvas, head, r);
  }

  // --- Eyes & mouth --------------------------------------------------------

  void _paintEyes(Canvas canvas, Offset head, double r) {
    final double eyeY = head.dy - r * 0.05;
    final double rx = r * (mood == FaceMood.amazed ? 0.24 : 0.21);
    final double ry = r * 0.26 * eyeOpenness;

    for (final double dir in <double>[-1, 1]) {
      final Offset center = Offset(head.dx + dir * r * 0.38, eyeY);
      if (eyeOpenness < 0.16) {
        // Closed eye: a happy little arc.
        canvas.drawArc(
          Rect.fromCenter(center: center, width: rx * 2, height: ry * 2 + 4),
          math.pi,
          math.pi,
          false,
          Paint()
            ..color = _ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.09
            ..strokeCap = StrokeCap.round,
        );
        continue;
      }

      canvas.drawOval(
        Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
        Paint()..color = _ink,
      );
      canvas.drawCircle(
        Offset(center.dx - rx * 0.34, center.dy - ry * 0.42),
        rx * 0.30,
        Paint()..color = AppColors.white,
      );
      canvas.drawCircle(
        Offset(center.dx + rx * 0.30, center.dy + ry * 0.34),
        rx * 0.16,
        Paint()..color = AppColors.white.withValues(alpha: 0.85),
      );
    }
  }

  void _paintMouth(Canvas canvas, Offset head, double r) {
    final Paint mouthPaint = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.07
      ..strokeCap = StrokeCap.round;

    switch (mood) {
      case FaceMood.amazed:
        canvas.drawCircle(
          Offset(head.dx, head.dy + r * 0.45),
          r * 0.13,
          Paint()..color = _ink,
        );
      case FaceMood.happy:
        final Rect smile = Rect.fromCenter(
          center: Offset(head.dx, head.dy + r * 0.34),
          width: r * 0.62,
          height: r * 0.5,
        );
        canvas.drawArc(smile, 0.15, math.pi - 0.30, false, mouthPaint);
        canvas.drawCircle(
          Offset(head.dx, head.dy + r * 0.55),
          r * 0.08,
          Paint()..color = const Color(0xFFFF7AA8),
        );
      case FaceMood.sleepy:
        canvas.drawCircle(
          Offset(head.dx, head.dy + r * 0.45),
          r * 0.07,
          Paint()..color = _ink,
        );
      case FaceMood.calm:
        final Rect smile = Rect.fromCenter(
          center: Offset(head.dx, head.dy + r * 0.36),
          width: r * 0.42,
          height: r * 0.30,
        );
        canvas.drawArc(smile, 0.25, math.pi - 0.50, false, mouthPaint);
    }
  }

  // --- Per-character decorations ------------------------------------------

  void _paintBackFeatures(
    Canvas canvas,
    Offset head,
    double r,
    Color edge,
    Color base,
  ) {
    final Paint edgePaint = Paint()..color = edge;

    switch (character.id) {
      case 'kitty':
        _triangleEar(canvas, head, r, -1, edgePaint);
        _triangleEar(canvas, head, r, 1, edgePaint);
      case 'bunny':
        _longEar(canvas, head, r, -1, edgePaint);
        _longEar(canvas, head, r, 1, edgePaint);
      case 'panda':
        final Paint dark = Paint()..color = const Color(0xFF4B4B5C);
        canvas.drawCircle(
          Offset(head.dx - r * 0.78, head.dy - r * 0.72),
          r * 0.34,
          dark,
        );
        canvas.drawCircle(
          Offset(head.dx + r * 0.78, head.dy - r * 0.72),
          r * 0.34,
          dark,
        );
      case 'unicorn':
        _triangleEar(canvas, head, r, -1, edgePaint, scale: 0.8);
        _triangleEar(canvas, head, r, 1, edgePaint, scale: 0.8);
        _horn(canvas, head, r);
        _mane(canvas, head, r);
      case 'fairy':
        _wings(canvas, head, r);
      case 'kid':
        _hair(canvas, head, r);
      default:
        _triangleEar(canvas, head, r, -1, edgePaint);
        _triangleEar(canvas, head, r, 1, edgePaint);
    }
  }

  void _paintFrontFeatures(
    Canvas canvas,
    Offset head,
    double r,
    Color edge,
  ) {
    switch (character.id) {
      case 'kitty':
        // Inner ears + whiskers.
        _triangleEar(
          canvas,
          head,
          r,
          -1,
          Paint()..color = _blush.withValues(alpha: 0.75),
          scale: 0.5,
        );
        _triangleEar(
          canvas,
          head,
          r,
          1,
          Paint()..color = _blush.withValues(alpha: 0.75),
          scale: 0.5,
        );
        _whiskers(canvas, head, r);
      case 'bunny':
        _longEar(
          canvas,
          head,
          r,
          -1,
          Paint()..color = _blush.withValues(alpha: 0.55),
          scale: 0.55,
        );
        _longEar(
          canvas,
          head,
          r,
          1,
          Paint()..color = _blush.withValues(alpha: 0.55),
          scale: 0.55,
        );
      case 'panda':
        final Paint patch = Paint()..color = const Color(0xFF4B4B5C);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(head.dx - r * 0.38, head.dy - r * 0.05),
            width: r * 0.62,
            height: r * 0.72,
          ),
          patch,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(head.dx + r * 0.38, head.dy - r * 0.05),
            width: r * 0.62,
            height: r * 0.72,
          ),
          patch,
        );
      case 'fairy':
        _antennae(canvas, head, r);
      default:
        break;
    }
  }

  void _triangleEar(
    Canvas canvas,
    Offset head,
    double r,
    double dir,
    Paint paint, {
    double scale = 1,
  }) {
    final double baseX = head.dx + dir * r * 0.62;
    final double baseY = head.dy - r * 0.72;
    final double w = r * 0.46 * scale;
    final double h = r * 0.78 * scale;

    final Path path = Path()
      ..moveTo(baseX - w, baseY + h * 0.35)
      ..lineTo(baseX + dir * w * 0.25, baseY - h * 0.65)
      ..lineTo(baseX + w, baseY + h * 0.35)
      ..close();

    canvas.drawPath(path, paint);
  }

  void _longEar(
    Canvas canvas,
    Offset head,
    double r,
    double dir,
    Paint paint, {
    double scale = 1,
  }) {
    canvas.save();
    canvas.translate(head.dx + dir * r * 0.34, head.dy - r * 1.02);
    canvas.rotate(dir * 0.16);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: r * 0.5 * scale + r * 0.16 * (scale == 1 ? 1 : 0),
        height: r * 1.34 * scale,
      ),
      paint,
    );
    canvas.restore();
  }

  void _horn(Canvas canvas, Offset head, double r) {
    final Path horn = Path()
      ..moveTo(head.dx - r * 0.24, head.dy - r * 0.90)
      ..lineTo(head.dx, head.dy - r * 1.62)
      ..lineTo(head.dx + r * 0.24, head.dy - r * 0.90)
      ..close();

    canvas.drawPath(horn, Paint()..color = AppColors.white);

    canvas.save();
    canvas.clipPath(horn);
    final List<Color> stripes = <Color>[
      AppColors.pink,
      AppColors.yellow,
      AppColors.mint,
      AppColors.sky,
    ];
    final double stripeHeight = r * 0.20;
    for (int i = 0; i < stripes.length; i++) {
      final double top = head.dy - r * 1.62 + i * stripeHeight;
      canvas.drawRect(
        Rect.fromLTWH(head.dx - r * 0.4, top, r * 0.8, stripeHeight * 0.62),
        Paint()..color = stripes[i].withValues(alpha: 0.9),
      );
    }
    canvas.restore();
  }

  void _mane(Canvas canvas, Offset head, double r) {
    final Paint manePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = r * 0.20;

    final List<Color> colors = <Color>[
      AppColors.pink,
      AppColors.lavender,
      AppColors.sky,
    ];
    for (int i = 0; i < colors.length; i++) {
      final Rect rect = Rect.fromCenter(
        center: Offset(head.dx + r * 0.34, head.dy + r * 0.12),
        width: r * (2.3 + i * 0.34),
        height: r * (2.0 + i * 0.30),
      );
      canvas.drawArc(
        rect,
        -0.65 + i * 0.28,
        1.5,
        false,
        manePaint..color = colors[i].withValues(alpha: 0.85),
      );
    }
  }

  void _wings(Canvas canvas, Offset head, double r) {
    final Paint wing = Paint()
      ..color = AppColors.sky.withValues(alpha: 0.45);

    for (final double dir in <double>[-1, 1]) {
      canvas.save();
      canvas.translate(head.dx + dir * r * 1.10, head.dy - r * 0.10);
      canvas.rotate(dir * 0.5);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: r * 0.9,
          height: r * 1.7,
        ),
        wing,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(dir * r * 0.55, r * 0.55),
          width: r * 0.62,
          height: r * 1.05,
        ),
        Paint()..color = AppColors.pink.withValues(alpha: 0.35),
      );
      canvas.restore();
    }
  }

  void _antennae(Canvas canvas, Offset head, double r) {
    final Paint antenna = Paint()
      ..color = _ink
      ..strokeWidth = r * 0.06
      ..strokeCap = StrokeCap.round;

    for (final double dir in <double>[-1, 1]) {
      final Path path = Path()
        ..moveTo(head.dx + dir * r * 0.30, head.dy - r * 0.92)
        ..quadraticBezierTo(
          head.dx + dir * r * 0.62,
          head.dy - r * 1.45,
          head.dx + dir * r * 0.30,
          head.dy - r * 1.62,
        );
      canvas.drawPath(
        path,
        antenna
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.06,
      );
      canvas.drawCircle(
        Offset(head.dx + dir * r * 0.30, head.dy - r * 1.64),
        r * 0.10,
        Paint()..color = AppColors.yellow,
      );
    }
  }

  void _hair(Canvas canvas, Offset head, double r) {
    final Paint hairPaint = Paint()..color = const Color(0xFF7A4B2E);
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: head, radius: r * 1.01)),
    );
    canvas.drawArc(
      Rect.fromCircle(center: head, radius: r * 1.02),
      math.pi * 1.02,
      math.pi * 0.96,
      true,
      hairPaint,
    );
    // A cheeky cowlick.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(head.dx - r * 0.05, head.dy - r * 1.12),
        width: r * 0.30,
        height: r * 0.46,
      ),
      hairPaint,
    );
    canvas.restore();
  }

  void _whiskers(Canvas canvas, Offset head, double r) {
    final Paint whisker = Paint()
      ..color = _ink.withValues(alpha: 0.35)
      ..strokeWidth = r * 0.035
      ..strokeCap = StrokeCap.round;

    for (final double dir in <double>[-1, 1]) {
      for (int i = 0; i < 3; i++) {
        final double y = head.dy + r * (0.22 + i * 0.13);
        canvas.drawLine(
          Offset(head.dx + dir * r * 0.72, y),
          Offset(head.dx + dir * r * 1.18, y - r * 0.05 + i * r * 0.05),
          whisker,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FacePainter oldDelegate) =>
      oldDelegate.eyeOpenness != eyeOpenness ||
      oldDelegate.mood != mood ||
      oldDelegate.character.id != character.id ||
      oldDelegate.breath != breath;
}
