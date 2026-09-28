import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../analysis/domain/models/pattern_result.dart';
import 'calculation_methods_sheet.dart';

/// Hero header card for AI Insights page:
/// Shows "{N} patterns identified", window label, approved disclaimer,
/// "How are these calculated?" action, or SD-10 empty states when N = 0.
class InsightsHeroCard extends StatelessWidget {
  final int patternsCount;
  final String windowNotice;
  final SD10EmptyType emptyStateType;
  final String? emptyStateMessage;
  final BuildingPatternItem? nearestBuildingItem;

  const InsightsHeroCard({
    super.key,
    required this.patternsCount,
    this.windowNotice = 'Based on last 30 days',
    this.emptyStateType = SD10EmptyType.none,
    this.emptyStateMessage,
    this.nearestBuildingItem,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasPatterns = patternsCount > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBE6DF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: badge + "How are these calculated?" action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasPatterns
                      ? const Color(0xFFE8F0E9)
                      : const Color(0xFFF2EFE9),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  hasPatterns ? 'ANALYSIS READY' : 'AI INSIGHTS',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: hasPatterns
                        ? const Color(0xFF2E5E4E)
                        : const Color(0xFF67594E),
                  ),
                ),
              ),
              InkWell(
                onTap: () => CalculationMethodsSheet.show(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.help_outline,
                        size: 15,
                        color: Color(0xFF8C7D70),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'How are these calculated?',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF67594E),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (hasPatterns) ...[
            Text(
              patternsCount == 1
                  ? '1 pattern identified'
                  : '$patternsCount patterns identified',
              style: GoogleFonts.notoSerif(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D402D),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              windowNotice,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8C7D70),
              ),
            ),
            const SizedBox(height: 14),
            // Visible disclaimer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F7F4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEDE8E1)),
              ),
              child: Text(
                kApprovedTriggerDisclaimer,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: const Color(0xFF67594E),
                  height: 1.4,
                ),
              ),
            ),
          ] else ...[
            // SD-10 Empty States
            _buildEmptyStateContent(context),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyStateContent(BuildContext context) {
    String headline;
    String description;

    switch (emptyStateType) {
      case SD10EmptyType.notEnoughVariety:
        headline = 'More variety needed';
        description = emptyStateMessage ??
            'We need a few days with and without each factor to compare.';
        break;
      case SD10EmptyType.nothingNotable:
        headline = 'No strong patterns yet';
        description = emptyStateMessage ??
            'No clear patterns yet — we keep checking as you log.';
        break;
      case SD10EmptyType.notEnoughData:
      case SD10EmptyType.none:
      default:
        headline = 'Building your patterns';
        description = emptyStateMessage ??
            'Log at least 14 days of symptoms and triggers to unlock your personal patterns.';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headline,
          style: GoogleFonts.notoSerif(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D402D),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: const Color(0xFF67594E),
            height: 1.45,
          ),
        ),
        if (nearestBuildingItem != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEBE6DF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      nearestBuildingItem!.displayText,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D402D),
                      ),
                    ),
                    Text(
                      '${nearestBuildingItem!.eventsCount} / ${nearestBuildingItem!.targetCount}',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8C7D70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (nearestBuildingItem!.eventsCount /
                            nearestBuildingItem!.targetCount)
                        .clamp(0.0, 1.0),
                    backgroundColor: const Color(0xFFE8E3DC),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF2D402D)),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          kApprovedTriggerDisclaimer,
          style: GoogleFonts.manrope(
            fontSize: 11,
            color: const Color(0xFF8C7D70),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
