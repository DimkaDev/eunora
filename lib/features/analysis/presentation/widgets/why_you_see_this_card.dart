import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/home_insight.dart';
import '../../domain/models/period_comparison.dart';
import '../../domain/models/window_analysis_result.dart';

/// Card that reveals "Why you see this" when opened from an insight or inspecting trend changes.
/// Shows the numbers behind the sentence with comparison bars.
class WhyYouSeeThisCard extends StatelessWidget {
  final HomeInsightCardData? insight;
  final WindowAnalysisResult analysis;

  const WhyYouSeeThisCard({
    super.key,
    this.insight,
    required this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    if (insight == null && analysis.severityComparison == null) {
      return const SizedBox.shrink();
    }

    final headline = insight?.headline ??
        ((analysis.severityComparison?.isEligible == true &&
                analysis.severityComparison?.changeType != MaterialChangeType.steady)
            ? 'Comparing symptom severity to your previous window.'
            : 'Symptom severity has remained steady compared to the previous window.');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBE6DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔍', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Why you see this',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4A3E36),
                ),
              ),
              const Spacer(),
              if (insight != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE0DDD5)),
                  ),
                  child: Text(
                    insight!.tag.label,
                    style: GoogleFonts.manrope(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: const Color(0xFF67594E),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            headline,
            style: GoogleFonts.manrope(
              fontSize: 13,
              height: 1.5,
              color: const Color(0xFF5E5248),
            ),
          ),
          const SizedBox(height: 16),
          _buildComparisonVisuals(context),
        ],
      ),
    );
  }

  Widget _buildComparisonVisuals(BuildContext context) {
    // 1. Sleep split explanation (W-3)
    if (insight?.candidateType == 'W-3') {
      return _buildTwoBarComparison(
        labelA: 'Under 6 hours sleep',
        valA: insight?.keyNumber ?? 3.5,
        unitA: '/ 5 severity',
        labelB: '6 hours or more',
        valB: 2.0,
        unitB: '/ 5 severity',
        maxVal: 5.0,
      );
    }

    // 2. Period comparison (W-1, or default window comparison)
    final comp = analysis.severityComparison;
    if (comp != null && comp.isEligible && comp.previousValue != null && comp.currentValue != null) {
      return _buildTwoBarComparison(
        labelA: 'Previous window',
        valA: comp.previousValue!,
        unitA: '/ 5 severity',
        labelB: 'Current window',
        valB: comp.currentValue!,
        unitB: '/ 5 severity',
        maxVal: 5.0,
      );
    }

    // 3. Fallback: Day vs 30d norm (D-2 / D-3)
    if (analysis.averageSeverity != null) {
      return _buildTwoBarComparison(
        labelA: 'Your 30-day norm',
        valA: analysis.averageSeverity!,
        unitA: '/ 5 avg',
        labelB: 'Inspected level',
        valB: insight?.keyNumber ?? analysis.averageSeverity!,
        unitB: '/ 5 level',
        maxVal: 5.0,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTwoBarComparison({
    required String labelA,
    required double valA,
    required String unitA,
    required String labelB,
    required double valB,
    String? unitB,
    required double maxVal,
  }) {
    final normA = (valA / maxVal).clamp(0.05, 1.0);
    final normB = (valB / maxVal).clamp(0.05, 1.0);

    return Column(
      children: [
        _buildSingleBar(label: labelA, value: valA, unit: unitA, fraction: normA, color: const Color(0xFF9E9287)),
        const SizedBox(height: 12),
        _buildSingleBar(label: labelB, value: valB, unit: unitB ?? unitA, fraction: normB, color: const Color(0xFF2D402D)),
      ],
    );
  }

  Widget _buildSingleBar({
    required String label,
    required double value,
    required String unit,
    required double fraction,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5E5248),
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)} $unit',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 10,
            width: double.infinity,
            color: const Color(0xFFEBE6DF),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction,
              child: Container(color: color),
            ),
          ),
        ),
      ],
    );
  }
}
