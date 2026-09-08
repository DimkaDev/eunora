import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// An animated circular icon container that plays a 2.5-second contextual micro-animation
/// whenever a symptom or trigger's severity or counter changes (or when tapped).
class AnimatedLoggingIcon extends StatefulWidget {
  final String name;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final dynamic triggerValue;
  final double size;
  final double iconSize;

  const AnimatedLoggingIcon({
    super.key,
    required this.name,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    this.triggerValue,
    this.size = 44.0,
    this.iconSize = 22.0,
  });

  @override
  State<AnimatedLoggingIcon> createState() => _AnimatedLoggingIconState();
}

class _AnimatedLoggingIconState extends State<AnimatedLoggingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedLoggingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.triggerValue != null &&
        oldWidget.triggerValue != null &&
        widget.triggerValue != oldWidget.triggerValue) {
      _playAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _playAnimation() {
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final lowerName = widget.name.toLowerCase();

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _playAnimation();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          final isPlaying = _controller.isAnimating;

          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // 1. Halo ripple expanding pulse during animation
                if (isPlaying)
                  Positioned.fill(
                    child: Transform.scale(
                      scale: 1.0 + (math.sin(progress * math.pi * 3).abs() * 0.2),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.color.withValues(
                            alpha: 0.15 * (1.0 - progress),
                          ),
                        ),
                      ),
                    ),
                  ),

                // 2. Base circular container with scale bounce
                Transform.scale(
                  scale: isPlaying
                      ? 1.0 + (math.sin(progress * math.pi * 4) * 0.08)
                      : 1.0,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: widget.backgroundColor,
                      shape: BoxShape.circle,
                      boxShadow: isPlaying
                          ? [
                              BoxShadow(
                                color: widget.color.withValues(alpha: 0.25),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: _buildAnimatedContent(lowerName, progress),
                  ),
                ),

                // 3. Floating particles / Steam / Zzz / Sparks
                if (isPlaying)
                  ..._buildFloatingParticles(lowerName, progress),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds context-specific icon animations based on the symptom/trigger type.
  Widget _buildAnimatedContent(String lowerName, double progress) {
    // 1. Exercise / Workout / Walking / Running
    if (lowerName.contains('exercise') ||
        lowerName.contains('walk') ||
        lowerName.contains('run') ||
        lowerName.contains('workout') ||
        lowerName.contains('fitness') ||
        lowerName.contains('training')) {
      return _buildExerciseAnimation(progress);
    }

    // 2. Caffeine / Coffee / Tea / Hot drinks
    if (lowerName.contains('caffeine') ||
        lowerName.contains('coffee') ||
        lowerName.contains('tea')) {
      return _buildCaffeineAnimation(progress);
    }

    // 3. Hot Flashes / Night Sweats / Heat
    if (lowerName.contains('hot flash') ||
        lowerName.contains('night sweat') ||
        lowerName.contains('sweat') ||
        lowerName.contains('flashes')) {
      return _buildHeatAnimation(progress);
    }

    // 4. Sleep / Insomnia / Fatigue / Tiredness
    if (lowerName.contains('sleep') ||
        lowerName.contains('insomnia') ||
        lowerName.contains('fatigue') ||
        lowerName.contains('tired')) {
      return _buildSleepAnimation(progress);
    }

    // 5. Stress / Anxiety / Mood / Brain Fog / Headache
    if (lowerName.contains('stress') ||
        lowerName.contains('anxiety') ||
        lowerName.contains('mood') ||
        lowerName.contains('brain') ||
        lowerName.contains('headache') ||
        lowerName.contains('migraine')) {
      return _buildStressAnimation(progress);
    }

    // 6. Alcohol / Wine / Drinks
    if (lowerName.contains('alcohol') ||
        lowerName.contains('wine') ||
        lowerName.contains('beer') ||
        lowerName.contains('drink')) {
      return _buildAlcoholAnimation(progress);
    }

    // 7. Smoking / Tobacco
    if (lowerName.contains('smoking') || lowerName.contains('tobacco')) {
      return _buildSmokingAnimation(progress);
    }

    // Default: Dynamic spring bounce & celebration shimmer
    return _buildDefaultAnimation(progress);
  }

  /// Exercise: Walker -> Barbell lift -> Runner sequence
  Widget _buildExerciseAnimation(double p) {
    IconData currentIcon;
    double dy = 0.0;
    double dx = 0.0;
    double rotation = 0.0;
    double scale = 1.0;

    if (p < 0.35) {
      // Walk & Run Phase (0.0 - 0.35)
      final subP = p / 0.35;
      currentIcon = subP < 0.5 ? Icons.directions_walk : Icons.directions_run;
      // Bouncing walking steps and forward tilt
      dy = -math.sin(subP * math.pi * 4).abs() * 4.0;
      dx = math.sin(subP * math.pi * 2) * 2.5;
      rotation = (subP < 0.5 ? 0.08 : 0.15);
      scale = 1.0 + (math.sin(subP * math.pi * 4) * 0.08);
    } else if (p < 0.75) {
      // Barbell Lifting Phase (0.35 - 0.75)
      final subP = (p - 0.35) / 0.40;
      currentIcon = Icons.fitness_center;
      // Raising barbell up and down 2 cycles
      final liftCycle = math.sin(subP * math.pi * 4);
      dy = -liftCycle * 5.0; // Up and down
      rotation = math.sin(subP * math.pi * 2) * 0.12;
      scale = 1.0 + (liftCycle.clamp(0.0, 1.0) * 0.18);
    } else {
      // Sprint Finish Phase (0.75 - 1.0)
      final subP = (p - 0.75) / 0.25;
      currentIcon = Icons.directions_run;
      dy = -math.sin(subP * math.pi * 4).abs() * 3.0;
      dx = math.sin(subP * math.pi * 3) * 2.0;
      rotation = 0.12 * (1.0 - subP);
      scale = 1.0 + (math.sin(subP * math.pi) * 0.12);
    }

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: rotation,
        child: Transform.scale(
          scale: scale,
          child: Icon(currentIcon, color: widget.color, size: widget.iconSize),
        ),
      ),
    );
  }

  /// Caffeine: Cup bobbing and steam swirl
  Widget _buildCaffeineAnimation(double p) {
    final bob = math.sin(p * math.pi * 6) * 2.0;
    final tilt = math.sin(p * math.pi * 4) * 0.08;
    return Transform.translate(
      offset: Offset(0, bob),
      child: Transform.rotate(
        angle: tilt,
        child: Icon(widget.icon, color: widget.color, size: widget.iconSize),
      ),
    );
  }

  /// Heat/Hot Flashes: Fire pulsing with flare
  Widget _buildHeatAnimation(double p) {
    final scale = 1.0 + (math.sin(p * math.pi * 6).abs() * 0.25);
    final wave = math.sin(p * math.pi * 8) * 0.06;
    final icon = (p > 0.2 && p < 0.8) ? Icons.whatshot : widget.icon;
    return Transform.rotate(
      angle: wave,
      child: Transform.scale(
        scale: scale,
        child: Icon(icon, color: widget.color, size: widget.iconSize),
      ),
    );
  }

  /// Sleep: Moon rocking gently
  Widget _buildSleepAnimation(double p) {
    final rock = math.sin(p * math.pi * 4) * 0.22;
    final scale = 1.0 + (math.sin(p * math.pi * 2) * 0.1);
    return Transform.rotate(
      angle: rock,
      child: Transform.scale(
        scale: scale,
        child: Icon(widget.icon, color: widget.color, size: widget.iconSize),
      ),
    );
  }

  /// Stress/Mood: Brain/Heart pulse wave
  Widget _buildStressAnimation(double p) {
    final pulse = math.sin(p * math.pi * 8).abs();
    final scale = 1.0 + (pulse * 0.22);
    return Transform.scale(
      scale: scale,
      child: Icon(widget.icon, color: widget.color, size: widget.iconSize),
    );
  }

  /// Alcohol: Glass toast / swirl
  Widget _buildAlcoholAnimation(double p) {
    final tilt = math.sin(p * math.pi * 6) * 0.25;
    final dy = -math.sin(p * math.pi * 3).abs() * 3.0;
    return Transform.translate(
      offset: Offset(0, dy),
      child: Transform.rotate(
        angle: tilt,
        child: Icon(widget.icon, color: widget.color, size: widget.iconSize),
      ),
    );
  }

  /// Smoking: Gentle smoke drift
  Widget _buildSmokingAnimation(double p) {
    final dx = math.sin(p * math.pi * 4) * 2.0;
    return Transform.translate(
      offset: Offset(dx, 0),
      child: Icon(widget.icon, color: widget.color, size: widget.iconSize),
    );
  }

  /// Default: Spring bounce pop
  Widget _buildDefaultAnimation(double p) {
    final scale = 1.0 + (math.sin(p * math.pi * 4) * 0.15);
    final rot = math.sin(p * math.pi * 2) * 0.1;
    return Transform.rotate(
      angle: rot,
      child: Transform.scale(
        scale: scale,
        child: Icon(widget.icon, color: widget.color, size: widget.iconSize),
      ),
    );
  }

  /// Particle effects (rising steam, floating Zzz, sparkles, sweat drops)
  List<Widget> _buildFloatingParticles(String lowerName, double p) {
    // 1. Sleep: Floating 'z' characters
    if (lowerName.contains('sleep') || lowerName.contains('insomnia')) {
      return [
        _buildFloatingText(
          'z',
          Offset(8, -12 - (p * 20)),
          (1.0 - p).clamp(0.0, 1.0),
          11,
        ),
        _buildFloatingText(
          'Z',
          Offset(16, -18 - (p * 26)),
          (1.0 - (p * 0.9)).clamp(0.0, 1.0),
          14,
        ),
      ];
    }

    // 2. Caffeine: Rising steam lines
    if (lowerName.contains('caffeine') || lowerName.contains('coffee')) {
      final yOffset = -8.0 - (p * 18.0);
      final opacity = (1.0 - p).clamp(0.0, 1.0);
      return [
        Positioned(
          top: yOffset,
          left: 14 + (math.sin(p * math.pi * 4) * 3),
          child: Opacity(
            opacity: opacity,
            child: Icon(
              Icons.air,
              size: 14,
              color: widget.color.withValues(alpha: 0.7),
            ),
          ),
        ),
      ];
    }

    // 3. Hot flash / Heat: Rising heat wave
    if (lowerName.contains('hot flash') || lowerName.contains('sweat')) {
      final yOffset = -6.0 - (p * 16.0);
      final opacity = (1.0 - p).clamp(0.0, 1.0);
      return [
        Positioned(
          top: yOffset,
          right: 2,
          child: Opacity(
            opacity: opacity,
            child: Icon(
              Icons.blur_on,
              size: 14,
              color: widget.color.withValues(alpha: 0.8),
            ),
          ),
        ),
      ];
    }

    // 4. Exercise: Sparkle energy dots
    if (lowerName.contains('exercise') ||
        lowerName.contains('walk') ||
        lowerName.contains('run') ||
        lowerName.contains('workout')) {
      final opacity = math.sin(p * math.pi).clamp(0.0, 1.0);
      return [
        Positioned(
          top: -2,
          right: -2,
          child: Opacity(
            opacity: opacity,
            child: Icon(
              Icons.auto_awesome,
              size: 13,
              color: widget.color,
            ),
          ),
        ),
        Positioned(
          bottom: -2,
          left: -2,
          child: Opacity(
            opacity: opacity,
            child: Icon(
              Icons.flash_on,
              size: 12,
              color: widget.color.withValues(alpha: 0.8),
            ),
          ),
        ),
      ];
    }

    // 5. General / Alcohol: Sparkle star
    if (lowerName.contains('alcohol') || lowerName.contains('wine')) {
      final opacity = math.sin(p * math.pi).clamp(0.0, 1.0);
      return [
        Positioned(
          top: -4,
          right: 0,
          child: Opacity(
            opacity: opacity,
            child: Icon(
              Icons.auto_awesome,
              size: 14,
              color: widget.color,
            ),
          ),
        ),
      ];
    }

    return const [];
  }

  Widget _buildFloatingText(
    String text,
    Offset offset,
    double opacity,
    double fontSize,
  ) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Opacity(
        opacity: opacity,
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}
