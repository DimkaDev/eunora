import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/period_comparison.dart';
import '../../domain/models/symptom_metric.dart';

/// Table rendering symptom metrics for the active window.
/// Displays days present, average severity with SD-3 label, and SD-4 trend arrow.
/// Tapping a row opens the Symptom Detail sheet.
class SymptomSummaryTable extends StatelessWidget {
  final List<SymptomAnalysisMetric> symptoms;
  final int totalLoggedDays;
  final void Function(SymptomAnalysisMetric metric)? onTapSymptom;

  const SymptomSummaryTable({
    super.key,
    required this.symptoms,
    required this.totalLoggedDays,
    this.onTapSymptom,
  });

  @override
  Widget build(BuildContext context) {
    if (symptoms.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F7F3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEBE6DF)),
        ),
        child: Center(
          child: Text(
            'No symptoms recorded in this period.',
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: const Color(0xFF8C7D70),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBE6DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Text(
                  'SYMPTOM',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: const Color(0xFF8C7D70),
                  ),
                ),
                const Spacer(),
                Text(
                  'DAYS',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: const Color(0xFF8C7D70),
                  ),
                ),
                const SizedBox(width: 24),
                Text(
                  'SEVERITY',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: const Color(0xFF8C7D70),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'TREND',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: const Color(0xFF8C7D70),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEBE6DF)),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: symptoms.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF5F2EC)),
            itemBuilder: (context, index) {
              final s = symptoms[index];
              return InkWell(
                onTap: () => onTapSymptom?.call(s),
                borderRadius: index == symptoms.length - 1
                    ? const BorderRadius.vertical(bottom: Radius.circular(16))
                    : BorderRadius.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.displayName,
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2D402D),
                              ),
                            ),
                            Text(
                              s.category,
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                color: const Color(0xFF8C7D70),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${s.daysPresent}/$totalLoggedDays',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5E5248),
                        ),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 75,
                        child: Text(
                          s.averageSeverity != null
                              ? '${s.severityLabel} · ${s.averageSeverity!.toStringAsFixed(1)}'
                              : '—',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getSeverityColor(s.severityLabel),
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 40,
                        child: Center(
                          child: _buildTrendIcon(s.comparison),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String? label) {
    if (label == 'Mild') return const Color(0xFF2D402D);
    if (label == 'Moderate') return const Color(0xFF9A5B1E);
    if (label == 'Severe') return const Color(0xFFBA1A1A);
    return const Color(0xFF8C7D70);
  }

  Widget _buildTrendIcon(MetricComparison? comp) {
    if (comp == null || !comp.isEligible) {
      return Text(
        '—',
        style: GoogleFonts.manrope(
          fontSize: 13,
          color: const Color(0xFFB0A59A),
        ),
      );
    }

    if (comp.changeType == MaterialChangeType.steady) {
      return const Icon(Icons.remove, size: 16, color: Color(0xFF8C7D70));
    }

    if (comp.changeType == MaterialChangeType.improved) {
      return const Icon(Icons.arrow_downward, size: 16, color: Color(0xFF2E5E4E));
    } else {
      return const Icon(Icons.arrow_upward, size: 16, color: Color(0xFFBA1A1A));
    }
  }
}
