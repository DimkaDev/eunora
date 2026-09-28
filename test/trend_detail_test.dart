import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/features/analysis/analysis.dart';
import 'package:eunora/features/analysis/presentation/widgets/sleep_analysis_block.dart';
import 'package:eunora/features/analysis/presentation/widgets/symptom_detail_sheet.dart';
import 'package:eunora/features/analysis/presentation/widgets/symptom_summary_table.dart';
import 'package:eunora/features/analysis/presentation/widgets/trend_chart_widget.dart';
import 'package:eunora/features/analysis/presentation/widgets/why_you_see_this_card.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';

void main() {
  const engine = AnalysisEngine();
  final refDate = DateTime(2026, 9, 20);

  DailyLog createLog({
    required DateTime date,
    bool isCompleted = true,
    List<LoggedSymptom> symptoms = const [],
    List<String> triggers = const [],
    double sleepDuration = 7.0,
  }) {
    return DailyLog(
      id: date.toIso8601String().substring(0, 10),
      userId: 'test_user',
      date: date,
      isCompleted: isCompleted,
      symptoms: symptoms,
      triggers: triggers,
      sleepDuration: sleepDuration,
      createdAt: date,
    );
  }

  LoggedSymptom createSymptom({
    required String id,
    required String name,
    String? severity,
  }) {
    return LoggedSymptom(
      symptom: Symptom(id: id, name: name, iconName: 'medical_services'),
      severity: severity,
    );
  }

  group('Task 5: TrendDetailArgs & Entry', () {
    test('initializes with default metric and period', () {
      const args = TrendDetailArgs();
      expect(args.metric, 'overall_severity');
      expect(args.period, AnalysisPeriod.days30);
      expect(args.insightToExplain, isNull);
    });

    test('copyWith updates metric, period, and insight', () {
      const initial = TrendDetailArgs(metric: 'hot_flash', period: AnalysisPeriod.days7);
      final updated = initial.copyWith(
        period: AnalysisPeriod.days90,
        insightToExplain: const HomeInsightCardData(
          title: 'Daily Insight',
          tag: HomeInsightTag.positiveTrend,
          headline: 'Great job!',
          averageSeverityDisplay: 'Mild · 1.5 / 5',
          consistencyPercent: 100,
          targetMetric: 'overall_severity',
          targetPeriod: AnalysisPeriod.days30,
          evidenceSummary: 'summary',
          candidateType: 'D-2',
          subjectKey: 'd2_lighter',
        ),
      );

      expect(updated.metric, 'hot_flash');
      expect(updated.period, AnalysisPeriod.days90);
      expect(updated.insightToExplain?.candidateType, 'D-2');
    });
  });

  group('Task 5: Main Chart Series & Gaps', () {
    test('preserves null gaps for unlogged days on 7-day and 30-day periods', () {
      final logs = [
        createLog(
          date: DateTime(2026, 9, 14),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')],
        ),
        // Sep 15 is unlogged -> GAP
        createLog(
          date: DateTime(2026, 9, 16),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Moderate')],
        ),
      ];

      final analysis = engine.analyzeWindow(
        logs: logs,
        period: AnalysisPeriod.days7,
        today: DateTime(2026, 9, 20),
      );

      final series = analysis.chartSeries;
      expect(series.isWeekly, isFalse);
      expect(series.points.length, 7);

      // Point for Sep 14 should have value 1.0
      final pt14 = series.points.firstWhere((p) => p.date.day == 14);
      expect(pt14.isGap, isFalse);
      expect(pt14.value, 1.0);

      // Point for Sep 15 should be a gap (null)
      final pt15 = series.points.firstWhere((p) => p.date.day == 15);
      expect(pt15.isGap, isTrue);
      expect(pt15.value, isNull);
    });

    test('aggregates by Monday-based weeks in 90-day view', () {
      final logs = [
        createLog(
          date: DateTime(2026, 9, 14), // Monday
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')],
        ),
        createLog(
          date: DateTime(2026, 9, 15), // Tuesday
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Moderate')],
        ),
      ];

      final analysis = engine.analyzeWindow(
        logs: logs,
        period: AnalysisPeriod.days90,
        today: refDate,
      );

      final series = analysis.chartSeries;
      expect(series.isWeekly, isTrue);
      expect(series.points.isNotEmpty, isTrue);

      // Points must fall on Mondays
      for (final pt in series.points) {
        expect(pt.date.weekday, DateTime.monday);
      }
    });
  });

  group('Task 5: Widgets Rendering', () {
    testWidgets('WhyYouSeeThisCard renders insight explanation and comparison bars', (tester) async {
      const insight = HomeInsightCardData(
        title: 'Weekly Insight',
        tag: HomeInsightTag.positiveTrend,
        headline: 'Your average symptom severity improved 40% compared with the previous 7 days (2.1 vs 3.5).',
        averageSeverityDisplay: 'Mild · 2.1 / 5',
        consistencyPercent: 100,
        targetMetric: 'overall_severity',
        targetPeriod: AnalysisPeriod.days7,
        evidenceSummary: 'improved 40%',
        candidateType: 'W-1',
        subjectKey: 'w1_change',
        keyNumber: 40.0,
      );

      final comparison = MetricComparison.evaluate(
        current: 2.1,
        previous: 3.5,
      );

      final analysis = WindowAnalysisResult(
        period: AnalysisPeriod.days7,
        windowStart: DateTime(2026, 9, 14),
        windowEnd: DateTime(2026, 9, 20),
        calendarDaysInWindow: 7,
        loggedDaysCount: 7,
        symptomFreeDaysCount: 0,
        coverage: 1.0,
        consistency: 1.0,
        isHistoryClamped: false,
        severityComparison: comparison,
        symptomRankings: [],
        symptomsMap: {},
        chartSeries: const AnalysisChartSeries(points: [], isWeekly: false),
        isSleepTrusted: true,
        identicalSleepPercent: 0.0,
        dailyPictures: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WhyYouSeeThisCard(
              insight: insight,
              analysis: analysis,
            ),
          ),
        ),
      );

      expect(find.text('Why you see this'), findsOneWidget);
      expect(find.text(insight.headline), findsOneWidget);
      expect(find.text('Previous window'), findsOneWidget);
      expect(find.text('Current window'), findsOneWidget);
    });

    testWidgets('SymptomSummaryTable renders symptom rows and tapping opens sheet', (tester) async {
      const metric = SymptomAnalysisMetric(
        symptomId: 'hot_flash',
        displayName: 'Hot Flashes',
        category: 'Vasomotor',
        daysPresent: 14,
        dayRate: 0.7,
        burden: 2.1,
        averageSeverity: 3.0,
        severityLabel: 'Moderate',
      );

      SymptomAnalysisMetric? tappedMetric;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomSummaryTable(
              symptoms: const [metric],
              totalLoggedDays: 20,
              onTapSymptom: (s) => tappedMetric = s,
            ),
          ),
        ),
      );

      expect(find.text('Hot Flashes'), findsOneWidget);
      expect(find.text('14/20'), findsOneWidget);
      expect(find.text('Moderate · 3.0'), findsOneWidget);

      await tester.tap(find.text('Hot Flashes'));
      await tester.pumpAndSettle();

      expect(tappedMetric?.symptomId, 'hot_flash');
    });

    testWidgets('SleepAnalysisBlock shows paused notice when sleep trust gate fails', (tester) async {
      final untrustedAnalysis = WindowAnalysisResult(
        period: AnalysisPeriod.days30,
        windowStart: DateTime(2026, 8, 22),
        windowEnd: DateTime(2026, 9, 20),
        calendarDaysInWindow: 30,
        loggedDaysCount: 15,
        symptomFreeDaysCount: 0,
        coverage: 0.5,
        consistency: 0.5,
        isHistoryClamped: false,
        symptomRankings: [],
        symptomsMap: {},
        chartSeries: const AnalysisChartSeries(points: [], isWeekly: false),
        isSleepTrusted: false, // <= SD-6 GATE FAILS (>= 70% identical)
        identicalSleepPercent: 0.85,
        dailyPictures: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SleepAnalysisBlock(analysis: untrustedAnalysis),
          ),
        ),
      );

      expect(find.text('Sleep Data Insights Paused'), findsOneWidget);
      expect(
        find.text('Sleep data looks unchanged across logs — insights are paused until more variation is recorded.'),
        findsOneWidget,
      );
    });

    testWidgets('SleepAnalysisBlock shows average sleep when sleep trust gate passes', (tester) async {
      final trustedAnalysis = WindowAnalysisResult(
        period: AnalysisPeriod.days30,
        windowStart: DateTime(2026, 8, 22),
        windowEnd: DateTime(2026, 9, 20),
        calendarDaysInWindow: 30,
        loggedDaysCount: 15,
        symptomFreeDaysCount: 0,
        coverage: 0.5,
        consistency: 0.5,
        isHistoryClamped: false,
        symptomRankings: [],
        symptomsMap: {},
        chartSeries: const AnalysisChartSeries(points: [], isWeekly: false),
        isSleepTrusted: true, // <= SD-6 GATE PASSES
        averageSleepHours: 7.2,
        identicalSleepPercent: 0.3,
        dailyPictures: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SleepAnalysisBlock(analysis: trustedAnalysis),
          ),
        ),
      );

      expect(find.text('Sleep Pattern'), findsOneWidget);
      expect(find.text('7.2 hrs avg'), findsOneWidget);
    });

    testWidgets('TrendDetailPage displays SD-10 empty state when 0 logs in period', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TrendDetailPage(
              args: TrendDetailArgs(
                metric: 'overall_severity',
                period: AnalysisPeriod.days7,
                customLogs: [], // Empty logs!
              ),
            ),
          ),
        ),
      );

      expect(find.text('No logs recorded for this period.'), findsOneWidget);
      expect(find.text('Switch to 30 Days'), findsOneWidget);
    });

    testWidgets('TrendDetailPage renders full header, chart, and disclaimer when data exists', (tester) async {
      final logs = List.generate(10, (i) {
        return createLog(
          date: DateTime(2026, 9, 11 + i),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Moderate')],
        );
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: TrendDetailPage(
              args: TrendDetailArgs(
                metric: 'overall_severity',
                period: AnalysisPeriod.days7,
                customLogs: logs,
              ),
            ),
          ),
        ),
      );

      // Verify header
      expect(find.text('AVERAGE IN PERIOD'), findsOneWidget);
      // Verify chart
      expect(find.byType(TrendChartWidget), findsOneWidget);
      // Verify disclaimer
      expect(
        find.text(
          'This analysis is based on your self-reported data. Changes in symptoms may be due to many factors. '
          'This analysis is not a substitute for clinical assessment by your healthcare provider.',
        ),
        findsOneWidget,
      );
    });
  });
}
