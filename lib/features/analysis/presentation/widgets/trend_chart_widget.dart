import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../domain/models/chart_series.dart';
import '../../domain/models/day_analysis_picture.dart';
import '../../domain/models/hrt_change_result.dart';

/// Interactive chart widget for Trend Detail page.
/// Supports null gaps, optional previous-period ghost line, regimen change vertical markers,
/// and tap-for-day inspector.
class TrendChartWidget extends StatefulWidget {
  final AnalysisChartSeries series;
  final AnalysisChartSeries? previousSeries;
  final bool showGhostLine;
  final List<HrtRegimenGroup> regimenGroups;
  final String metric;
  final double maxY;
  final void Function(DateTime date, AnalysisChartPoint? point)? onPointSelected;

  const TrendChartWidget({
    super.key,
    required this.series,
    this.previousSeries,
    this.showGhostLine = false,
    this.regimenGroups = const [],
    this.metric = 'overall_severity',
    this.maxY = 5.0,
    this.onPointSelected,
  });

  @override
  State<TrendChartWidget> createState() => _TrendChartWidgetState();
}

class _TrendChartWidgetState extends State<TrendChartWidget> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(covariant TrendChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.series != widget.series) {
      _selectedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.series.points;
    if (points.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Text('No chart data available'),
        ),
      );
    }

    final effectiveMaxY = widget.metric == 'sleep' ? 12.0 : 5.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapUp: (details) {
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox == null) return;
                  final localPos = details.localPosition;
                  final chartWidth = constraints.maxWidth - 48; // padding
                  if (chartWidth <= 0 || points.isEmpty) return;

                  final dx = (localPos.dx - 36).clamp(0.0, chartWidth);
                  final step = points.length > 1 ? chartWidth / (points.length - 1) : chartWidth;
                  final index = (dx / step).round().clamp(0, points.length - 1);

                  setState(() {
                    _selectedIndex = index;
                  });

                  final pt = points[index];
                  widget.onPointSelected?.call(pt.date, pt.isGap ? null : pt);
                },
                child: CustomPaint(
                  size: Size(constraints.maxWidth, 220),
                  painter: _TrendChartPainter(
                    points: points,
                    previousPoints: widget.showGhostLine ? widget.previousSeries?.points : null,
                    regimenGroups: widget.regimenGroups,
                    selectedIndex: _selectedIndex,
                    maxY: effectiveMaxY,
                    isSleep: widget.metric == 'sleep',
                    isWeekly: widget.series.isWeekly,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<AnalysisChartPoint> points;
  final List<AnalysisChartPoint>? previousPoints;
  final List<HrtRegimenGroup> regimenGroups;
  final int? selectedIndex;
  final double maxY;
  final bool isSleep;
  final bool isWeekly;

  _TrendChartPainter({
    required this.points,
    this.previousPoints,
    required this.regimenGroups,
    this.selectedIndex,
    required this.maxY,
    required this.isSleep,
    required this.isWeekly,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 36.0;
    const rightPad = 16.0;
    const topPad = 24.0;
    const bottomPad = 32.0;

    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;

    if (chartWidth <= 0 || chartHeight <= 0 || points.isEmpty) return;

    // 1. Draw horizontal grid lines & Y-axis labels
    final gridPaint = Paint()
      ..color = const Color(0xFFE5E0D8)
      ..strokeWidth = 1.0;

    final ySteps = isSleep ? [0.0, 4.0, 6.0, 8.0, 10.0] : [1.0, 3.0, 5.0];
    for (final yVal in ySteps) {
      final yNorm = 1.0 - (yVal / maxY).clamp(0.0, 1.0);
      final y = topPad + yNorm * chartHeight;

      canvas.drawLine(Offset(leftPad, y), Offset(size.width - rightPad, y), gridPaint);

      final label = isSleep ? '${yVal.toInt()}h' : yVal.toInt().toString();
      final textSpan = TextSpan(
        text: label,
        style: GoogleFonts.manrope(
          fontSize: 10,
          color: const Color(0xFF9E9287),
          fontWeight: FontWeight.w600,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(leftPad - textPainter.width - 6, y - 6));
    }

    final n = points.length;
    final stepX = n > 1 ? chartWidth / (n - 1) : chartWidth / 2;

    double getX(int index) => leftPad + index * stepX;
    double getY(double value) {
      final norm = 1.0 - (value / maxY).clamp(0.0, 1.0);
      return topPad + norm * chartHeight;
    }

    // 2. Draw Regimen Change Vertical Dashed Markers
    final markerPaint = Paint()
      ..color = const Color(0xFFC88A75)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final group in regimenGroups) {
      for (int i = 0; i < points.length; i++) {
        final pt = points[i];
        final isSameDate = pt.date.year == group.changeDate.year &&
            pt.date.month == group.changeDate.month &&
            pt.date.day == group.changeDate.day;
        if (isSameDate) {
          final x = getX(i);
          // Draw dashed vertical line
          double startY = topPad;
          const dashLen = 4.0;
          const spaceLen = 3.0;
          while (startY < topPad + chartHeight) {
            canvas.drawLine(
              Offset(x, startY),
              Offset(x, (startY + dashLen).clamp(topPad, topPad + chartHeight)),
              markerPaint,
            );
            startY += dashLen + spaceLen;
          }

          // Small pill badge at top
          final badgePaint = Paint()..color = const Color(0xFFF9EAE1);
          final rect = RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, topPad - 10), width: 28, height: 16),
            const Radius.circular(8),
          );
          canvas.drawRRect(rect, badgePaint);

          final badgePainter = TextPainter(
            text: TextSpan(
              text: '💊',
              style: GoogleFonts.manrope(fontSize: 10),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          badgePainter.paint(canvas, Offset(x - badgePainter.width / 2, topPad - 17));
        }
      }
    }

    // 3. Draw Ghost Line (Previous Period) if provided
    if (previousPoints != null && previousPoints!.isNotEmpty) {
      final ghostPaint = Paint()
        ..color = const Color(0xFF94A3B8).withOpacity(0.4)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      Path? currentGhostPath;
      for (int i = 0; i < previousPoints!.length && i < points.length; i++) {
        final pt = previousPoints![i];
        if (pt.isGap || pt.value == null) {
          currentGhostPath = null;
          continue;
        }

        final x = getX(i);
        final y = getY(pt.value!);

        if (currentGhostPath == null) {
          currentGhostPath = Path()..moveTo(x, y);
        } else {
          currentGhostPath.lineTo(x, y);
        }
        canvas.drawPath(currentGhostPath, ghostPaint);
      }
    }

    // 4. Draw Main Series Line with NULL GAPS PRESERVED
    final linePaint = Paint()
      ..color = const Color(0xFF2D402D)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    Path? currentPath;
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      if (pt.isGap || pt.value == null) {
        // Line breaks cleanly at unlogged gaps!
        currentPath = null;
        continue;
      }

      final x = getX(i);
      final y = getY(pt.value!);

      if (currentPath == null) {
        currentPath = Path()..moveTo(x, y);
      } else {
        currentPath.lineTo(x, y);
      }
      canvas.drawPath(currentPath, linePaint);
    }

    // 5. Draw Data Points
    final dotFillPaint = Paint()..color = Colors.white;
    final dotBorderPaint = Paint()
      ..color = const Color(0xFF2D402D)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final selectedDotPaint = Paint()
      ..color = const Color(0xFFC88A75)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      if (pt.isGap || pt.value == null) continue;

      final x = getX(i);
      final y = getY(pt.value!);

      final isSelected = selectedIndex == i;

      if (isSelected) {
        canvas.drawCircle(Offset(x, y), 6.0, dotFillPaint);
        canvas.drawCircle(Offset(x, y), 6.0, selectedDotPaint);
        canvas.drawCircle(Offset(x, y), 2.5, Paint()..color = const Color(0xFFC88A75));
      } else {
        canvas.drawCircle(Offset(x, y), 3.5, dotFillPaint);
        canvas.drawCircle(Offset(x, y), 3.5, dotBorderPaint);
      }
    }

    // 6. Draw X-axis date labels (sparse)
    final labelInterval = (n / 5).ceil().clamp(1, n);
    for (int i = 0; i < points.length; i += labelInterval) {
      final pt = points[i];
      final x = getX(i);
      final String labelText;
      if (isWeekly) {
        labelText = 'Wk ${DateFormat('MMM d').format(pt.date)}';
      } else {
        labelText = DateFormat('d/M').format(pt.date);
      }

      final textPainter = TextPainter(
        text: TextSpan(
          text: labelText,
          style: GoogleFonts.manrope(
            fontSize: 9,
            color: const Color(0xFF9E9287),
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, Offset(x - textPainter.width / 2, topPad + chartHeight + 8));
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.previousPoints != previousPoints ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.regimenGroups != regimenGroups ||
        oldDelegate.maxY != maxY;
  }
}
