import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/analysis_period.dart';
import '../../domain/models/chart_series.dart';
import '../../domain/models/day_analysis_picture.dart';
import '../../domain/models/hrt_change_result.dart';
import '../../domain/models/period_comparison.dart';
import '../../domain/models/trend_detail_args.dart';
import '../../domain/models/window_analysis_result.dart';
import '../../services/analysis_engine.dart';
import '../providers/analysis_provider.dart';
import '../providers/hrt_change_provider.dart';
import '../widgets/sleep_analysis_block.dart';
import '../widgets/symptom_detail_sheet.dart';
import '../widgets/symptom_summary_table.dart';
import '../widgets/trend_chart_widget.dart';
import '../widgets/why_you_see_this_card.dart';

class TrendDetailPage extends ConsumerStatefulWidget {
  final TrendDetailArgs args;

  const TrendDetailPage({
    super.key,
    required this.args,
  });

  @override
  ConsumerState<TrendDetailPage> createState() => _TrendDetailPageState();
}

class _TrendDetailPageState extends ConsumerState<TrendDetailPage> {
  late AnalysisPeriod _selectedPeriod;
  late String _selectedMetric;
  bool _showGhostLine = false;
  DateTime? _selectedDate;
  AnalysisChartPoint? _selectedPoint;

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.args.period == AnalysisPeriod.day1
        ? AnalysisPeriod.days7
        : widget.args.period;
    _selectedMetric = widget.args.metric;
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (widget.args.customLogs != null) {
      const engine = AnalysisEngine();
      final current = engine.analyzeWindow(
        logs: widget.args.customLogs!,
        period: _selectedPeriod,
      );
      const hrtResult = HrtAnalysisResult(groups: []);
      content = _buildContent(context, current, hrtResult, isCustom: true);
    } else {
      final analysisAsync = ref.watch(analysisWindowProvider(_selectedPeriod));
      final hrtAsync = ref.watch(hrtAnalysisResultProvider);

      content = analysisAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D402D)),
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Unable to load trend analysis. Please try again.',
              style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF8C7D70)),
            ),
          ),
        ),
        data: (analysis) {
          final hrtResult = hrtAsync.valueOrNull ?? const HrtAnalysisResult(groups: []);
          return _buildContent(context, analysis, hrtResult);
        },
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFEF8F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D402D)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          _getMetricTitle(),
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D402D),
          ),
        ),
        centerTitle: true,
      ),
      body: content,
    );
  }

  String _getMetricTitle() {
    if (_selectedMetric == 'overall_severity') return 'Overall Symptom Severity';
    if (_selectedMetric == 'sleep') return 'Sleep Duration';
    return widget.args.metricDisplayName ?? _selectedMetric.replaceAll('_', ' ').toUpperCase();
  }

  Widget _buildContent(
    BuildContext context,
    WindowAnalysisResult analysis,
    HrtAnalysisResult hrtResult, {
    bool isCustom = false,
  }) {
    // SD-10 Empty state when 0 logs in selected window
    if (analysis.loggedDaysCount == 0) {
      return _buildEmptyState(context);
    }

    // Prepare metric-specific chart series
    final chartSeries = _extractMetricSeries(analysis, _selectedMetric);
    final previousSeries = _extractPreviousPeriodSeries(analysis, _selectedMetric);

    // Selected day picture for tap-for-day inspector
    DayAnalysisPicture? selectedDayPicture;
    if (_selectedDate != null) {
      for (final pic in analysis.dailyPictures) {
        if (pic.date.year == _selectedDate!.year &&
            pic.date.month == _selectedDate!.month &&
            pic.date.day == _selectedDate!.day) {
          selectedDayPicture = pic;
          break;
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Selector Pills
          _buildPeriodSelector(),
          const SizedBox(height: 20),

          // Header: Current Value, SD-4 Comparison, Coverage
          _buildHeaderMetrics(analysis),
          const SizedBox(height: 20),

          // Main Chart with Ghost Line Toggle
          _buildChartContainer(chartSeries, previousSeries, hrtResult),
          const SizedBox(height: 16),

          // Tap-for-Day Inspector Card (if day tapped)
          if (selectedDayPicture != null) ...[
            _buildDayInspectorCard(selectedDayPicture),
            const SizedBox(height: 20),
          ],

          // Why You See This Card (when opened from an insight)
          if (widget.args.insightToExplain != null) ...[
            WhyYouSeeThisCard(
              insight: widget.args.insightToExplain,
              analysis: analysis,
            ),
            const SizedBox(height: 20),
          ],

          // Symptom Summary Table
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Symptom Breakdown',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D402D),
                ),
              ),
              Text(
                '${analysis.symptomRankings.length} tracked',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: const Color(0xFF8C7D70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SymptomSummaryTable(
            symptoms: analysis.symptomRankings,
            totalLoggedDays: analysis.loggedDaysCount,
            onTapSymptom: (symptom) {
              SymptomDetailSheet.show(
                context,
                metric: symptom,
                totalLoggedDays: analysis.loggedDaysCount,
                logs: widget.args.customLogs,
                period: _selectedPeriod,
                onOpenDayInCalendar: (date) {
                  context.push('/calendar', extra: date);
                },
              );
            },
          ),
          const SizedBox(height: 20),

          // Sleep Block (gated by SD-6 sleep trust)
          SleepAnalysisBlock(analysis: analysis),
          const SizedBox(height: 24),

          // Section E2 Approved Disclaimer
          _buildApprovedDisclaimer(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        _buildPeriodPill('7 Days', AnalysisPeriod.days7),
        const SizedBox(width: 8),
        _buildPeriodPill('30 Days', AnalysisPeriod.days30),
        const SizedBox(width: 8),
        _buildPeriodPill('90 Days', AnalysisPeriod.days90),
      ],
    );
  }

  Widget _buildPeriodPill(String label, AnalysisPeriod period) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = period;
            _selectedDate = null;
            _selectedPoint = null;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2D402D) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF2D402D) : const Color(0xFFEBE6DF),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF67594E),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderMetrics(WindowAnalysisResult analysis) {
    String currentDisplay = analysis.severityDisplay ?? '—';
    if (_selectedMetric == 'sleep') {
      currentDisplay = analysis.averageSleepHours != null
          ? '${analysis.averageSleepHours!.toStringAsFixed(1)} hrs'
          : '—';
    }

    final comparison = analysis.severityComparison;
    final meetsMin = comparison?.isEligible ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBE6DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AVERAGE IN PERIOD',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: const Color(0xFF8C7D70),
                ),
              ),
              if (meetsMin && comparison != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: comparison.changeType == MaterialChangeType.improved
                        ? const Color(0xFFE8F0E8)
                        : (comparison.changeType == MaterialChangeType.worsened
                            ? const Color(0xFFFDF5F3)
                            : const Color(0xFFF2EFE9)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    comparison.changeType?.label.toUpperCase() ?? 'STEADY',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: comparison.changeType == MaterialChangeType.improved
                          ? const Color(0xFF2D402D)
                          : (comparison.changeType == MaterialChangeType.worsened
                              ? const Color(0xFFBA1A1A)
                              : const Color(0xFF67594E)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currentDisplay,
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D402D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Based on ${analysis.loggedDaysCount} of ${analysis.calendarDaysInWindow} days',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: const Color(0xFF8C7D70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartContainer(
    AnalysisChartSeries series,
    AnalysisChartSeries? previousSeries,
    HrtAnalysisResult hrtResult,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBE6DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                series.isWeekly ? 'Weekly Trend (Mon–Sun)' : 'Daily Trend',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4A3E36),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ghost line',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: const Color(0xFF8C7D70),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Switch.adaptive(
                    value: _showGhostLine,
                    activeColor: const Color(0xFF2D402D),
                    onChanged: (val) {
                      setState(() => _showGhostLine = val);
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          TrendChartWidget(
            series: series,
            previousSeries: previousSeries,
            showGhostLine: _showGhostLine,
            regimenGroups: hrtResult.groups,
            metric: _selectedMetric,
            onPointSelected: (date, point) {
              setState(() {
                _selectedDate = date;
                _selectedPoint = point;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayInspectorCard(DayAnalysisPicture pic) {
    final dateStr = DateFormat('EEE, MMM d, yyyy').format(pic.date);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0DDD5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D402D),
                ),
              ),
              Text(
                pic.isLogged
                    ? (pic.isSymptomFree
                        ? 'Symptom-free'
                        : 'Score: ${pic.dayLevel?.toStringAsFixed(1) ?? '—'} / 5')
                    : 'Unlogged day',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: pic.isLogged ? const Color(0xFF2D402D) : const Color(0xFF8C7D70),
                ),
              ),
            ],
          ),
          if (pic.isLogged && pic.symptomScores.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: pic.symptomScores.entries.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFEBE6DF)),
                  ),
                  child: Text(
                    '${e.key.replaceAll('_', ' ')}: ${e.value.toStringAsFixed(0)}',
                    style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF4A3E36)),
                  ),
                );
              }).toList(),
            ),
          ],
          if (pic.isLogged && pic.triggers.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Triggers: ${pic.triggers.values.map((t) => t.displayName).join(', ')}',
              style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF8C7D70)),
            ),
          ],
          if (pic.isLogged && pic.sleepHours != null) ...[
            const SizedBox(height: 4),
            Text(
              'Sleep: ${pic.sleepHours!.toStringAsFixed(1)} hrs',
              style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF8C7D70)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📋', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 16),
            Text(
              'No logs recorded for this period.',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4A3E36),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Log your symptoms on the Home tab to build your trend analysis.',
              style: GoogleFonts.manrope(
                fontSize: 13,
                height: 1.5,
                color: const Color(0xFF8C7D70),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_selectedPeriod != AnalysisPeriod.days30) {
                  setState(() => _selectedPeriod = AnalysisPeriod.days30);
                } else {
                  Navigator.of(context).maybePop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D402D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _selectedPeriod != AnalysisPeriod.days30 ? 'Switch to 30 Days' : 'Go Back',
                style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovedDisclaimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EDEA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'This analysis is based on your self-reported data. Changes in symptoms may be due to many factors. '
        'This analysis is not a substitute for clinical assessment by your healthcare provider.',
        style: GoogleFonts.manrope(
          fontSize: 11,
          color: const Color(0xFF67594E),
          height: 1.45,
        ),
      ),
    );
  }

  AnalysisChartSeries _extractMetricSeries(WindowAnalysisResult analysis, String metric) {
    if (metric == 'overall_severity') {
      return analysis.chartSeries;
    }

    if (metric == 'sleep') {
      final points = analysis.dailyPictures.map((pic) {
        return AnalysisChartPoint(
          date: pic.date,
          value: pic.isLogged ? pic.sleepHours : null,
        );
      }).toList();

      return AnalysisChartSeries(
        period: analysis.period,
        points: points,
        isWeekly: false,
        label: 'Sleep Duration',
      );
    }

    // Specific symptom metric
    final points = analysis.dailyPictures.map((pic) {
      if (!pic.isLogged) return AnalysisChartPoint(date: pic.date, value: null);
      final score = pic.symptomScores[metric];
      return AnalysisChartPoint(date: pic.date, value: score ?? 0.0);
    }).toList();

    return AnalysisChartSeries(
      period: analysis.period,
      points: points,
      isWeekly: false,
      label: metric,
    );
  }

  AnalysisChartSeries? _extractPreviousPeriodSeries(WindowAnalysisResult analysis, String metric) {
    final prevPictures = analysis.previousWindowPictures;
    if (prevPictures == null || prevPictures.isEmpty) return null;

    final points = prevPictures.map((pic) {
      return AnalysisChartPoint(
        date: pic.date,
        value: pic.isLogged ? pic.dayLevel : null,
      );
    }).toList();

    return AnalysisChartSeries(
      period: analysis.period,
      points: points,
      isWeekly: analysis.period == AnalysisPeriod.days90,
      label: 'Previous Period',
    );
  }
}
