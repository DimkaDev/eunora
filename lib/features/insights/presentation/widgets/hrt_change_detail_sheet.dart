import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../analysis/domain/models/hrt_change_result.dart';
import '../../../analysis/domain/models/period_comparison.dart';
import '../../../analysis/services/analysis_engine.dart';

/// Modal bottom sheet displaying detailed HRT regimen before/after comparisons:
/// symptom chips (defaulting to the largest change), 29-day daily-score chart with change date divider,
/// dashed before/after averages, gaps for unlogged days, and adherence details.
class HrtChangeDetailSheet extends StatefulWidget {
  final HrtRegimenGroup group;

  const HrtChangeDetailSheet({
    super.key,
    required this.group,
  });

  static Future<void> show(
    BuildContext context, {
    required HrtRegimenGroup group,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => HrtChangeDetailSheet(group: group),
    );
  }

  @override
  State<HrtChangeDetailSheet> createState() => _HrtChangeDetailSheetState();
}

class _HrtChangeDetailSheetState extends State<HrtChangeDetailSheet> {
  late String _selectedSymptomId;

  @override
  void initState() {
    super.initState();
    // Default to the symptom with the largest absolute burden change
    if (widget.group.symptomResults.isNotEmpty) {
      final sorted = List<HrtSymptomChangeResult>.from(widget.group.symptomResults)
        ..sort((a, b) {
          final deltaA = (a.burdenAfter - a.burdenBefore).abs();
          final deltaB = (b.burdenAfter - b.burdenBefore).abs();
          return deltaB.compareTo(deltaA);
        });
      _selectedSymptomId = sorted.first.symptomId;
    } else {
      _selectedSymptomId = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final changeDateStr = DateFormat('MMM d, yyyy').format(group.changeDate);

    HrtSymptomChangeResult? selectedResult;
    for (final r in group.symptomResults) {
      if (r.symptomId == _selectedSymptomId) {
        selectedResult = r;
        break;
      }
    }
    selectedResult ??=
        group.symptomResults.isNotEmpty ? group.symptomResults.first : null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
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
                      group.summaryTitle,
                      style: GoogleFonts.notoSerif(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D402D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Change date: $changeDateStr · ${group.statusMessage}',
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
                  // Symptom chips selection
                  if (group.symptomResults.isNotEmpty) ...[
                    Text(
                      'SYMPTOMS EVALUATED',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: const Color(0xFF8C7D70),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: group.symptomResults.map((s) {
                          final isSelected = s.symptomId == _selectedSymptomId;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(s.symptomDisplayName),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedSymptomId = s.symptomId;
                                });
                              },
                              selectedColor: const Color(0xFF2D402D),
                              labelStyle: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF5D534A),
                              ),
                              backgroundColor: const Color(0xFFF2EFE9),
                              checkmarkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (selectedResult != null) ...[
                    // Daily score chart
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${selectedResult.symptomDisplayName} Daily Scores',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2D402D),
                                ),
                              ),
                              _buildChangeBadge(selectedResult.comparison),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '14 days before vs 14 days after (change date excluded)',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: const Color(0xFF8C7D70),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Custom Painter Chart
                          SizedBox(
                            height: 160,
                            width: double.infinity,
                            child: CustomPaint(
                              painter: _HrtBeforeAfterChartPainter(
                                changeDate: group.changeDate,
                                dailyScores: selectedResult.dailyScores,
                                beforeAverage: selectedResult.burdenBefore,
                                afterAverage: selectedResult.burdenAfter,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Chart Legend
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLegendItem(
                                color: const Color(0xFF8C7D70),
                                isDashed: true,
                                label: 'Before Avg: ${selectedResult.burdenBefore.toStringAsFixed(1)}',
                              ),
                              const SizedBox(width: 16),
                              _buildLegendItem(
                                color: const Color(0xFF2D402D),
                                isDivider: true,
                                label: 'Change Day',
                              ),
                              const SizedBox(width: 16),
                              _buildLegendItem(
                                color: const Color(0xFF4A7C59),
                                isDashed: true,
                                label: 'After Avg: ${selectedResult.burdenAfter.toStringAsFixed(1)}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Metrics Comparison Table
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEBE6DF)),
                      ),
                      child: Column(
                        children: [
                          _buildMetricRow(
                            'Presence in window',
                            '${selectedResult.daysPresentBefore} of ${selectedResult.loggedDaysBefore} days',
                            '${selectedResult.daysPresentAfter} of ${selectedResult.loggedDaysAfter} days',
                          ),
                          const Divider(height: 20, color: Color(0xFFF0ECE6)),
                          _buildMetricRow(
                            'Average severity (present)',
                            selectedResult.averageSeverityBefore != null
                                ? '${AnalysisEngine.severityLabelForScore(selectedResult.averageSeverityBefore!)} (${selectedResult.averageSeverityBefore!.toStringAsFixed(1)})'
                                : '—',
                            selectedResult.averageSeverityAfter != null
                                ? '${AnalysisEngine.severityLabelForScore(selectedResult.averageSeverityAfter!)} (${selectedResult.averageSeverityAfter!.toStringAsFixed(1)})'
                                : '—',
                          ),
                          const Divider(height: 20, color: Color(0xFFF0ECE6)),
                          _buildMetricRow(
                            'Daily symptom burden',
                            selectedResult.burdenBefore.toStringAsFixed(1),
                            selectedResult.burdenAfter.toStringAsFixed(1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F7F4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Comparison becomes available once 14 days of follow-up logs have accumulated.',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: const Color(0xFF67594E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Adherence section if available
                  if (group.adherence != null) ...[
                    Text(
                      'REGIMEN ADHERENCE',
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.adherence!.adherenceText,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2D402D),
                            ),
                          ),
                          if (group.adherence!.needsGentleNote &&
                              group.adherence!.gentleNote != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              group.adherence!.gentleNote!,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: const Color(0xFF8C7D70),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Overlapping notes if any
                  if (group.overlappingNotes.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF6EE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF5E3CE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: group.overlappingNotes.map((note) {
                          return Text(
                            'Note: $note',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: const Color(0xFF8A5A2B),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Disclaimer
                  Text(
                    group.disclaimer,
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

  Widget _buildChangeBadge(MetricComparison comparison) {
    Color bg;
    Color fg;
    String label;

    switch (comparison.changeType) {
      case MaterialChangeType.improved:
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        label = 'Improved';
        break;
      case MaterialChangeType.worsened:
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        label = 'Worsened';
        break;
      case MaterialChangeType.steady:
        bg = const Color(0xFFF2EFE9);
        fg = const Color(0xFF67594E);
        label = 'Steady';
        break;
      case MaterialChangeType.newOccurrence:
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
        label = 'New';
        break;
      case MaterialChangeType.cleared:
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        label = 'Cleared';
        break;
      case null:
        bg = const Color(0xFFF2EFE9);
        fg = const Color(0xFF67594E);
        label = 'Steady';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildMetricRow(String title, String before, String after) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: const Color(0xFF67594E),
            ),
          ),
        ),
        Expanded(
          child: Text(
            before,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D402D),
            ),
          ),
        ),
        Expanded(
          child: Text(
            after,
            textAlign: TextAlign.right,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D402D),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    bool isDashed = false,
    bool isDivider = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF67594E),
          ),
        ),
      ],
    );
  }
}

/// Custom painter rendering the 29-day before/after daily score series:
/// 14 days before, change date vertical divider, 14 days after.
/// Dashed lines for before and after averages, continuous lines connecting logged days with gaps for unlogged days.
class _HrtBeforeAfterChartPainter extends CustomPainter {
  final DateTime changeDate;
  final Map<DateTime, double?> dailyScores;
  final double beforeAverage;
  final double afterAverage;

  _HrtBeforeAfterChartPainter({
    required this.changeDate,
    required this.dailyScores,
    required this.beforeAverage,
    required this.afterAverage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Total 29 slots: 14 before (indices 0..13), changeDate (index 14), 14 after (indices 15..28)
    const int totalSlots = 29;
    final double slotWidth = w / (totalSlots - 1);

    // Coordinate mapping: Y maps 0..5 onto (h - 20) .. 10
    final double chartTop = 10.0;
    final double chartBottom = h - 20.0;
    final double chartHeight = chartBottom - chartTop;

    double yForScore(double score) {
      final ratio = (score / 5.0).clamp(0.0, 1.0);
      return chartBottom - (ratio * chartHeight);
    }

    // Grid lines: 0, 1, 3, 5
    final gridPaint = Paint()
      ..color = const Color(0xFFEAE5DE)
      ..strokeWidth = 1.0;

    for (final score in [0.0, 1.0, 3.0, 5.0]) {
      final y = yForScore(score);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Divider line on change date (slot 14)
    final double dividerX = 14 * slotWidth;
    final dividerPaint = Paint()
      ..color = const Color(0xFF5D534A)
      ..strokeWidth = 1.5;

    // Draw vertical dashed line for divider
    double curY = chartTop;
    while (curY < chartBottom) {
      canvas.drawLine(
        Offset(dividerX, curY),
        Offset(dividerX, (curY + 4).clamp(chartTop, chartBottom)),
        dividerPaint,
      );
      curY += 8;
    }

    // Dashed before average line (from slot 0 to slot 13)
    final beforeAvgY = yForScore(beforeAverage);
    final beforeAvgPaint = Paint()
      ..color = const Color(0xFF8C7D70)
      ..strokeWidth = 1.2;
    double bx = 0;
    while (bx < dividerX) {
      canvas.drawLine(
        Offset(bx, beforeAvgY),
        Offset((bx + 4).clamp(0, dividerX), beforeAvgY),
        beforeAvgPaint,
      );
      bx += 8;
    }

    // Dashed after average line (from slot 15 to slot 28)
    final afterAvgY = yForScore(afterAverage);
    final afterAvgPaint = Paint()
      ..color = const Color(0xFF4A7C59)
      ..strokeWidth = 1.2;
    double ax = dividerX + slotWidth;
    while (ax < w) {
      canvas.drawLine(
        Offset(ax, afterAvgY),
        Offset((ax + 4).clamp(dividerX, w), afterAvgY),
        afterAvgPaint,
      );
      ax += 8;
    }

    // Collect 29 points
    final List<Offset?> points = [];
    final normChange = AnalysisEngine.normalizeDate(changeDate);

    for (int i = 0; i < totalSlots; i++) {
      final int offsetDays = i - 14;
      final date = AnalysisEngine.addDays(normChange, offsetDays);
      final double? score = dailyScores[date];
      final double x = i * slotWidth;

      if (score != null) {
        points.add(Offset(x, yForScore(score)));
      } else {
        points.add(null); // Unlogged gap
      }
    }

    // Draw line segments with gaps for null
    final linePaint = Paint()
      ..color = const Color(0xFF2D402D)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = const Color(0xFF2D402D)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      if (pt == null) continue;

      // Draw dot
      canvas.drawCircle(pt, 3.0, dotPaint);

      // Connect to next point if not null and adjacent
      if (i + 1 < points.length && points[i + 1] != null) {
        // Only connect if not crossing the change date directly without data
        canvas.drawLine(pt, points[i + 1]!, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HrtBeforeAfterChartPainter oldDelegate) {
    return oldDelegate.changeDate != changeDate ||
        oldDelegate.beforeAverage != beforeAverage ||
        oldDelegate.afterAverage != afterAverage ||
        oldDelegate.dailyScores != dailyScores;
  }
}
