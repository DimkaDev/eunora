import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../analysis/domain/models/pattern_result.dart';

/// Section showing up to 3 building items nearest to the 7-event threshold.
class BuildingPatternsSection extends StatelessWidget {
  final List<BuildingPatternItem> items;

  const BuildingPatternsSection({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final displayItems = items.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BUILDING PATTERNS',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: const Color(0xFF8C7D70),
              ),
            ),
            Text(
              'Approaching 7 events',
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: const Color(0xFF8C7D70),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEBE6DF)),
          ),
          child: Column(
            children: displayItems.map((item) {
              final double progress =
                  (item.eventsCount / item.targetCount).clamp(0.0, 1.0);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.displayText,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2D402D),
                          ),
                        ),
                        Text(
                          '${item.eventsCount} / ${item.targetCount}',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8C7D70),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: const Color(0xFFE8E3DC),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF2D402D)),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
