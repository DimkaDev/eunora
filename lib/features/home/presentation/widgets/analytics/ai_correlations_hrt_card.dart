import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/analysis/domain/models/hrt_change_result.dart';
import 'package:eunora/features/analysis/domain/models/pattern_result.dart';

/// Section 5b: "AI Correlations & HRT Impact" Card
/// Shows two lines: strongest pattern and latest regimen-change status.
/// The HRT line is omitted if HRT is not set up and is invariant across period changes.
class AiCorrelationsHrtCard extends StatelessWidget {
  final PatternEngineResult patternResult;
  final HrtAnalysisResult? hrtResult;
  final bool isHrtSetUp;
  final int loggedDaysCount;
  final bool isPremium;
  final VoidCallback? onSeeAllInsights;

  const AiCorrelationsHrtCard({
    super.key,
    required this.patternResult,
    this.hrtResult,
    required this.isHrtSetUp,
    this.loggedDaysCount = 0,
    this.isPremium = true,
    this.onSeeAllInsights,
  });

  @override
  Widget build(BuildContext context) {
    final strongestPattern = patternResult.patterns.isNotEmpty
        ? patternResult.patterns.first
        : null;

    final HrtRegimenGroup? latestHrtGroup = (hrtResult != null && hrtResult!.groups.isNotEmpty)
        ? hrtResult!.groups.first
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI CORRELATIONS & HRT IMPACT',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: AppTheme.onSurface,
                ),
              ),
              InkWell(
                onTap: () {
                  if (onSeeAllInsights != null) {
                    onSeeAllInsights!();
                  } else {
                    context.push('/insights');
                  }
                },
                child: Text(
                  'See all insights',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Line 1: Strongest Pattern
          _buildPatternLine(context, strongestPattern),

          // Line 2: HRT Regimen Change Status (only if HRT is set up)
          if (isHrtSetUp) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFEBE6DF)),
            ),
            _buildHrtLine(context, latestHrtGroup),
          ],
        ],
      ),
    );
  }

  Widget _buildPatternLine(BuildContext context, PatternInsight? strongest) {
    if (strongest != null) {
      final isProtective = strongest.type == PatternType.protective;
      final effectText =
          '${strongest.triggerDisplayName} → ${strongest.outcomeDisplayName} ${strongest.lag.displayText} · ${strongest.correlationPercent}% · ${strongest.eventCount} events';

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isProtective ? const Color(0xFFE8F5E9) : const Color(0xFFEDDDF5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isProtective ? Icons.health_and_safety_outlined : Icons.auto_awesome,
              color: isProtective ? const Color(0xFF2E7D32) : AppTheme.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'STRONGEST PATTERN',
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: AppTheme.outline,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (strongest.confidence.isHigh)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'High confidence',
                          style: GoogleFonts.manrope(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  effectText,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // SD-10 Empty / Building progress state for Line 1
    final nearest = patternResult.buildingItems.isNotEmpty
        ? patternResult.buildingItems.first
        : null;

    final String progressTitle;
    final String progressSubtitle;
    double? fraction;

    if (nearest != null) {
      progressTitle = '${nearest.triggerDisplayName} · ${nearest.eventsCount} of ${nearest.targetCount} events';
      progressSubtitle = 'Personal patterns unlock once at least ${nearest.targetCount} events are recorded.';
      fraction = (nearest.eventsCount / nearest.targetCount).clamp(0.0, 1.0);
    } else if (patternResult.emptyStateType == SD10EmptyType.notEnoughVariety) {
      progressTitle = 'Trigger variety needed';
      progressSubtitle = patternResult.emptyStateMessage ??
          'We need a few days without this trigger to compare.';
    } else if (patternResult.emptyStateType == SD10EmptyType.nothingNotable) {
      progressTitle = 'No clear patterns yet';
      progressSubtitle = patternResult.emptyStateMessage ??
          'No clear patterns yet — we keep checking as you log.';
    } else {
      progressTitle = 'Building baseline';
      final remaining = (7 - loggedDaysCount).clamp(1, 7);
      progressSubtitle = 'Log $remaining more days to reveal patterns.';
      fraction = (loggedDaysCount / 7.0).clamp(0.0, 1.0);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFFF0ECE7),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.insights_rounded,
            color: AppTheme.outline,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PATTERN STATUS',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppTheme.outline,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                progressTitle,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
              ),
              if (fraction != null) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 4,
                    backgroundColor: const Color(0xFFEBE6DF),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2D402D)),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                progressSubtitle,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHrtLine(BuildContext context, HrtRegimenGroup? latestGroup) {
    String hrtTitle;
    String hrtDetail;
    Color iconBg = const Color(0xFFE8EAF6);
    Color iconColor = const Color(0xFF3F51B5);
    IconData icon = Icons.medication_outlined;

    if (latestGroup == null) {
      hrtTitle = 'Current HRT regimen active';
      hrtDetail = 'No regimen changes recorded yet.';
    } else {
      switch (latestGroup.status) {
        case HrtChangeStatus.ready:
          hrtTitle = latestGroup.headlineText ?? latestGroup.summaryTitle;
          hrtDetail = latestGroup.statusMessage;
          iconBg = const Color(0xFFE8F5E9);
          iconColor = const Color(0xFF2E7D32);
          icon = Icons.check_circle_outline;
          break;

        case HrtChangeStatus.pending:
          final daysToGo = latestGroup.daysToGo ?? (14 - latestGroup.daysSinceChange).clamp(1, 14);
          hrtTitle = 'Day ${latestGroup.daysSinceChange} of 14 since regimen changed';
          hrtDetail = 'Comparison ready in $daysToGo days.';
          iconBg = const Color(0xFFFFF3E0);
          iconColor = const Color(0xFFE65100);
          icon = Icons.hourglass_top_outlined;
          break;

        case HrtChangeStatus.notEnoughBaseline:
          hrtTitle = 'Regimen changed on ${_formatDate(latestGroup.changeDate)}';
          hrtDetail = latestGroup.statusMessage; // "Not enough logged days before the change to compare"
          iconBg = const Color(0xFFFBE9E7);
          iconColor = const Color(0xFFD84315);
          icon = Icons.info_outline;
          break;

        case HrtChangeStatus.notEnoughFollowUp:
          hrtTitle = 'Regimen changed on ${_formatDate(latestGroup.changeDate)}';
          hrtDetail = latestGroup.statusMessage; // "Not enough logged days after the change to compare"
          iconBg = const Color(0xFFFBE9E7);
          iconColor = const Color(0xFFD84315);
          icon = Icons.info_outline;
          break;
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LATEST HRT STATUS',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppTheme.outline,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                hrtTitle,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hrtDetail,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}
