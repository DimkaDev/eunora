import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../analysis/domain/models/pattern_result.dart';
import 'pattern_detail_sheet.dart';

/// Card rendering an identified pattern with trigger, chips, effect sentence,
/// hit-rate line, stats line, and visible disclaimer. Tapping opens PatternDetailSheet.
class PatternCard extends StatelessWidget {
  final PatternInsight pattern;
  final VoidCallback? onTap;

  const PatternCard({
    super.key,
    required this.pattern,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String categoryLabel = _getCategoryLabel(pattern);
    final Color categoryColor = _getCategoryColor(pattern);

    return InkWell(
      onTap: onTap ?? () => PatternDetailSheet.show(context, pattern: pattern),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEBE6DF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Trigger name + Category & Confidence chips
            Row(
              children: [
                Expanded(
                  child: Text(
                    pattern.triggerDisplayName,
                    style: GoogleFonts.notoSerif(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D402D),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    categoryLabel,
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: categoryColor,
                    ),
                  ),
                ),
                if (pattern.confidence == PatternConfidence.high) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D402D),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'High confidence',
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // Effect sentence
            Text(
              pattern.headlineText,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D402D),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),

            // Hit rate line
            Text(
              pattern.hitRateText,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: const Color(0xFF67594E),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),

            // Stats line: "{P}% correlation · {n} events"
            Row(
              children: [
                const Icon(
                  Icons.show_chart,
                  size: 14,
                  color: Color(0xFF8C7D70),
                ),
                const SizedBox(width: 4),
                Text(
                  '${pattern.correlationPercent}% correlation · ${pattern.eventCount} events',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8C7D70),
                  ),
                ),
                const Spacer(),
                Text(
                  'Details',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D402D),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: Color(0xFF2D402D),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0ECE6)),
            const SizedBox(height: 8),

            // Approved disclaimer on the card itself
            Text(
              pattern.disclaimer,
              style: GoogleFonts.manrope(
                fontSize: 10,
                color: const Color(0xFF8C7D70),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(PatternInsight p) {
    if (p.triggerId == 'hot_weather' ||
        p.triggerId == 'warm_environment' ||
        p.triggerId == 'tight_clothing') {
      return 'Environment';
    }
    if (p.type == PatternType.protective) {
      return 'Protective';
    }
    return 'Trigger';
  }

  Color _getCategoryColor(PatternInsight p) {
    if (p.triggerId == 'hot_weather' ||
        p.triggerId == 'warm_environment' ||
        p.triggerId == 'tight_clothing') {
      return const Color(0xFF2E6B8E); // Teal/Blue for Environment
    }
    if (p.type == PatternType.protective) {
      return const Color(0xFF2E7D32); // Green for Protective
    }
    return const Color(0xFFC05A46); // Rust/Peach for Trigger
  }
}
