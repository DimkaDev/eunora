import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../analysis/domain/models/pattern_result.dart';
import '../../../analysis/services/analysis_engine.dart';

/// Modal bottom sheet displaying deep-dive pattern details:
/// comparative outcome bars, list of event days, and a short methodology note.
class PatternDetailSheet extends StatelessWidget {
  final PatternInsight pattern;

  const PatternDetailSheet({
    super.key,
    required this.pattern,
  });

  static Future<void> show(
    BuildContext context, {
    required PatternInsight pattern,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PatternDetailSheet(pattern: pattern),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exposedLabel = AnalysisEngine.severityLabelForScore(pattern.exposedAverage);
    final unexposedLabel = AnalysisEngine.severityLabelForScore(pattern.unexposedAverage);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0DDD5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pattern.triggerDisplayName} → ${pattern.outcomeDisplayName}',
                      style: GoogleFonts.notoSerif(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D402D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pattern.correlationPercent}% correlation · ${pattern.eventCount} exposed events',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8C7D70),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF8C7D70)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Headline statement
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F7F4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEDE8E1)),
                    ),
                    child: Text(
                      pattern.headlineText,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D402D),
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 1: Two comparative bars
                  Text(
                    'AVERAGE OUTCOME COMPARISON',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: const Color(0xFF8C7D70),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF9F6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEBE6DF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOutcomeBar(
                          label: pattern.lag == PatternLag.lag1
                              ? 'On days after ${pattern.triggerDisplayName}'
                              : 'On days with ${pattern.triggerDisplayName}',
                          score: pattern.exposedAverage,
                          severityLabel: exposedLabel,
                          color: pattern.type == PatternType.protective
                              ? const Color(0xFF4A7C59)
                              : const Color(0xFFC05A46),
                        ),
                        const SizedBox(height: 16),
                        _buildOutcomeBar(
                          label: 'Other days',
                          score: pattern.unexposedAverage,
                          severityLabel: unexposedLabel,
                          color: const Color(0xFF8C7D70),
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: Color(0xFFE8E3DC)),
                        const SizedBox(height: 10),
                        Text(
                          'Average difference: ${(pattern.effect.abs()).toStringAsFixed(1)} points across ${pattern.comparisonDaysCount + pattern.eventCount} paired days.',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: const Color(0xFF67594E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section 2: List of Event Days
                  Text(
                    'RECORDED EVENT DAYS',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: const Color(0xFF8C7D70),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Days you logged ${pattern.triggerDisplayName} with the resulting ${pattern.outcomeDisplayName} intensity:',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: const Color(0xFF67594E),
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (pattern.eventDays.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F7F4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEDE8E1)),
                      ),
                      child: Text(
                        'Logged on ${pattern.eventCount} days during this period.',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: const Color(0xFF5D534A),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEBE6DF)),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pattern.eventDays.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFF0ECE6)),
                        itemBuilder: (context, index) {
                          final event = pattern.eventDays[index];
                          final dateStr = DateFormat('EEE, MMM d').format(event.date);
                          final scoreLabel =
                              AnalysisEngine.severityLabelForScore(event.outcomeScore);

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 15,
                                      color: Color(0xFF8C7D70),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      dateStr,
                                      style: GoogleFonts.manrope(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF2D402D),
                                      ),
                                    ),
                                    if (event.isLagged) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0ECE6),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '+1d lag',
                                          style: GoogleFonts.manrope(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF67594E),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '$scoreLabel · ${event.outcomeScore.toStringAsFixed(1)} / 5',
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _colorForScore(event.outcomeScore),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Section 3: Short method note
                  Text(
                    'METHOD NOTE',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: const Color(0xFF8C7D70),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3EF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Evaluated across ${pattern.eventCount} exposed days and ${pattern.comparisonDaysCount} comparison days '
                      'using Pearson correlation (r = ${(pattern.rawCorrelation).toStringAsFixed(2)}). '
                      'Timing is evaluated at ${pattern.lag == PatternLag.lag1 ? "1-day lag (next day)" : "same day (lag 0)"}. '
                      'Patterns require at least 7 exposed events and a correlation strength of at least 30%.',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: const Color(0xFF5D534A),
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Disclaimer
                  Text(
                    pattern.disclaimer,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: const Color(0xFF8C7D70),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutcomeBar({
    required String label,
    required double score,
    required String severityLabel,
    required Color color,
  }) {
    final double ratio = (score / 5.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D402D),
                ),
              ),
            ),
            Text(
              '$severityLabel · ${score.toStringAsFixed(1)} / 5',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE8E3DC),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            FractionallySizedBox(
              widthFactor: ratio,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _colorForScore(double score) {
    if (score >= 4.0) return const Color(0xFFC05A46);
    if (score >= 2.0) return const Color(0xFFC78235);
    return const Color(0xFF4A7C59);
  }
}
