import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants/assets.dart';
import '../core/theme/app_colors.dart';
import '../data/models/nail_item_model.dart';
import '../data/models/skin_tone.dart';
import 'safe_asset_image.dart';

/// The normalized nail beds in the shipped hand artwork.
///
/// Keeping these targets in one place makes the interaction honest: the
/// brush can only paint inside a natural nail bed, never inside an arbitrary
/// rectangle drawn on top of the hand.
const List<Rect> realisticNailRegions = <Rect>[
  Rect.fromLTWH(0.114, 0.222, 0.068, 0.064), // little finger
  Rect.fromLTWH(0.245, 0.143, 0.094, 0.076), // ring finger
  Rect.fromLTWH(0.370, 0.098, 0.096, 0.080), // middle finger
  Rect.fromLTWH(0.525, 0.143, 0.093, 0.078), // index finger
  Rect.fromLTWH(0.700, 0.322, 0.124, 0.082), // thumb
];

/// A single brush movement over the real hand. The screen uses the distance
/// travelled to grow coverage, so a tap cannot complete a nail.
@immutable
class NailBrushEvent {
  const NailBrushEvent({
    required this.nailIndex,
    required this.position,
    required this.distance,
  });

  final int? nailIndex;
  final Offset position;
  final double distance;
}

/// A detailed, image-backed hand with live nail masks on top.
///
/// The hand is a transparent PNG captured for this game, not a row of rounded
/// rectangles. The overlay is deliberately limited to five anatomically placed
/// nail paths and is driven by pointer movement when callbacks are supplied.
class RealisticHandPreview extends StatelessWidget {
  const RealisticHandPreview({
    this.shape,
    this.nailLength = NailLength.medium,
    this.colorOption,
    this.nailColors = const <int, Color>{},
    this.nailProgress = const <int, double>{},
    this.pattern,
    this.sticker,
    this.ring,
    this.showSticker = true,
    this.showRing = true,
    this.showSparkles = false,
    this.skinTone = SkinTone.natural,
    this.padding = 0,
    this.brushPosition,
    this.brushColor = AppColors.pink,
    this.showBrush = false,
    this.onBrushMove,
    this.onBrushEnd,
    this.onNailSelected,
    this.onNailLongPress,
    super.key,
  });

  final NailShape? shape;
  final NailLength nailLength;
  final NailColorOption? colorOption;

  /// Per-nail colour and coverage for the interactive studio.
  final Map<int, Color> nailColors;
  final Map<int, double> nailProgress;

  final NailPattern? pattern;
  final DecorItem? sticker;
  final DecorItem? ring;
  final bool showSticker;
  final bool showRing;
  final bool showSparkles;
  final SkinTone skinTone;
  final double padding;

  /// Local coordinates in the image stack. The brush is only a visual cursor;
  /// the actual paint is applied by [onBrushMove].
  final Offset? brushPosition;
  final Color brushColor;
  final bool showBrush;
  final ValueChanged<NailBrushEvent>? onBrushMove;
  final VoidCallback? onBrushEnd;
  final ValueChanged<int>? onNailSelected;
  final ValueChanged<int>? onNailLongPress;

  static const double _imageAspect = 887 / 1774;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 320.0;
        final double maxHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : maxWidth / _imageAspect;
        final double availableWidth =
            math.max(1.0, maxWidth - padding * 2).toDouble();
        final double availableHeight =
            math.max(1.0, maxHeight - padding * 2).toDouble();
        final double width = math.max(
          1.0,
          math.min(availableWidth, availableHeight * _imageAspect),
        ).toDouble();
        final double height = width / _imageAspect;

        final Widget art = SizedBox(
          width: width,
          height: height,
          child: _InteractiveHandStack(
            width: width,
            height: height,
            shape: shape ?? NailShape.round,
            nailLength: nailLength,
            colorOption: colorOption,
            nailColors: nailColors,
            nailProgress: nailProgress,
            pattern: pattern,
            sticker: sticker,
            ring: ring,
            showSticker: showSticker,
            showRing: showRing,
            showSparkles: showSparkles,
            skinTone: skinTone,
            brushPosition: brushPosition,
            brushColor: brushColor,
            showBrush: showBrush,
            onBrushMove: onBrushMove,
            onBrushEnd: onBrushEnd,
            onNailSelected: onNailSelected,
            onNailLongPress: onNailLongPress,
          ),
        );

        return Center(
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: art,
          ),
        );
      },
    );
  }
}

class _InteractiveHandStack extends StatefulWidget {
  const _InteractiveHandStack({
    required this.width,
    required this.height,
    required this.shape,
    required this.nailLength,
    required this.colorOption,
    required this.nailColors,
    required this.nailProgress,
    required this.pattern,
    required this.sticker,
    required this.ring,
    required this.showSticker,
    required this.showRing,
    required this.showSparkles,
    required this.skinTone,
    required this.brushPosition,
    required this.brushColor,
    required this.showBrush,
    required this.onBrushMove,
    required this.onBrushEnd,
    required this.onNailSelected,
    required this.onNailLongPress,
  });

  final double width;
  final double height;
  final NailShape shape;
  final NailLength nailLength;
  final NailColorOption? colorOption;
  final Map<int, Color> nailColors;
  final Map<int, double> nailProgress;
  final NailPattern? pattern;
  final DecorItem? sticker;
  final DecorItem? ring;
  final bool showSticker;
  final bool showRing;
  final bool showSparkles;
  final SkinTone skinTone;
  final Offset? brushPosition;
  final Color brushColor;
  final bool showBrush;
  final ValueChanged<NailBrushEvent>? onBrushMove;
  final VoidCallback? onBrushEnd;
  final ValueChanged<int>? onNailSelected;
  final ValueChanged<int>? onNailLongPress;

  @override
  State<_InteractiveHandStack> createState() => _InteractiveHandStackState();
}

class _InteractiveHandStackState extends State<_InteractiveHandStack> {
  Offset? _lastPoint;

  @override
  Widget build(BuildContext context) {
    Widget child = Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned.fill(child: _HandImage(skinTone: widget.skinTone)),
        Positioned.fill(
          child: CustomPaint(
            painter: _RealisticNailPainter(
              shape: widget.shape,
              nailLength: widget.nailLength,
              colorOption: widget.colorOption,
              nailColors: widget.nailColors,
              nailProgress: widget.nailProgress,
              pattern: widget.pattern,
            ),
          ),
        ),
        if (widget.showSticker && widget.sticker != null)
          _StickerOnNail(item: widget.sticker!),
        if (widget.showRing && widget.ring != null)
          const _RingOnHand(),
        if (widget.showSparkles)
          const Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _HandSparklePainter()))),
        if (widget.showBrush && widget.brushPosition != null)
          Positioned(
            left: widget.brushPosition!.dx - 44,
            top: widget.brushPosition!.dy - 22,
            child: IgnorePointer(
              child: Transform.rotate(
                angle: -0.35,
                child: PolishBrushVisual(polishColor: widget.brushColor),
              ),
            ),
          ),
      ],
    );

    if (widget.onBrushMove != null || widget.onNailSelected != null) {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (DragStartDetails details) {
          _lastPoint = details.localPosition;
          _notifySelection(details.localPosition);
        },
        onPanUpdate: (DragUpdateDetails details) {
          final Offset current = details.localPosition;
          final Offset previous = _lastPoint ?? current;
          _lastPoint = current;
          final int? nail = _nailAt(current);
          widget.onBrushMove?.call(
            NailBrushEvent(
              nailIndex: nail,
              position: current,
              distance: (current - previous).distance,
            ),
          );
          if (nail != null) widget.onNailSelected?.call(nail);
        },
        onPanEnd: (_) {
          _lastPoint = null;
          widget.onBrushEnd?.call();
        },
        onPanCancel: () {
          _lastPoint = null;
          widget.onBrushEnd?.call();
        },
        onLongPressStart: (LongPressStartDetails details) {
          final int? nail = _nailAt(details.localPosition);
          if (nail != null) widget.onNailLongPress?.call(nail);
        },
        child: child,
      );
    }

    return child;
  }

  void _notifySelection(Offset point) {
    final int? nail = _nailAt(point);
    if (nail != null) widget.onNailSelected?.call(nail);
  }

  int? _nailAt(Offset point) {
    final Offset normalized = Offset(
      point.dx / widget.width,
      point.dy / widget.height,
    );
    for (int i = 0; i < realisticNailRegions.length; i++) {
      if (realisticNailRegions[i].inflate(0.026).contains(normalized)) {
        return i;
      }
    }
    return null;
  }
}

class _HandImage extends StatelessWidget {
  const _HandImage({required this.skinTone});

  final SkinTone skinTone;

  @override
  Widget build(BuildContext context) {
    final Widget image = Image.asset(
      Assets.realisticHand,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Realistic hand with natural nails',
      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) =>
          const SizedBox.expand(),
    );

    if (skinTone == SkinTone.natural) return image;
    return ColorFiltered(
      colorFilter: ColorFilter.mode(skinTone.filter, BlendMode.modulate),
      child: image,
    );
  }
}

class _RealisticNailPainter extends CustomPainter {
  _RealisticNailPainter({
    required this.shape,
    required this.nailLength,
    required this.colorOption,
    required this.nailColors,
    required this.nailProgress,
    required this.pattern,
  });

  final NailShape shape;
  final NailLength nailLength;
  final NailColorOption? colorOption;
  final Map<int, Color> nailColors;
  final Map<int, double> nailProgress;
  final NailPattern? pattern;

  @override
  void paint(Canvas canvas, Size size) {
    for (int index = 0; index < realisticNailRegions.length; index++) {
      final Color? color = nailColors[index] ?? colorOption?.color;
      if (color == null) continue;
      final double progress =
          (nailProgress[index] ?? (nailColors.containsKey(index) ? 1.0 : 1.0))
              .clamp(0.0, 1.0)
              .toDouble();
      if (progress <= 0.001) continue;
      _paintNail(canvas, size, index, color, progress);
    }
  }

  void _paintNail(
    Canvas canvas,
    Size size,
    int index,
    Color color,
    double coverage,
  ) {
    final Rect normalized = realisticNailRegions[index];
    final double baseHeight = normalized.height * size.height;
    final double paintedHeight = baseHeight * nailLength.factor;
    final double top = normalized.top * size.height -
        (paintedHeight - baseHeight) * 0.58;
    final Rect rect = Rect.fromLTWH(
      normalized.left * size.width,
      top,
      normalized.width * size.width,
      paintedHeight,
    );

    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    if (index == 4) canvas.rotate(-0.48);
    final Rect local = Rect.fromCenter(
      center: Offset.zero,
      width: rect.width,
      height: rect.height,
    );
    final Path path = _nailPath(local, shape);

    final Color highlight = Color.lerp(color, Colors.white, 0.38)!
        .withValues(alpha: 0.94 * coverage);
    final Color shade = Color.lerp(color, Colors.black, 0.10)!
        .withValues(alpha: 0.94 * coverage);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[highlight, shade],
        ).createShader(local),
    );

    canvas.save();
    canvas.clipPath(path);
    if (pattern != null && coverage > 0.10) {
      _paintPattern(canvas, local, pattern!.id, coverage);
    }
    if (coverage > 0.45) {
      final Paint wetHighlight = Paint()
        ..color = Colors.white.withValues(alpha: 0.34 * coverage)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(1.0, local.width * 0.12).toDouble();
      canvas.drawLine(
        Offset(local.left + local.width * 0.28, local.top + local.height * 0.25),
        Offset(local.left + local.width * 0.44, local.top + local.height * 0.55),
        wetHighlight,
      );
    }
    canvas.restore();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.54)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, local.width * 0.035).toDouble(),
    );
    canvas.restore();
  }

  Path _nailPath(Rect rect, NailShape value) {
    final double left = rect.left;
    final double right = rect.right;
    final double top = rect.top;
    final double bottom = rect.bottom;
    final double center = rect.center.dx;

    return switch (value) {
      NailShape.almond => Path()
        ..moveTo(center, top)
        ..cubicTo(right * 0.96, top + rect.height * 0.20, right * 0.90,
            bottom - rect.height * 0.16, center, bottom)
        ..cubicTo(left + rect.width * 0.10, bottom - rect.height * 0.16,
            left + rect.width * 0.04, top + rect.height * 0.20, center, top)
        ..close(),
      NailShape.square => Path()
        ..moveTo(left + rect.width * 0.18, top)
        ..lineTo(right - rect.width * 0.18, top)
        ..cubicTo(right - rect.width * 0.06, top, right, top + rect.height * 0.12,
            right, top + rect.height * 0.22)
        ..lineTo(right, bottom - rect.height * 0.20)
        ..quadraticBezierTo(right, bottom, right - rect.width * 0.18, bottom)
        ..lineTo(left + rect.width * 0.18, bottom)
        ..quadraticBezierTo(left, bottom, left, bottom - rect.height * 0.20)
        ..lineTo(left, top + rect.height * 0.22)
        ..cubicTo(left, top + rect.height * 0.12, left + rect.width * 0.06, top,
            left + rect.width * 0.18, top)
        ..close(),
      NailShape.round => Path()
        ..moveTo(center, top)
        ..cubicTo(right - rect.width * 0.04, top, right, top + rect.height * 0.22,
            right, top + rect.height * 0.38)
        ..lineTo(right, bottom - rect.height * 0.20)
        ..quadraticBezierTo(right, bottom, center, bottom)
        ..quadraticBezierTo(left, bottom, left, bottom - rect.height * 0.20)
        ..lineTo(left, top + rect.height * 0.38)
        ..cubicTo(left, top + rect.height * 0.22, left + rect.width * 0.04, top,
            center, top)
        ..close(),
    };
  }

  void _paintPattern(Canvas canvas, Rect rect, String id, double opacity) {
    final Paint paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.62 * opacity)
      ..strokeCap = StrokeCap.round;
    switch (id) {
      case 'glitter':
        final math.Random random = math.Random(17 + rect.width.round());
        for (int i = 0; i < 9; i++) {
          final Offset point = Offset(
            rect.left + random.nextDouble() * rect.width,
            rect.top + random.nextDouble() * rect.height,
          );
          canvas.drawCircle(point, rect.width * 0.045, paint);
        }
      case 'stripes':
        paint.strokeWidth = rect.width * 0.10;
        for (double y = rect.top - rect.height;
            y < rect.bottom + rect.height;
            y += rect.height * 0.30) {
          canvas.drawLine(
            Offset(rect.left - rect.width, y),
            Offset(rect.right + rect.width, y + rect.height * 0.40),
            paint,
          );
        }
      case 'stars':
        for (final Offset point in <Offset>[
          Offset(rect.left + rect.width * 0.30, rect.top + rect.height * 0.28),
          Offset(rect.left + rect.width * 0.68, rect.top + rect.height * 0.66),
        ]) {
          final double radius = rect.width * 0.15;
          canvas.drawLine(point.translate(-radius, 0), point.translate(radius, 0), paint);
          canvas.drawLine(point.translate(0, -radius), point.translate(0, radius), paint);
        }
      case 'rainbow':
        final List<Color> colours = <Color>[
          AppColors.pink,
          AppColors.yellow,
          AppColors.mint,
          AppColors.sky,
        ];
        final double band = rect.height / colours.length;
        for (int i = 0; i < colours.length; i++) {
          canvas.drawRect(
            Rect.fromLTWH(rect.left, rect.top + band * i, rect.width, band),
            Paint()..color = colours[i].withValues(alpha: 0.68 * opacity),
          );
        }
      case 'french':
        canvas.drawPath(
          Path()
            ..moveTo(rect.left, rect.top + rect.height * 0.18)
            ..quadraticBezierTo(rect.center.dx, rect.top + rect.height * 0.34,
                rect.right, rect.top + rect.height * 0.18)
            ..lineTo(rect.right, rect.top)
            ..lineTo(rect.left, rect.top)
            ..close(),
          Paint()..color = Colors.white.withValues(alpha: 0.88 * opacity),
        );
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(_RealisticNailPainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.nailLength != nailLength ||
      oldDelegate.colorOption != colorOption ||
      oldDelegate.pattern != pattern ||
      oldDelegate.nailColors != nailColors ||
      oldDelegate.nailProgress != nailProgress;
}

class _StickerOnNail extends StatelessWidget {
  const _StickerOnNail({required this.item});

  final DecorItem item;

  @override
  Widget build(BuildContext context) {
    final Rect region = realisticNailRegions[2];
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // This widget is laid out in a Stack with tight constraints. Using
          // alignment keeps the sticker attached to the middle nail as the
          // photographic hand scales on phones and tablets.
          return Align(
            alignment: Alignment(
              region.center.dx * 2 - 1,
              region.center.dy * 2 - 1,
            ),
            child: SizedBox(
              width: constraints.maxWidth * region.width * 0.78,
              height: constraints.maxHeight * region.height * 0.70,
              child: SafeAssetImage(
                asset: item.asset,
                fit: BoxFit.contain,
                fallbackIcon: _stickerIcon(item.id),
                fallbackColor: AppColors.pink,
                semanticLabel: item.label,
              ),
            ),
          );
        },
      ),
    );
  }

  static IconData _stickerIcon(String id) => switch (id) {
        'heart' => Icons.favorite_rounded,
        'flower' => Icons.local_florist_rounded,
        'candy' => Icons.icecream_rounded,
        'rainbow' => Icons.gradient_rounded,
        'sparkle' => Icons.auto_awesome_rounded,
        'cloud' => Icons.cloud_rounded,
        'moon' => Icons.dark_mode_rounded,
        'bow' => Icons.redeem_rounded,
        'gem' => Icons.hexagon_rounded,
        'butterfly' => Icons.filter_vintage,
        _ => Icons.star_rounded,
      };
}

/// A tiny gold charm used on the real hand instead of a flat preview icon.
class _RingOnHand extends StatelessWidget {
  const _RingOnHand();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: IgnorePointer(child: CustomPaint(painter: _RingPainter())),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width * 0.418, size.height * 0.345);
    final double radius = size.width * 0.052;
    final Paint gold = Paint()
      ..color = const Color(0xFFFFD95A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, size.width * 0.014).toDouble();
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radius * 1.55, height: radius * 0.78),
      gold,
    );
    canvas.drawCircle(
      center.translate(0, -radius * 0.55),
      radius * 0.34,
      Paint()..color = AppColors.lavender,
    );
    canvas.drawCircle(
      center.translate(-radius * 0.10, -radius * 0.68),
      radius * 0.12,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => false;
}

class _HandSparklePainter extends CustomPainter {
  const _HandSparklePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.82)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.0, size.width * 0.010).toDouble();
    for (final Offset point in <Offset>[
      Offset(size.width * 0.16, size.height * 0.42),
      Offset(size.width * 0.76, size.height * 0.25),
      Offset(size.width * 0.70, size.height * 0.62),
    ]) {
      final double r = size.width * 0.025;
      canvas.drawLine(point.translate(-r, 0), point.translate(r, 0), paint);
      canvas.drawLine(point.translate(0, -r), point.translate(0, r), paint);
    }
  }

  @override
  bool shouldRepaint(_HandSparklePainter oldDelegate) => false;
}

/// The glass polish bottle and its brush. It is intentionally a live widget
/// rather than a flat icon: the colour, open cap and glass highlight change as
/// the child paints.
class PolishBottleVisual extends StatelessWidget {
  const PolishBottleVisual({
    required this.color,
    this.open = false,
    this.size = 112,
    super.key,
  });

  final Color color;
  final bool open;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.28,
      child: CustomPaint(
        painter: _PolishBottlePainter(color: color, open: open),
      ),
    );
  }
}

class _PolishBottlePainter extends CustomPainter {
  _PolishBottlePainter({required this.color, required this.open});

  final Color color;
  final bool open;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Rect body = Rect.fromLTWH(w * 0.14, h * 0.32, w * 0.72, h * 0.58);
    final RRect bottle = RRect.fromRectAndRadius(body, Radius.circular(w * 0.16));

    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.94), width: w * 0.78, height: h * 0.10),
      Paint()..color = Colors.black.withValues(alpha: 0.14),
    );
    canvas.drawRRect(
      bottle,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.86),
            color.withValues(alpha: 0.82),
            Color.lerp(color, Colors.black, 0.18)!.withValues(alpha: 0.92),
          ],
        ).createShader(body),
    );
    canvas.drawRRect(
      bottle,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.62)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.025,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.25, h * 0.37, w * 0.18, h * 0.40),
        Radius.circular(w * 0.07),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.38),
    );

    final Rect neck = Rect.fromLTWH(w * 0.34, h * 0.19, w * 0.32, h * 0.19);
    canvas.drawRRect(
      RRect.fromRectAndRadius(neck, Radius.circular(w * 0.04)),
      Paint()..color = Colors.white.withValues(alpha: 0.82),
    );
    final Rect cap = Rect.fromLTWH(w * 0.29, open ? h * 0.04 : h * 0.14, w * 0.42, h * 0.13);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cap, Radius.circular(w * 0.035)),
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            Color.lerp(color, Colors.white, 0.35)!,
            Color.lerp(color, Colors.black, 0.24)!,
          ],
        ).createShader(cap),
    );
    if (open) {
      final Paint brush = Paint()
        ..color = const Color(0xFFE9D0B8)
        ..strokeWidth = w * 0.027
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(w * 0.50, h * 0.18), Offset(w * 0.50, h * 0.01), brush);
      canvas.drawLine(
        Offset(w * 0.45, h * 0.01),
        Offset(w * 0.55, h * 0.01),
        Paint()
          ..color = color
          ..strokeWidth = w * 0.065
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_PolishBottlePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.open != open;
}

/// A realistic-looking moving brush cursor used while dragging over a nail.
class PolishBrushVisual extends StatelessWidget {
  const PolishBrushVisual({
    this.polishColor = AppColors.pink,
    this.size = 88,
    super.key,
  });

  final Color polishColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.48,
      child: CustomPaint(painter: _PolishBrushPainter(polishColor)),
    );
  }
}

class _PolishBrushPainter extends CustomPainter {
  _PolishBrushPainter(this.polishColor);

  final Color polishColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double h = size.height;
    final Paint handle = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFFFFFFFF), Color(0xFFCDB8E4)],
      ).createShader(Offset.zero & size);
    final Path handlePath = Path()
      ..moveTo(size.width * 0.18, h * 0.30)
      ..quadraticBezierTo(size.width * 0.42, h * 0.18, size.width * 0.80, h * 0.32)
      ..lineTo(size.width * 0.75, h * 0.68)
      ..quadraticBezierTo(size.width * 0.42, h * 0.78, size.width * 0.18, h * 0.62)
      ..close();
    canvas.drawPath(handlePath, handle);
    canvas.drawPath(
      handlePath,
      Paint()
        ..color = AppColors.lavender.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    final RRect bristles = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.02, h * 0.18, size.width * 0.28, h * 0.64),
      Radius.circular(h * 0.25),
    );
    canvas.drawRRect(
      bristles,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[
            Color.lerp(polishColor, Colors.white, 0.55)!,
            polishColor,
          ],
        ).createShader(bristles.outerRect),
    );
    canvas.drawRRect(
      bristles,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(_PolishBrushPainter oldDelegate) =>
      oldDelegate.polishColor != polishColor;
}
