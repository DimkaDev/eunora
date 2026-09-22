import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui' as ui;
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/analysis/domain/models/analysis_period.dart';
import 'package:eunora/features/analysis/domain/models/trend_detail_args.dart';
import 'package:eunora/features/analysis/services/analysis_engine.dart';

class SeverityTrendCard extends StatefulWidget {
  final List<DailyLog> filteredLogs;
  final int periodDays;
  final int? loggedDaysCount;
  final VoidCallback? onTap;

  const SeverityTrendCard({
    super.key,
    required this.filteredLogs,
    required this.periodDays,
    this.loggedDaysCount,
    this.onTap,
  });

  @override
  State<SeverityTrendCard> createState() => _SeverityTrendCardState();
}

class _SeverityTrendCardState extends State<SeverityTrendCard> {
  int? _selectedTrendDayIndex;
  double? _selectedTrendValue;

  @override
  void didUpdateWidget(covariant SeverityTrendCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.periodDays != widget.periodDays) {
      _selectedTrendDayIndex = null;
      _selectedTrendValue = null;
    }
  }

  void _openTrendDetail() {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }
    final period = widget.periodDays == 7
        ? AnalysisPeriod.days7
        : widget.periodDays == 90
            ? AnalysisPeriod.days90
            : AnalysisPeriod.days30;

    context.push(
      '/trend-detail',
      extra: TrendDetailArgs(
        metric: 'overall_severity',
        period: period,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Map logs by date (midnight) for quick lookup
    final Map<String, double> dailyLoads = {};
    for (final log in widget.filteredLogs) {
      final key = "${log.date.year}-${log.date.month.toString().padLeft(2, '0')}-${log.date.day.toString().padLeft(2, '0')}";
      if (log.symptoms.isNotEmpty) {
        double sumIntensity = 0.0;
        for (final s in log.symptoms) {
          sumIntensity += s.intensity?.toDouble() ??
              (s.severity == 'Mild'
                  ? 1.0
                  : s.severity == 'Moderate'
                      ? 3.0
                      : 5.0);
        }
        dailyLoads[key] = sumIntensity / log.symptoms.length;
      }
    }

    // Build timeline points: Gaps (no-log days) are kept as null
    final DateTime today = DateTime.now();
    final DateTime startDate = today.subtract(Duration(days: widget.periodDays - 1));

    final List<double?> rawPoints = [];
    for (int i = 0; i < widget.periodDays; i++) {
      final d = startDate.add(Duration(days: i));
      final key = "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      rawPoints.add(dailyLoads[key]);
    }

    // Process points according to X-axis density:
    final List<double?> processedPoints = [];
    if (widget.periodDays == 7) {
      processedPoints.addAll(rawPoints);
    } else {
      // 3-day rolling average
      for (int i = 0; i < rawPoints.length; i++) {
        final List<double> window = [];
        for (int offset = -2; offset <= 0; offset++) {
          final idx = i + offset;
          if (idx >= 0 && rawPoints[idx] != null) {
            window.add(rawPoints[idx]!);
          }
        }
        if (window.isNotEmpty) {
          processedPoints.add(window.reduce((a, b) => a + b) / window.length);
        } else {
          processedPoints.add(null);
        }
      }
    }

    // Calculate trend percentage
    final int halfIndex = widget.periodDays ~/ 2;
    final List<double> firstHalf = [];
    final List<double> secondHalf = [];

    for (int i = 0; i < rawPoints.length; i++) {
      final val = rawPoints[i];
      if (val != null) {
        if (i < halfIndex) {
          firstHalf.add(val);
        } else {
          secondHalf.add(val);
        }
      }
    }

    final bool hasData = rawPoints.any((p) => p != null);
    final bool showTrend = hasData && firstHalf.length >= 4 && secondHalf.length >= 4;
    String trendText = hasData ? "Keep logging to see your trend" : "No data available";
    Color trendColor = AppTheme.outline;
    IconData trendIcon = hasData ? Icons.trending_flat : Icons.info_outline;

    if (showTrend) {
      final double avgFirst = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
      final double avgSecond = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

      if (avgFirst > 0.0) {
        final double pct = (avgFirst - avgSecond) / avgFirst * 100;
        if (pct >= 0) {
          trendText = "${pct.toStringAsFixed(0)}% improvement";
          trendColor = const Color(0xFF2E7D32); // Success Green
          trendIcon = Icons.trending_down;
        } else {
          trendText = "${pct.abs().toStringAsFixed(0)}% increase";
          trendColor = const Color(0xFFE8A89B); // Neutral Peachy Rose
          trendIcon = Icons.trending_up;
        }
      }
    }

    final int effectiveLogged = widget.loggedDaysCount ??
        widget.filteredLogs.where((l) => l.isCompleted).length;
    final String coverageCaption = 'Logged $effectiveLogged / ${widget.periodDays} days';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _openTrendDetail,
      child: Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SEVERITY TREND',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      coverageCaption,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(trendIcon, size: 14, color: trendColor),
                    const SizedBox(width: 4),
                    Text(
                      trendText,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: trendColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (!hasData)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.show_chart_rounded,
                          color: AppTheme.outline,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No data recorded for this period',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Log your daily symptoms to see your severity trend.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Dynamic interactive trend painter
              LayoutBuilder(
                builder: (context, constraints) {
                  final double width = constraints.maxWidth;
                  final double stepX = width / (processedPoints.length - 1);

                  return GestureDetector(
                    onPanUpdate: (details) {
                      final double localX = details.localPosition.dx.clamp(0.0, width);
                      final int index = (localX / stepX).round().clamp(0, processedPoints.length - 1);
                      final double? val = processedPoints[index];
                      if (val != null) {
                        setState(() {
                          _selectedTrendDayIndex = index;
                          _selectedTrendValue = val;
                        });
                      }
                    },
                    onTapUp: (details) {
                      final double localX = details.localPosition.dx.clamp(0.0, width);
                      final int index = (localX / stepX).round().clamp(0, processedPoints.length - 1);
                      final double? val = processedPoints[index];
                      if (val != null) {
                        setState(() {
                          _selectedTrendDayIndex = index;
                          _selectedTrendValue = val;
                        });
                      }
                    },
                    child: Column(
                      children: [
                        SizedBox(
                          height: 112,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: DynamicTrendPainter(
                              points: processedPoints,
                              selectedIndex: _selectedTrendDayIndex,
                            ),
                          ),
                        ),
                        if (_selectedTrendDayIndex != null && _selectedTrendValue != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${widget.periodDays - 1 - _selectedTrendDayIndex!} days ago: ${AnalysisEngine.severityLabelForScore(_selectedTrendValue!)} · ${_selectedTrendValue!.toStringAsFixed(1)} / 5',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${widget.periodDays} days ago',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.outline,
                    ),
                  ),
                  Text(
                    'Today',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DynamicTrendPainter extends CustomPainter {
  final List<double?> points;
  final int? selectedIndex;

  DynamicTrendPainter({required this.points, this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, size.height),
        [
          const Color(0xFFEDDDF5).withOpacity(0.8),
          const Color(0xFFEDDDF5).withOpacity(0.0),
        ],
      )
      ..style = PaintingStyle.fill;

    final path = Path();
    final double stepX = size.width / (points.length - 1);

    bool first = true;
    for (int i = 0; i < points.length; i++) {
      final val = points[i];
      if (val != null) {
        // SD-3 0-5 scale
        final double yRatio = val / 5.0;
        final double yPos = size.height - (size.height * yRatio.clamp(0.0, 1.0));
        final double xPos = i * stepX;

        if (first) {
          path.moveTo(xPos, yPos);
          first = false;
        } else {
          path.lineTo(xPos, yPos);
        }
      }
    }

    if (!first) {
      canvas.drawPath(path, paint);

      // Close the path for gradient fill
      final fillPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw selected point indicator
    if (selectedIndex != null &&
        selectedIndex! < points.length &&
        points[selectedIndex!] != null) {
      final val = points[selectedIndex!]!;
      final double yRatio = val / 5.0;
      final double yPos = size.height - (size.height * yRatio.clamp(0.0, 1.0));
      final double xPos = selectedIndex! * stepX;

      final pointPaint = Paint()
        ..color = AppTheme.primary
        ..style = PaintingStyle.fill;

      final outerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(xPos, yPos), 6.0, outerPaint);
      canvas.drawCircle(Offset(xPos, yPos), 4.0, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant DynamicTrendPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.selectedIndex != selectedIndex;
  }
}
