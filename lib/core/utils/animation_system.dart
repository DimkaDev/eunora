import 'package:flutter/material.dart';
import 'package:eunora/core/theme/app_theme.dart';

/// A springy bounce-on-tap gesture wrapper that shrinks on press
/// and bounces back on release, respecting system reduced motion settings.
class Bounceable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final Duration duration;

  const Bounceable({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.96,
    this.duration = const Duration(milliseconds: 120),
  });

  @override
  State<Bounceable> createState() => _BounceableState();
}

class _BounceableState extends State<Bounceable> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutQuad,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse().then((_) {
        if (mounted) {
          widget.onTap!();
        }
      });
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.maybeOf(context)?.accessibleNavigation ?? false;

    if (reducedMotion || widget.onTap == null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: widget.child,
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// An entrance animation widget that fades and translates its child
/// from an offset to its final position, supporting stagger delays.
class FadeInEntrance extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset offset;

  const FadeInEntrance({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.offset = const Offset(0, 16),
  });

  @override
  State<FadeInEntrance> createState() => _FadeInEntranceState();
}

class _FadeInEntranceState extends State<FadeInEntrance> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.16, 1, 0.3, 1), // easeOutExpo
      ),
    );

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.maybeOf(context)?.accessibleNavigation ?? false;

    if (reducedMotion) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// A premium animated progress bar that transitions width shifts smoothly.
class AnimatedProgressBar extends StatelessWidget {
  final double progress;
  final double height;
  final Color? backgroundColor;
  final Color? progressColor;
  final Duration duration;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    this.height = 8.0,
    this.backgroundColor,
    this.progressColor,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    final resolvedBgColor = backgroundColor ?? Colors.white.withOpacity(0.5);
    final resolvedProgColor = progressColor ?? AppTheme.primary;
    final reducedMotion = MediaQuery.maybeOf(context)?.accessibleNavigation ?? false;

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: resolvedBgColor,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: progress),
        duration: reducedMotion ? Duration.zero : duration,
        curve: const Cubic(0.16, 1, 0.3, 1), // easeOutExpo
        builder: (context, value, child) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: resolvedProgColor,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A pulsing shimmer effect box suitable for skeleton screens.
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -1.5, end: 1.5).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.maybeOf(context)?.accessibleNavigation ?? false;

    if (reducedMotion) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1.0, -1.0),
              end: Alignment(_animation.value + 1.0, 1.0),
              colors: const [
                Color(0xFFF2EDEA), // AppTheme.surfaceContainer
                Color(0xFFE7E1DF), // AppTheme.surfaceContainerHighest
                Color(0xFFF2EDEA), // AppTheme.surfaceContainer
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A transition switcher that slides children left-to-right or right-to-left
/// depending on whether the index is increasing (forward) or decreasing (backward).
class DirectionalAnimatedSwitcher extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final Duration duration;

  const DirectionalAnimatedSwitcher({
    super.key,
    required this.child,
    required this.currentIndex,
    this.duration = const Duration(milliseconds: 350),
  });

  @override
  State<DirectionalAnimatedSwitcher> createState() => _DirectionalAnimatedSwitcherState();
}

class _DirectionalAnimatedSwitcherState extends State<DirectionalAnimatedSwitcher> {
  late int _prevIndex;

  @override
  void initState() {
    super.initState();
    _prevIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(covariant DirectionalAnimatedSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _prevIndex = oldWidget.currentIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isForward = widget.currentIndex >= _prevIndex;
    final slideOffset = isForward ? const Offset(0.08, 0) : const Offset(-0.08, 0);
    final reducedMotion = MediaQuery.maybeOf(context)?.accessibleNavigation ?? false;

    if (reducedMotion) {
      return widget.child;
    }

    return AnimatedSwitcher(
      duration: widget.duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final isChildNew = child.key == ValueKey<int>(widget.currentIndex);
        
        final offsetTween = isChildNew
            ? Tween<Offset>(begin: slideOffset, end: Offset.zero)
            : Tween<Offset>(begin: isForward ? const Offset(-0.08, 0) : const Offset(0.08, 0), end: Offset.zero);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: offsetTween.animate(animation),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// A premium animated checkbox that scales and bounces with tactile spring feedback.
class AnimatedCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? checkColor;
  final double size;

  const AnimatedCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.checkColor,
    this.size = 22.0,
  });

  @override
  State<AnimatedCheckbox> createState() => _AnimatedCheckboxState();
}

class _AnimatedCheckboxState extends State<AnimatedCheckbox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkScaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.85), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 0.85, end: 1.05), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.05, end: 1.0), weight: 30),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _checkScaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    );

    if (widget.value) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeBg = widget.activeColor ?? AppTheme.primary;
    final inactiveBg = widget.inactiveColor ?? Colors.transparent;
    final borderCol = widget.value ? activeBg : const Color(0xFFD0C4BC);
    final reducedMotion = MediaQuery.maybeOf(context)?.accessibleNavigation ?? false;

    if (reducedMotion) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Checkbox(
          value: widget.value,
          onChanged: (val) => widget.onChanged(val ?? false),
          activeColor: activeBg,
          side: BorderSide(color: borderCol),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        widget.onChanged(!widget.value);
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.value ? activeBg : inactiveBg,
            border: Border.all(
              color: borderCol,
              width: widget.value ? 0 : 2,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: widget.value
              ? ScaleTransition(
                  scale: _checkScaleAnimation,
                  child: Icon(
                    Icons.check,
                    color: widget.checkColor ?? Colors.white,
                    size: widget.size * 0.72,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// A premium animated toggle switch with beautiful spring back curves and color fades.
class AnimatedSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;

  const AnimatedSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
  });

  @override
  State<AnimatedSwitch> createState() => _AnimatedSwitchState();
}

class _AnimatedSwitchState extends State<AnimatedSwitch> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _thumbPosition;
  late Animation<Color?> _backgroundColor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    _thumbPosition = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutBack,
      ),
    );

    if (widget.value) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeBgColor = widget.activeColor ?? AppTheme.primary;
    final inactiveBgColor = widget.inactiveColor ?? const Color(0xFFE7E1DF);
    final resolvedThumbColor = widget.thumbColor ?? Colors.white;

    _backgroundColor = ColorTween(
      begin: inactiveBgColor,
      end: activeBgColor,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    final reducedMotion = MediaQuery.maybeOf(context)?.accessibleNavigation ?? false;

    if (reducedMotion) {
      return Switch(
        value: widget.value,
        onChanged: widget.onChanged,
        activeColor: activeBgColor,
      );
    }

    return GestureDetector(
      onTap: () {
        widget.onChanged(!widget.value);
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: 48,
            height: 28,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: _backgroundColor.value,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment(
                    _thumbPosition.value,
                    0.0,
                  ),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: resolvedThumbColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
