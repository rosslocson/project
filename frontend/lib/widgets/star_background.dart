import 'dart:math' as math;
import 'package:flutter/material.dart';

// ── Star model ────────────────────────────────────────────────────────────────
class Star {
  final double x;
  final double y;
  final double size;
  final double baseOpacity;
  final double speed;
  final double twinklePhase;

  const Star({
    required this.x,
    required this.y,
    required this.size,
    required this.baseOpacity,
    required this.speed,
    required this.twinklePhase,
  });
}

List<Star> generateStars({int count = 200}) {
  final rng = math.Random();
  return List.generate(
    count,
    (_) => Star(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      size: rng.nextDouble() * 2.0 + 0.5,
      baseOpacity: rng.nextDouble() * 0.7 + 0.3,
      speed: rng.nextDouble() * 0.5 + 0.1,
      twinklePhase: rng.nextDouble() * 2 * math.pi,
    ),
  );
}

// ── Painter ───────────────────────────────────────────────────────────────────
class StarfieldPainter extends CustomPainter {
  final double animationValue;
  final List<Star> stars;

  const StarfieldPainter({
    required this.animationValue,
    required this.stars,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final star in stars) {
      final twinkle =
          (math.sin((animationValue * 2 * math.pi * 5) + star.twinklePhase) +
                  1.0) /
              2.0;
      final opacity =
          (star.baseOpacity * (0.3 + 0.7 * twinkle)).clamp(0.0, 1.0);
      paint.color = Colors.white.withValues(alpha: opacity);

      final dx =
          (star.x * size.width + animationValue * size.width * star.speed) %
              size.width;
      final dy = star.y * size.height;

      if (star.size > 1.5) {
        canvas.drawCircle(
          Offset(dx, dy),
          star.size * 2,
          Paint()
            ..color = Colors.white.withValues(alpha: opacity * 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
        );
      }
      canvas.drawCircle(Offset(dx, dy), star.size, paint);
    }
  }

  @override
  bool shouldRepaint(StarfieldPainter old) =>
      old.animationValue != animationValue;
}

// ── Reusable animated galaxy background widget ────────────────────────────────
class GalaxyBackground extends StatelessWidget {
  final Animation<double> animation;
  final List<Star> stars;

  const GalaxyBackground({
    super.key,
    required this.animation,
    required this.stars,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.3, -0.2),
          radius: 1.5,
          colors: [
            Color(0xFF3A0812),
            Color(0xFF140306),
            Color(0xFF050505),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, __) => CustomPaint(
          painter: StarfieldPainter(
            animationValue: animation.value,
            stars: stars,
          ),
        ),
      ),
    );
  }
}

// ── Left-panel content (shared between login & register) ──────────────────────
class GalaxyLeftPanel extends StatelessWidget {
  final String headline;
  final String subheadline;

  const GalaxyLeftPanel({
    super.key,
    required this.headline,
    required this.subheadline,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(64.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            headline,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            subheadline,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 18,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Blend gradient mask (fades galaxy into white form panel) ─────────────────
class GalaxyBlendMask extends StatelessWidget {
  const GalaxyBlendMask({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.0),
            Colors.white,
            Colors.white,
          ],
          stops: const [0.0, 0.35, 0.50, 1.0],
        ),
      ),
    );
  }
}