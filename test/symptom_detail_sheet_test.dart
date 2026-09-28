import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eunora/features/analysis/analysis.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';
import 'package:eunora/features/home/presentation/widgets/analytics/most_frequent_symptoms_card.dart';
import 'package:eunora/features/home/presentation/pages/calendar_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task 9: SymptomDetailSheet Unit & Widget Tests', () {
    testWidgets('Quick Stats renders exact "{X} days" wording, never "times", with SD-3 and SD-4', (tester) async {
      final metric = SymptomAnalysisMetric(
        symptomId: 'hot_flashes',
        displayName: 'Hot Flashes',
        category: 'Vasomotor',
        daysPresent: 12,
        dayRate: 12 / 20,
        averageSeverity: 3.1,
        severityLabel: 'Moderate',
        burden: 1.86,
        comparison: const MetricComparison(
          status: ComparisonStatus.eligible,
          currentValue: 3.1,
          previousValue: 2.3,
          delta: 0.8,
          changeType: MaterialChangeType.worsened,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomDetailSheet(
              metric: metric,
              totalLoggedDays: 20,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Quick Stats: "{X} days" wording strictly used
      expect(find.text('12 days'), findsOneWidget);
      expect(find.textContaining('times'), findsNothing);

      // Average severity with label and "/ 5"
      expect(find.text('Moderate · 3.1 / 5'), findsOneWidget);

      // SD-4 trend badge
      expect(find.text('Worsened (+0.8)'), findsOneWidget);
    });

    testWidgets('Physician note is shown ONLY when worsened per SD-4 AND totalLoggedDays >= 14', (tester) async {
      final worsenedMetric = SymptomAnalysisMetric(
        symptomId: 'hot_flashes',
        displayName: 'Hot Flashes',
        category: 'Vasomotor',
        daysPresent: 10,
        dayRate: 0.7,
        averageSeverity: 4.0,
        severityLabel: 'Severe',
        burden: 2.8,
        comparison: const MetricComparison(
          status: ComparisonStatus.eligible,
          currentValue: 4.0,
          previousValue: 3.0,
          delta: 1.0,
          changeType: MaterialChangeType.worsened,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomDetailSheet(
              metric: worsenedMetric,
              totalLoggedDays: 14,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Physician note visible with approved wording
      expect(find.text('NOTE FOR YOUR PHYSICIAN'), findsOneWidget);
      expect(
        find.text('This trend may be worth mentioning at your next appointment'),
        findsOneWidget,
      );
      // Strictly never "we recommend"
      expect(find.textContaining('we recommend'), findsNothing);
      expect(find.text('Open Health Passport'), findsOneWidget);
    });

    testWidgets('Physician note is HIDDEN when improved or when totalLoggedDays < 14', (tester) async {
      final improvedMetric = SymptomAnalysisMetric(
        symptomId: 'hot_flashes',
        displayName: 'Hot Flashes',
        category: 'Vasomotor',
        daysPresent: 10,
        dayRate: 0.7,
        averageSeverity: 2.0,
        severityLabel: 'Mild',
        burden: 1.4,
        comparison: const MetricComparison(
          status: ComparisonStatus.eligible,
          currentValue: 2.0,
          previousValue: 3.5,
          delta: -1.5,
          changeType: MaterialChangeType.improved,
        ),
      );

      // Case 1: Improved but totalLoggedDays = 20 -> Hidden
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomDetailSheet(
              metric: improvedMetric,
              totalLoggedDays: 20,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NOTE FOR YOUR PHYSICIAN'), findsNothing);
      expect(find.text('This trend may be worth mentioning at your next appointment'), findsNothing);

      // Case 2: Worsened but totalLoggedDays < 14 (e.g. 10 days) -> Hidden
      final worsenedFewDays = SymptomAnalysisMetric(
        symptomId: 'hot_flashes',
        displayName: 'Hot Flashes',
        category: 'Vasomotor',
        daysPresent: 8,
        dayRate: 0.8,
        averageSeverity: 4.0,
        severityLabel: 'Severe',
        burden: 3.2,
        comparison: const MetricComparison(
          status: ComparisonStatus.eligible,
          currentValue: 4.0,
          previousValue: 3.0,
          delta: 1.0,
          changeType: MaterialChangeType.worsened,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomDetailSheet(
              metric: worsenedFewDays,
              totalLoggedDays: 10,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NOTE FOR YOUR PHYSICIAN'), findsNothing);
    });

    testWidgets('Strongest pattern displays correlation %, event count, and approved disclaimer', (tester) async {
      final metric = SymptomAnalysisMetric(
        symptomId: 's_hot_flashes',
        displayName: 'Hot Flashes',
        category: 'Vasomotor',
        daysPresent: 15,
        dayRate: 0.5,
        averageSeverity: 3.0,
        severityLabel: 'Moderate',
        burden: 1.5,
      );

      const pattern = PatternInsight(
        triggerId: 'stress',
        triggerDisplayName: 'Stress',
        outcomeId: 's_hot_flashes',
        outcomeDisplayName: 'Hot Flashes',
        isOverallDayLevel: false,
        lag: PatternLag.lag0,
        type: PatternType.worsening,
        confidence: PatternConfidence.high,
        rawCorrelation: 0.65,
        strength: 0.65,
        correlationPercent: 65,
        effect: 1.4,
        exposedAverage: 4.2,
        unexposedAverage: 2.8,
        eventCount: 12,
        comparisonDaysCount: 18,
        hitRateCount: 9,
        headlineText: 'Stress → Hot Flashes on days you log it',
        evidenceText: 'Average 4.2 vs 2.8 on other days',
        hitRateText: 'Hot Flashes were higher on 9 of 12 stress days',
        disclaimer: kApprovedTriggerDisclaimer,
        secondaryOutcomes: [],
        eventDays: [],
      );

      const patternResult = PatternEngineResult(
        requestedPeriod: AnalysisPeriod.days30,
        effectiveDaysInWindow: 30,
        patterns: [pattern],
        buildingItems: [],
        emptyStateType: SD10EmptyType.none,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomDetailSheet(
              metric: metric,
              totalLoggedDays: 30,
              patternResult: patternResult,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Stress → Hot Flashes on days you log it'), findsOneWidget);
      expect(find.text('65% correlation · 12 events'), findsOneWidget);
      expect(find.text('High confidence'), findsOneWidget);
      expect(find.text(kApprovedTriggerDisclaimer), findsOneWidget);
    });

    testWidgets('Day-of-Week pattern fallback renders when >= 4 weeks, >= 3 weekday logs, >= 0.5 higher', (tester) async {
      final metric = SymptomAnalysisMetric(
        symptomId: 's_hot_flashes',
        displayName: 'Hot Flashes',
        category: 'Vasomotor',
        daysPresent: 10,
        dayRate: 0.35,
        averageSeverity: 3.5,
        severityLabel: 'Moderate',
        burden: 1.2,
      );

      // Create 35 days of logs spanning 5 weeks
      // Make Mondays (weekday 1) have score 5.0, other days have score 1.0
      final List<DailyLog> logs = [];
      final baseDate = DateTime(2026, 8, 1);
      for (int i = 0; i < 35; i++) {
        final date = baseDate.add(Duration(days: i));
        final isMonday = date.weekday == DateTime.monday;
        logs.add(
          DailyLog(
            id: 'log_$i',
            userId: 'u1',
            date: date,
            isCompleted: true,
            createdAt: date,
            symptoms: [
              LoggedSymptom(
                symptom: const Symptom(id: 's_hot_flashes', name: 'Hot Flashes', iconName: 'local_fire_department'),
                severity: isMonday ? 'Severe' : 'Mild',
                intensity: isMonday ? 5 : 1,
              ),
            ],
          ),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomDetailSheet(
              metric: metric,
              totalLoggedDays: 35,
              logs: logs,
              period: AnalysisPeriod.days30,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Day-of-Week Pattern'), findsOneWidget);
      expect(find.text('Higher on Mondays'), findsOneWidget);
      expect(find.textContaining('tends to be higher on Mondays'), findsOneWidget);

      // Strictly NO time-of-day phrases
      expect(find.textContaining('morning'), findsNothing);
      expect(find.textContaining('evening'), findsNothing);
      expect(find.textContaining('night'), findsNothing);
    });

    testWidgets('SD-10 state renders when no patterns or weekday patterns meet criteria', (tester) async {
      final metric = SymptomAnalysisMetric(
        symptomId: 's_fatigue',
        displayName: 'Fatigue',
        category: 'Energy',
        daysPresent: 3,
        dayRate: 0.3,
        averageSeverity: 2.0,
        severityLabel: 'Mild',
        burden: 0.6,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomDetailSheet(
              metric: metric,
              totalLoggedDays: 10,
              logs: const [],
              period: AnalysisPeriod.days30,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Keep logging to discover patterns'), findsOneWidget);
      expect(find.textContaining('We need more data to identify reliable patterns'), findsOneWidget);
    });

    testWidgets('Recent history displays duration where recorded, triggers, "Open in calendar", and strictly NO clock times', (tester) async {
      final metric = SymptomAnalysisMetric(
        symptomId: 's_hot_flashes',
        displayName: 'Hot Flashes',
        category: 'Vasomotor',
        daysPresent: 2,
        dayRate: 0.5,
        averageSeverity: 4.0,
        severityLabel: 'Severe',
        burden: 2.0,
      );

      DateTime? openedDate;
      final logs = [
        DailyLog(
          id: 'log_1',
          userId: 'u1',
          date: DateTime(2026, 9, 15),
          isCompleted: true,
          createdAt: DateTime(2026, 9, 15, 14, 30), // clock time exists in createdAt but must NOT be displayed
          triggers: ['Stress', 'Caffeine'],
          symptoms: [
            LoggedSymptom(
              symptom: const Symptom(id: 's_hot_flashes', name: 'Hot Flashes', iconName: 'local_fire_department'),
              severity: 'Severe',
              intensity: 5,
              durationMinutes: 25,
            ),
          ],
        ),
        DailyLog(
          id: 'log_2',
          userId: 'u1',
          date: DateTime(2026, 9, 12),
          isCompleted: true,
          createdAt: DateTime(2026, 9, 12, 9, 15),
          triggers: ['Alcohol'],
          symptoms: [
            LoggedSymptom(
              symptom: const Symptom(id: 's_hot_flashes', name: 'Hot Flashes', iconName: 'local_fire_department'),
              severity: 'Moderate',
              intensity: 3,
              durationMinutes: 10,
            ),
          ],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomDetailSheet(
              metric: metric,
              totalLoggedDays: 2,
              logs: logs,
              onOpenDayInCalendar: (date) {
                openedDate = date;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Recent history entries
      expect(find.text('RECENT HISTORY'), findsOneWidget);
      expect(find.text('Tue, Sep 15'), findsOneWidget);
      expect(find.text('25 min'), findsOneWidget);
      expect(find.text('Stress'), findsOneWidget);
      expect(find.text('Caffeine'), findsOneWidget);

      expect(find.text('Sat, Sep 12'), findsOneWidget);
      expect(find.text('10 min'), findsOneWidget);
      expect(find.text('Alcohol'), findsOneWidget);

      // Strictly NO clock times anywhere (e.g. "14:30", "9:15", "AM", "PM")
      expect(find.textContaining('14:30'), findsNothing);
      expect(find.textContaining('9:15'), findsNothing);
      expect(find.textContaining('AM'), findsNothing);
      expect(find.textContaining('PM'), findsNothing);

      // Strictly NO edit or delete buttons
      expect(find.text('Delete'), findsNothing);
      expect(find.text('Edit'), findsNothing);

      // "Open in calendar" action
      final openButtons = find.text('Open in calendar');
      expect(openButtons, findsNWidgets(2));
      await tester.tap(openButtons.first);
      await tester.pumpAndSettle();

      expect(openedDate, DateTime(2026, 9, 15));
    });

    testWidgets('Entry Point 1: MostFrequentSymptomsCard row tap opens SymptomDetailSheet', (tester) async {
      final log = DailyLog(
        id: '2026-09-10',
        userId: 'u1',
        date: DateTime(2026, 9, 10),
        isCompleted: true,
        createdAt: DateTime(2026, 9, 10),
        symptoms: [
          LoggedSymptom(
            symptom: const Symptom(id: 's_hot_flashes', name: 'Hot Flashes', iconName: 'local_fire_department'),
            severity: 'Moderate',
            intensity: 3,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MostFrequentSymptomsCard(
              filteredLogs: [log],
              periodDays: 30,
              loggedDaysCount: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hot Flashes'), findsOneWidget);
      await tester.tap(find.text('Hot Flashes'));
      await tester.pumpAndSettle();

      expect(find.byType(SymptomDetailSheet), findsOneWidget);
      expect(find.text('1 days'), findsOneWidget);
    });

    testWidgets('Entry Point 2: SymptomSummaryTable row tap opens SymptomDetailSheet', (tester) async {
      final metric = SymptomAnalysisMetric(
        symptomId: 's_anxiety',
        displayName: 'Anxiety',
        category: 'Mood',
        daysPresent: 5,
        dayRate: 0.25,
        averageSeverity: 2.8,
        severityLabel: 'Moderate',
        burden: 0.7,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomSummaryTable(
              symptoms: [metric],
              totalLoggedDays: 20,
              onTapSymptom: (s) {
                SymptomDetailSheet.show(
                  tester.element(find.byType(SymptomSummaryTable)),
                  metric: s,
                  totalLoggedDays: 20,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Anxiety'), findsOneWidget);
      await tester.tap(find.text('Anxiety'));
      await tester.pumpAndSettle();

      expect(find.byType(SymptomDetailSheet), findsOneWidget);
      expect(find.text('5 days'), findsOneWidget);
    });

    testWidgets('Entry Point 3: CalendarPage symptom chip tap opens SymptomDetailSheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CalendarPage(
                initialSelectedDate: DateTime(2026, 4, 7),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the symptom chip in day details
      final chip = find.text('Hot flashes · 2/5');
      expect(chip, findsOneWidget);

      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();

      await tester.tap(chip);
      await tester.pumpAndSettle();

      // SymptomDetailSheet opened
      expect(find.byType(SymptomDetailSheet), findsOneWidget);
      expect(find.text('Hot flashes'), findsWidgets);
    });
  });
}
