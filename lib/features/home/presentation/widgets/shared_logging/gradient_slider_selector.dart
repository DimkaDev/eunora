import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';

class GradientSliderSelector extends StatelessWidget {
  final List<String> values;
  final String currentValue;
  final ValueChanged<String> onChanged;
  final String label;
  final String Function(String value) emojiGetter;

  const GradientSliderSelector({
    super.key,
    required this.values,
    required this.currentValue,
    required this.onChanged,
    required this.label,
    required this.emojiGetter,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the index of the current value to align the sliding thumb.
    // If the list is empty or the value is not found, fallback to 0.
    final int index = values.indexOf(currentValue);
    final int selectedIndex = index != -1 ? index : 0;

    // We align the thumb based on index
    // For 3 items:
    // Index 0 -> Alignment.centerLeft
    // Index 1 -> Alignment.center
    // Index 2 -> Alignment.centerRight
    // To generalise slightly or keep it robust for 3 options:
    Alignment alignment = Alignment.center;
    if (values.length <= 1) {
      alignment = Alignment.center;
    } else {
      final double fraction = selectedIndex / (values.length - 1);
      // Map 0.0 -> -1.0 (left), 0.5 -> 0.0 (center), 1.0 -> 1.0 (right)
      alignment = Alignment(fraction * 2.0 - 1.0, 0.0);
    }

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
        const SizedBox(height: 12),
        Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFE2F5E2), // Soft Green (Mild/Calm/Low)
                Color(0xFFFFF1D0), // Soft Yellow/Orange (Moderate)
                Color(0xFFFFE0E0), // Soft Red (Severe/High/Intense)
              ],
            ),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Stack(
            children: [
              // White sliding thumb selector
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: alignment,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.26,
                  height: 48,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                ),
              ),
              Row(
                children: values.map((val) {
                  final isSelected = val == currentValue;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(val),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              emojiGetter(val),
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              val,
                              style: GoogleFonts.manrope(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppTheme.primary
                                    : const Color(0xFF8A817C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
