import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';

class QuantityCounterSelector extends StatelessWidget {
  final int value;
  final String label;
  final ValueChanged<int> onChanged;
  final String Function(int value) displayValueBuilder;
  final int stepValue;
  final int minValue;

  const QuantityCounterSelector({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    required this.displayValueBuilder,
    this.stepValue = 1,
    this.minValue = 1,
  });

  @override
  Widget build(BuildContext context) {
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
              GestureDetector(
                onTap: () {
                  if (value > minValue) {
                    onChanged(value - stepValue);
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.remove, color: AppTheme.primary),
                ),
              ),
              Text(
                displayValueBuilder(value),
                style: GoogleFonts.notoSerif(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              GestureDetector(
                onTap: () => onChanged(value + stepValue),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: AppTheme.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
