import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/utils/animation_system.dart';

class QuantityCounterSelector extends StatelessWidget {
  final int value;
  final String label;
  final ValueChanged<int> onChanged;
  final String Function(int value) displayValueBuilder;
  final int stepValue;
  final int minValue;
  final int? maxValue;

  const QuantityCounterSelector({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    required this.displayValueBuilder,
    this.stepValue = 1,
    this.minValue = 1,
    this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final canDecrement = value > minValue;
    final canIncrement = maxValue == null || value < maxValue!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.manrope(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: const Color(0xFF8A817C),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F5F0).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CounterButton(
                icon: Icons.remove,
                isEnabled: canDecrement,
                onTap: canDecrement ? () => onChanged(value - stepValue) : null,
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.80, end: 1.0).animate(
                        CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                      ),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  displayValueBuilder(value),
                  key: ValueKey<String>(displayValueBuilder(value)),
                  style: GoogleFonts.notoSerif(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              _CounterButton(
                icon: Icons.add,
                isEnabled: canIncrement,
                onTap: canIncrement ? () => onChanged(value + stepValue) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CounterButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isEnabled;

  const _CounterButton({
    required this.icon,
    required this.onTap,
    required this.isEnabled,
  });

  @override
  State<_CounterButton> createState() => _CounterButtonState();
}

class _CounterButtonState extends State<_CounterButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.78).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.78, end: 1.12).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.12, end: 1.0).chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 25,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.isEnabled || widget.onTap == null) return;
    _controller.forward(from: 0.0);
    HapticFeedback.lightImpact();
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: widget.isEnabled ? 1.0 : 0.35,
      child: GestureDetector(
        onTap: widget.isEnabled ? _handleTap : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.isEnabled ? _scaleAnimation.value : 1.0,
              child: child,
            );
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: widget.isEnabled
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              widget.icon,
              color: widget.isEnabled ? AppTheme.primary : const Color(0xFFBBB0A8),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
