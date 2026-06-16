import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:eunora/core/theme/app_theme.dart';

class SuccessAnimationWidget extends StatefulWidget {
  final IconData icon;
  final double size;

  const SuccessAnimationWidget({
    super.key,
    this.icon = Icons.auto_awesome,
    this.size = 112,
  });

  @override
  State<SuccessAnimationWidget> createState() => _SuccessAnimationWidgetState();
}

class _SuccessAnimationWidgetState extends State<SuccessAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _circleScale;
  late Animation<double> _iconScale;
  late Animation<double> _iconRotation;
  late Animation<double> _rippleScale1;
  late Animation<double> _rippleOpacity1;
  late Animation<double> _rippleScale2;
  late Animation<double> _rippleOpacity2;

  // Particle positions/colors for the burst effect
  final List<_SparkleParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Main circle scale-up with elastic bounce
    _circleScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
      ),
    );

    // Icon scale-up with overshoot
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // Icon subtle rotation
    _iconRotation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutBack),
      ),
    );

    // Ripple 1
    _rippleScale1 = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    _rippleOpacity1 = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
      ),
    );

    // Ripple 2 (slightly delayed)
    _rippleScale2 = Tween<double>(begin: 1.0, end: 2.6).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _rippleOpacity2 = Tween<double>(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
      ),
    );

    // Generate random particles
    final random = math.Random();
    final colors = [
      AppTheme.primary,
      const Color(0xFF8EB8B5), // Sage
      const Color(0xFFD6A2E8), // Pastel Purple
      const Color(0xFFF1C40F), // Gold/Amber
      const Color(0xFFE74C3C), // Coral
    ];

    for (int i = 0; i < 16; i++) {
      final angle = (i * 22.5) * math.pi / 180.0 + (random.nextDouble() * 0.2 - 0.1);
      final distance = 60.0 + random.nextDouble() * 50.0;
      final particleSize = 6.0 + random.nextDouble() * 8.0;
      _particles.add(
        _SparkleParticle(
          angle: angle,
          distance: distance,
          size: particleSize,
          color: colors[random.nextInt(colors.length)],
          isStar: random.nextBool(),
        ),
      );
    }

    // Trigger animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Ripple 2
            if (_controller.value > 0.45)
              Transform.scale(
                scale: _rippleScale2.value,
                child: Opacity(
                  opacity: _rippleOpacity2.value,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primary.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

            // Ripple 1
            if (_controller.value > 0.35)
              Transform.scale(
                scale: _rippleScale1.value,
                child: Opacity(
                  opacity: _rippleOpacity1.value,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primary.withOpacity(0.4),
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
              ),

            // Main Circle Background
            Transform.scale(
              scale: _circleScale.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Transform.rotate(
                    angle: _iconRotation.value * 2 * math.pi,
                    child: Transform.scale(
                      scale: _iconScale.value,
                      child: Icon(
                        widget.icon,
                        color: AppTheme.primary,
                        size: widget.size * 0.43, // around 48 for 112 size
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Sparkle Particle Burst
            if (_controller.value > 0.3)
              ..._particles.map((particle) {
                // Progress of the burst (0.0 to 1.0)
                final burstProgress = math.min(
                  1.0,
                  math.max(0.0, (_controller.value - 0.3) / 0.7),
                );

                // Curve for movement
                final moveCurve = Curves.easeOutCubic.transform(burstProgress);
                // Curve for fading out/scaling down
                final fadeCurve = Curves.easeIn.transform(burstProgress);

                final currentDistance = particle.distance * moveCurve;
                final currentOpacity = 1.0 - fadeCurve;
                final currentScale = 1.0 - (fadeCurve * 0.8);

                final dx = currentDistance * math.cos(particle.angle);
                final dy = currentDistance * math.sin(particle.angle);

                return Positioned(
                  left: (widget.size / 2) + dx - (particle.size / 2),
                  top: (widget.size / 2) + dy - (particle.size / 2),
                  child: Opacity(
                    opacity: currentOpacity,
                    child: Transform.scale(
                      scale: currentScale,
                      child: particle.isStar
                          ? Icon(
                              Icons.star_rounded,
                              color: particle.color,
                              size: particle.size,
                            )
                          : Container(
                              width: particle.size,
                              height: particle.size,
                              decoration: BoxDecoration(
                                color: particle.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

class _SparkleParticle {
  final double angle;
  final double distance;
  final double size;
  final Color color;
  final bool isStar;

  _SparkleParticle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
    required this.isStar,
  });
}
