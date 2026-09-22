import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../analysis/domain/models/pattern_result.dart';
import '../../../../analysis/domain/models/reviewed_tip_library.dart';

/// Personalized Insight Banner for the Tracker / Calendar screen.
/// Displays the strongest displayable pattern as a calm observation,
/// followed by a single reviewed lifestyle tip (if one exists for that trigger),
/// and the approved Section E2 disclaimer verbatim.
/// Fallback when no pattern: "Log {X} more days to unlock personal insights."
/// NEVER mentions hours or time of day per SD-8.
class CalendarInsightsBanner extends StatelessWidget {
  final PatternEngineResult? patternResult;
  final int loggedDaysCount;
  final VoidCallback? onLearnMore;
  final bool isInsufficientData;

  const CalendarInsightsBanner({
    super.key,
    this.patternResult,
    this.loggedDaysCount = 0,
    this.onLearnMore,
    this.isInsufficientData = false,
  });

  @override
  Widget build(BuildContext context) {
    final strongest = patternResult?.displayablePatterns.firstOrNull;

    if (isInsufficientData || strongest == null) {
      return _buildFallbackBanner();
    }

    return _buildPatternBanner(strongest);
  }

  Widget _buildPatternBanner(PatternInsight pattern) {
    final isProtective = pattern.type == PatternType.protective;
    final lagText = pattern.lag == PatternLag.lag1 ? 'the day after' : 'on days you log it';

    // Phrased as a calm observation per SD-8
    final observation = isProtective
        ? 'In your data, ${pattern.outcomeDisplayName} tends to be milder $lagText when you log ${pattern.triggerDisplayName}.'
        : 'In your data, ${pattern.outcomeDisplayName} tends to be stronger $lagText when you log ${pattern.triggerDisplayName}.';

    final tip = getReviewedTip(pattern.triggerId);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: isProtective ? const Color(0xFF2D402D) : const Color(0xFF814F45),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isProtective ? Icons.shield_outlined : Icons.psychology_alt,
                            color: isProtective ? const Color(0xFF2D402D) : const Color(0xFF814F45),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Personalized Insight',
                            style: GoogleFonts.notoSerif(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Calm observation
                      Text(
                        observation,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: AppTheme.onSurface,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                      // Single reviewed lifestyle tip if present
                      if (tip != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F7F3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEBE6DF)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.tips_and_updates_outlined,
                                size: 16,
                                color: Color(0xFF67594E),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: const Color(0xFF5E5248),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Section E2 Approved Disclaimer verbatim
                      Text(
                        kApprovedTriggerDisclaimer,
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          color: const Color(0xFF8C7D70),
                          height: 1.4,
                        ),
                      ),
                      if (onLearnMore != null) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFE7E1DF)),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: onLearnMore,
                            icon: const Text('SEE ALL PATTERNS'),
                            label: const Icon(Icons.open_in_new, size: 14),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF814F45),
                              padding: EdgeInsets.zero,
                              textStyle: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackBanner() {
    final remainingDays = (14 - loggedDaysCount).clamp(1, 14);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: const Color(0xFF9E9287),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.psychology_alt_outlined,
                            color: Color(0xFF9E9287),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Personalized Insight',
                            style: GoogleFonts.notoSerif(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Log $remainingDays more days to unlock personal insights.',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: AppTheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        kApprovedTriggerDisclaimer,
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          color: const Color(0xFF8C7D70),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
