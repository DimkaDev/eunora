import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../analysis/domain/models/pattern_result.dart';

/// Patterns card for the Tracker / Calendar screen.
/// Displays the top 2 displayable patterns or an insufficient data progress state per Task 6.
class CalendarPatternsCard extends StatelessWidget {
  final PatternEngineResult patternResult;
  final VoidCallback? onSeeAll;

  const CalendarPatternsCard({
    super.key,
    required this.patternResult,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final displayable = patternResult.displayablePatterns.take(2).toList();
    final hasPatterns = displayable.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Indicator + Title + "See all"
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Patterns',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See all',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D402D),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Color(0xFF2D402D),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (hasPatterns)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  for (int i = 0; i < displayable.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _buildPatternRow(displayable[i]),
                  ],
                ],
              ),
            )
          else
            _buildInsufficientDataState(),
        ],
      ),
    );
  }

  Widget _buildPatternRow(PatternInsight pattern) {
    final lagPhrase = pattern.lag == PatternLag.lag1 ? 'next day' : 'same day';
    // Format: "{Trigger} → {symptom} {short lag phrase} · {P}% · {n} events"
    final rowText =
        '${pattern.triggerDisplayName} → ${pattern.outcomeDisplayName} $lagPhrase · ${pattern.correlationPercent}% · ${pattern.eventCount} events';

    final isProtective = pattern.type == PatternType.protective;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isProtective
              ? const Color(0xFF2D402D).withValues(alpha: 0.2)
              : AppTheme.outlineVariant.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isProtective ? Icons.shield_outlined : Icons.insights,
            size: 18,
            color: isProtective ? const Color(0xFF2D402D) : const Color(0xFF7A6B5F),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              rowText,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsufficientDataState() {
    final trigger = patternResult.progressTriggerName ?? 'Logging';
    final currentEvents = patternResult.progressCurrentEvents;
    final targetEvents = patternResult.progressTargetEvents > 0
        ? patternResult.progressTargetEvents
        : 7;
    final progressFraction = (currentEvents / targetEvents).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'INSUFFICIENT DATA',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: AppTheme.outline,
                  ),
                ),
                Text(
                  '$trigger · $currentEvents of $targetEvents events',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D402D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressFraction,
                minHeight: 6,
                backgroundColor: const Color(0xFFEBE6DF),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2D402D)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Personal patterns unlock once at least $targetEvents paired events are recorded.',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppTheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
