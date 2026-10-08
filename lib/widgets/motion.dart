import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../features/game/game_providers.dart';

/// Keeps a widget subtly alive (breathing). Respects "reduce motion".
class IdleBreathe extends ConsumerStatefulWidget {
  const IdleBreathe({
    required this.child,
    this.scale = 1.03,
    this.duration = const Duration(milliseconds: 2200),
    super.key,
  });

  final Widget child;
  final double scale;
  final Duration duration;

  @override
  ConsumerState<IdleBreathe> createState() => _IdleBreatheState();
}

class _IdleBreatheState extends ConsumerState<IdleBreathe>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        ref.watch(settingsControllerProvider.select((s) => s.reduceMotion));

    if (reduceMotion) return widget.child;

    return ScaleTransition(
      scale: Tween<double>(begin: 1, end: widget.scale).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}

/// Gentle sparkles that twinkle over any background.
/// Purely procedural — no asset or Lottie file required.
class SparkleBurst extends StatefulWidget {
  const SparkleBurst({
    this.count = 18,
    this.opacity = 0.8,
    this.colors = AppColors.rainbow,
    this.seed = 7,
    super.key,
  });

  final int count;
  final double opacity;
  final List<Color> colors;
  final int seed;

  @override
  State<SparkleBurst> createState() => _SparkleBurstState();
}

class _SparkleBurstState extends ConsumerState<SparkleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  late final List<_Sparkle> _sparkles = _buildSparkles();

  List<_Sparkle> _buildSparkles() {
    final math.Random random = math.Random(widget.seed);
    return List<_Sparkle>.generate(widget.count, (int index) {
      return _Sparkle(
        dx: random.nextDouble(),
        dy: random.nextDouble(),
        size: 6 + random.nextDouble() * 12,
        phase: random.nextDouble(),
        speed: 0.6 + random.nextDouble() * 0.8,
        color: widget.colors[index % widget.colors.length],
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        ref.watch(settingsControllerProvider.select((s) => s.reduceMotion));
    if (reduceMotion) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          painter: _SparklePainter(
            sparkles: _sparkles,
            time: _controller.value,
            opacity: widget.opacity,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Sparkle {
  const _Sparkle({
    required this.dx,
    required this.dy,
    required this.size,
    required this.phase,
    required this.speed,
    required this.color,
  });

  final double dx;
  final double dy;
  final double size;
  final double phase;
  final double speed;
  final Color color;
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter({
    required this.sparkles,
    required this.time,
    required this.opacity,
  });

  final List<_Sparkle> sparkles;
  final double time;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    for (final _Sparkle sparkle in sparkles) {
      final double t = ((time * sparkle.speed) + sparkle.phase) % 1;
      final double wave = math.sin(t * math.pi);
      final double alpha = (wave * opacity).clamp(0.0, 1.0);
      if (alpha <= 0.02) continue;

      final Offset center = Offset(
        sparkle.dx * size.width,
        sparkle.dy * size.height,
      );
      final double radius = sparkle.size * (0.5 + wave * 0.5);
      _drawStar(canvas, center, radius, sparkle.color.withValues(alpha: alpha));
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final Paint paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (radius * 0.30).clamp(1.0, 3.5);

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
    canvas.drawCircle(center, radius * 0.22, Paint()..color = AppColors.white);
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.opacity != opacity;
}

/// A friendly "drag here" hint: a soft ring that travels side to side with a
/// touch icon. No text — the child understands it instantly.
class HintHand extends StatefulWidget {
  const HintHand({this.size = 76, super.key});

  final double size;

  @override
  ConsumerState<HintHand> createState() => _HintHandState();
}

class _HintHandState extends ConsumerState<HintHand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        ref.watch(settingsControllerProvider.select((s) => s.reduceMotion));

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double t = reduceMotion ? 0.5 : _controller.value;
          return Transform.translate(
            offset: Offset((t - 0.5) * widget.size * 1.6, 0),
            child: Opacity(
              opacity: 0.65 + 0.35 * math.sin(t * math.pi),
              child: child,
            ),
          );
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.white.withValues(alpha: 0.75),
            border: Border.all(color: AppColors.white, width: 3),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.touch_app_rounded,
            size: widget.size * 0.55,
            color: AppColors.pink,
          ),
        ),
      ),
    );
  }
}

/// Protects little players: the system back button can never drop them into
/// an unexpected place. Each screen decides what "back" should do.
class KidPopScope extends StatelessWidget {
  const KidPopScope({required this.child, this.onBack, super.key});

  final Widget child;

  /// `null` means "back does nothing here" (the screen has its own big buttons).
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        onBack?.call();
      },
      child: child,
    );
  }
}

/// Convenience: "back" that always lands on Home.
void goHome(BuildContext context) => context.go(AppRoutes.home);
