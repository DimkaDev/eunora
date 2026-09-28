import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../home/domain/entities/daily_log.dart';
import '../../domain/models/analysis_period.dart';
import '../../domain/models/period_comparison.dart';
import '../../domain/models/pattern_result.dart';
import '../../domain/models/symptom_metric.dart';
import '../../services/analysis_engine.dart';
import '../../services/pattern_engine.dart';

/// Modal bottom sheet displaying detailed metrics for a tapped symptom.
/// Follows Task 9 specifications:
/// - Quick stats with strict "{X} days" wording (never "times")
/// - SD-3 average severity and SD-4 trend badge
/// - Strongest displayable pattern, fallback to day-of-week pattern, or SD-10 state
/// - Recent 5 history entries with severity, duration (when recorded), triggers, and "Open in calendar"
/// - Medically reviewed management strategies (hidden until enabled)
/// - Physician note gated by SD-4 worsening + >= 14 logged days (approved wording, never "we recommend")
class SymptomDetailSheet extends StatelessWidget {
  final SymptomAnalysisMetric metric;
  final int totalLoggedDays;
  final List<DailyLog>? logs;
  final AnalysisPeriod? period;
  final PatternEngineResult? patternResult;
  final void Function(DateTime date)? onOpenDayInCalendar;

  /// Management strategies content library flag: hidden until enabled.
  static const bool hasReviewedStrategies = false;

  const SymptomDetailSheet({
    super.key,
    required this.metric,
    required this.totalLoggedDays,
    this.logs,
    this.period,
    this.patternResult,
    this.onOpenDayInCalendar,
  });

  static Future<void> show(
    BuildContext context, {
    required SymptomAnalysisMetric metric,
    required int totalLoggedDays,
    List<DailyLog>? logs,
    AnalysisPeriod? period,
    PatternEngineResult? patternResult,
    void Function(DateTime date)? onOpenDayInCalendar,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SymptomDetailSheet(
        metric: metric,
        totalLoggedDays: totalLoggedDays,
        logs: logs,
        period: period,
        patternResult: patternResult,
        onOpenDayInCalendar: onOpenDayInCalendar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Resolve patterns
    final pattern = _findStrongestPattern();
    final weekdayPattern = pattern == null ? _evaluateWeekdayPattern() : null;

    // Resolve recent history (last 5 entries where symptom was logged)
    final recentEntries = _getRecentEntries();

    // Physician note check: worsened materially per SD-4 AND >= 14 logged days
    final bool showPhysicianNote =
        metric.comparison?.changeType == MaterialChangeType.worsened &&
        totalLoggedDays >= 14;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAF7F2),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4CDC5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
                  children: [
                    // Header
                    _buildHeader(context),
                    const SizedBox(height: 20),

                    // Quick Stats
                    _buildQuickStats(),
                    const SizedBox(height: 24),

                    // Physician Note (if eligible)
                    if (showPhysicianNote) ...[
                      _buildPhysicianNote(context),
                      const SizedBox(height: 24),
                    ],

                    // Pattern Insight Section
                    _buildPatternSection(pattern, weekdayPattern),
                    const SizedBox(height: 24),

                    // Recent History Section
                    _buildRecentHistorySection(context, recentEntries),
                    const SizedBox(height: 24),

                    // Management Strategies (hidden until enabled)
                    if (hasReviewedStrategies) ...[
                      _buildManagementStrategies(),
                      const SizedBox(height: 24),
                    ],

                    // Close Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: const BorderSide(color: Color(0xFFD4CDC5)),
                          backgroundColor: Colors.white,
                        ),
                        child: Text(
                          'Close',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5E5248),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- HEADER ---
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metric.displayName,
                style: GoogleFonts.notoSerif(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D402D),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                metric.category.toUpperCase(),
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: const Color(0xFF8C7D70),
                ),
              ),
            ],
          ),
        ),
        if (metric.ranking != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE8E1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Rank #${metric.ranking}',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF5E5248),
              ),
            ),
          ),
      ],
    );
  }

  // --- QUICK STATS ---
  Widget _buildQuickStats() {
    // Days logged strictly uses "{X} days", never "times"
    final daysLoggedText = '${metric.daysPresent} days';
    final daysSubtitle = totalLoggedDays > 0
        ? 'of $totalLoggedDays logged'
        : 'in period';

    // Average severity label and "/ 5"
    final avgSevText = metric.averageSeverity != null
        ? '${metric.severityLabel} · ${metric.averageSeverity!.toStringAsFixed(1)} / 5'
        : '—';

    // Trend vs previous window (SD-4)
    final trendText = _formatTrendLabel();
    final trendSubtitle = metric.comparison?.isEligible == true
        ? 'vs previous window'
        : 'Needs more logs';

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'DAYS LOGGED',
            value: daysLoggedText,
            subtitle: daysSubtitle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            label: 'AVG SEVERITY',
            value: avgSevText,
            subtitle: 'When present',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            label: 'TREND',
            value: trendText,
            subtitle: trendSubtitle,
            valueColor: _getTrendColor(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String subtitle,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBE6DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: const Color(0xFF8C7D70),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor ?? const Color(0xFF2D402D),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.manrope(
              fontSize: 10,
              color: const Color(0xFF9E9287),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatTrendLabel() {
    final comp = metric.comparison;
    if (comp == null || !comp.isEligible) {
      return 'No comparison';
    }
    final change = comp.delta ?? ((comp.currentValue ?? 0) - (comp.previousValue ?? 0));
    final sign = change > 0 ? '+' : '';
    switch (comp.changeType) {
      case MaterialChangeType.worsened:
        return 'Worsened ($sign${change.toStringAsFixed(1)})';
      case MaterialChangeType.improved:
        return 'Improved (${change.toStringAsFixed(1)})';
      case MaterialChangeType.steady:
      default:
        return 'Steady (±${change.abs().toStringAsFixed(1)})';
    }
  }

  Color? _getTrendColor() {
    final comp = metric.comparison;
    if (comp == null || !comp.isEligible) return null;
    switch (comp.changeType) {
      case MaterialChangeType.worsened:
        return const Color(0xFFBA1A1A);
      case MaterialChangeType.improved:
        return const Color(0xFF2E5E4E);
      case MaterialChangeType.steady:
      default:
        return const Color(0xFF5E5248);
    }
  }

  // --- PHYSICIAN NOTE ---
  Widget _buildPhysicianNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFDBC8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.medical_information_outlined,
                size: 20,
                color: Color(0xFFB44B22),
              ),
              const SizedBox(width: 8),
              Text(
                'NOTE FOR YOUR PHYSICIAN',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: const Color(0xFFB44B22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This trend may be worth mentioning at your next appointment',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4A2818),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/passport');
              },
              icon: const Icon(Icons.description_outlined, size: 16),
              label: Text(
                'Open Health Passport',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB44B22),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- PATTERN INSIGHT SECTION ---
  Widget _buildPatternSection(PatternInsight? pattern, _WeekdayPatternResult? weekdayPattern) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PATTERN INSIGHT',
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: const Color(0xFF8C7D70),
          ),
        ),
        const SizedBox(height: 10),
        if (pattern != null)
          _buildStrongestPatternCard(pattern)
        else if (weekdayPattern != null)
          _buildWeekdayPatternCard(weekdayPattern)
        else
          _buildSD10PatternCard(),
      ],
    );
  }

  Widget _buildStrongestPatternCard(PatternInsight pattern) {
    final isProtective = pattern.type == PatternType.protective;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBE6DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isProtective
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFBE9E7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isProtective ? 'Protective' : 'Trigger',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isProtective
                        ? const Color(0xFF2E5E4E)
                        : const Color(0xFFBA1A1A),
                  ),
                ),
              ),
              if (pattern.confidence.isHigh) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'High confidence',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0369A1),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            pattern.headlineText,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D402D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${pattern.correlationPercent}% correlation · ${pattern.eventCount} events',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF67594E),
            ),
          ),
          if (pattern.hitRateText.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              pattern.hitRateText,
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: const Color(0xFF8C7D70),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            kApprovedTriggerDisclaimer,
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF9E9287),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayPatternCard(_WeekdayPatternResult wp) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBE6DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Day-of-Week Pattern',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF7E22CE),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Higher on ${wp.weekdayName}s',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D402D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'In your data, ${metric.displayName.toLowerCase()} tends to be higher on ${wp.weekdayName}s '
            '(average ${wp.weekdayAvg.toStringAsFixed(1)} / 5 vs ${wp.otherAvg.toStringAsFixed(1)} / 5 on other days).',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: const Color(0xFF5E5248),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Based on ${wp.weekdayCount} occurrences across your tracking window.',
            style: GoogleFonts.manrope(
              fontSize: 10,
              color: const Color(0xFF9E9287),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSD10PatternCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBE6DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.hourglass_empty_rounded,
                size: 18,
                color: Color(0xFF8C7D70),
              ),
              const SizedBox(width: 8),
              Text(
                'Keep logging to discover patterns',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D402D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'We need more data to identify reliable patterns for ${metric.displayName.toLowerCase()}. '
            'Patterns appear once you have logged this symptom alongside your daily habits across at least 14 days.',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: const Color(0xFF67594E),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // --- RECENT HISTORY SECTION ---
  Widget _buildRecentHistorySection(BuildContext context, List<_RecentHistoryItem> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RECENT HISTORY',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: const Color(0xFF8C7D70),
              ),
            ),
            Text(
              'Last 5 logged days',
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: const Color(0xFF8C7D70),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEBE6DF)),
            ),
            child: Center(
              child: Text(
                'No recorded logs for this symptom in the current window.',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: const Color(0xFF8C7D70),
                ),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEBE6DF)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF2EFE9)),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Date (no clock times!)
                          Text(
                            DateFormat('EEE, MMM d').format(entry.date),
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2D402D),
                            ),
                          ),
                          Row(
                            children: [
                              // Duration if recorded
                              if (entry.durationMinutes != null && entry.durationMinutes! > 0) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2EFE9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${entry.durationMinutes} min',
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF5E5248),
                                    ),
                                  ),
                                ),
                              ],
                              // Severity chip
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _getSeverityChipBg(entry.severityLabel),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  entry.severityLabel,
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _getSeverityChipTextColor(entry.severityLabel),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Triggers logged that day
                      if (entry.triggers.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: entry.triggers.map((t) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F3EF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                t,
                                style: GoogleFonts.manrope(
                                  fontSize: 10,
                                  color: const Color(0xFF67594E),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 10),
                      // Action: Open day in calendar (strictly no delete, no edit)
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            if (onOpenDayInCalendar != null) {
                              onOpenDayInCalendar!(entry.date);
                            } else {
                              context.push('/calendar', extra: entry.date);
                            }
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 13,
                                  color: Color(0xFF2D402D),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Open in calendar',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2D402D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // --- MANAGEMENT STRATEGIES ---
  Widget _buildManagementStrategies() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MANAGEMENT STRATEGIES',
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: const Color(0xFF8C7D70),
          ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Medically Reviewed Guidance',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D402D),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Evidence-based lifestyle and clinical options for managing ${metric.displayName.toLowerCase()}.',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: const Color(0xFF67594E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- RESOLUTION HELPERS ---
  PatternInsight? _findStrongestPattern() {
    PatternEngineResult? pr = patternResult;
    if (pr == null && logs != null && logs!.isNotEmpty) {
      final effectivePeriod = period ?? AnalysisPeriod.days30;
      pr = const PatternEngine().analyze(logs: logs!, period: effectivePeriod);
    }
    if (pr == null) return null;

    final matching = pr.displayablePatterns.where((p) {
      return p.outcomeId.toLowerCase() == metric.symptomId.toLowerCase() ||
          p.outcomeDisplayName.toLowerCase() == metric.displayName.toLowerCase();
    }).toList();

    if (matching.isEmpty) return null;
    matching.sort((a, b) => b.strength.compareTo(a.strength));
    return matching.first;
  }

  _WeekdayPatternResult? _evaluateWeekdayPattern() {
    if (logs == null || logs!.isEmpty) return null;

    // Requirement: at least 4 weeks of data (28 days)
    final sortedLogs = [...logs!]..sort((a, b) => a.date.compareTo(b.date));
    final int spanDays = sortedLogs.last.date.difference(sortedLogs.first.date).inDays + 1;
    final int periodDays = period?.dayCount ?? 30;
    if (spanDays < 28 && periodDays < 28 && logs!.length < 28) {
      return null;
    }

    // Weekday scores: 1 (Mon) to 7 (Sun)
    final Map<int, List<double>> weekdayScores = {for (int i = 1; i <= 7; i++) i: []};

    for (final log in logs!) {
      if (!log.isCompleted) continue;
      for (final s in log.symptoms) {
        if (s.symptom.id.toLowerCase() == metric.symptomId.toLowerCase() ||
            s.symptom.name.toLowerCase() == metric.displayName.toLowerCase()) {
          final double score = s.intensity?.toDouble() ??
              (s.severity?.toLowerCase() == 'mild'
                  ? 1.0
                  : s.severity?.toLowerCase() == 'moderate'
                      ? 3.0
                      : s.severity?.toLowerCase() == 'severe'
                          ? 5.0
                          : 3.0);
          weekdayScores[log.date.weekday]!.add(score);
          break;
        }
      }
    }

    _WeekdayPatternResult? bestResult;
    double maxDiff = 0.0;

    const weekdayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    for (int w = 1; w <= 7; w++) {
      final scores = weekdayScores[w]!;
      // Requirement: at least 3 logged occurrences of that weekday
      if (scores.length < 3) continue;

      final double avgW = scores.reduce((a, b) => a + b) / scores.length;

      // Other weekdays combined
      final List<double> otherScores = [];
      for (int ow = 1; ow <= 7; ow++) {
        if (ow != w) {
          otherScores.addAll(weekdayScores[ow]!);
        }
      }

      if (otherScores.isEmpty) continue;
      final double avgOther = otherScores.reduce((a, b) => a + b) / otherScores.length;

      final diff = avgW - avgOther;
      // Requirement: average score is at least 0.5 higher than average of other weekdays
      if (diff >= 0.5 && diff > maxDiff) {
        maxDiff = diff;
        bestResult = _WeekdayPatternResult(
          weekday: w,
          weekdayName: weekdayNames[w],
          weekdayAvg: avgW,
          otherAvg: avgOther,
          diff: diff,
          weekdayCount: scores.length,
        );
      }
    }

    return bestResult;
  }

  List<_RecentHistoryItem> _getRecentEntries() {
    if (logs == null || logs!.isEmpty) return [];

    final List<_RecentHistoryItem> entries = [];
    for (final log in logs!) {
      for (final s in log.symptoms) {
        if (s.symptom.id.toLowerCase() == metric.symptomId.toLowerCase() ||
            s.symptom.name.toLowerCase() == metric.displayName.toLowerCase()) {
          final double score = s.intensity?.toDouble() ??
              (s.severity?.toLowerCase() == 'mild'
                  ? 1.0
                  : s.severity?.toLowerCase() == 'moderate'
                      ? 3.0
                      : s.severity?.toLowerCase() == 'severe'
                          ? 5.0
                          : 3.0);
          final label = s.severity ?? AnalysisEngine.severityLabelForScore(score);
          entries.add(
            _RecentHistoryItem(
              date: log.date,
              severityLabel: label,
              intensity: score,
              durationMinutes: s.durationMinutes,
              triggers: log.triggers,
            ),
          );
          break;
        }
      }
    }

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries.take(5).toList();
  }

  Color _getSeverityChipBg(String label) {
    switch (label.toLowerCase()) {
      case 'mild':
        return const Color(0xFFE8F5E9);
      case 'severe':
        return const Color(0xFFFBE9E7);
      case 'moderate':
      default:
        return const Color(0xFFFFF3E0);
    }
  }

  Color _getSeverityChipTextColor(String label) {
    switch (label.toLowerCase()) {
      case 'mild':
        return const Color(0xFF2E5E4E);
      case 'severe':
        return const Color(0xFFBA1A1A);
      case 'moderate':
      default:
        return const Color(0xFFB44B22);
    }
  }
}

class _WeekdayPatternResult {
  final int weekday;
  final String weekdayName;
  final double weekdayAvg;
  final double otherAvg;
  final double diff;
  final int weekdayCount;

  const _WeekdayPatternResult({
    required this.weekday,
    required this.weekdayName,
    required this.weekdayAvg,
    required this.otherAvg,
    required this.diff,
    required this.weekdayCount,
  });
}

class _RecentHistoryItem {
  final DateTime date;
  final String severityLabel;
  final double intensity;
  final int? durationMinutes;
  final List<String> triggers;

  const _RecentHistoryItem({
    required this.date,
    required this.severityLabel,
    required this.intensity,
    this.durationMinutes,
    required this.triggers,
  });
}
