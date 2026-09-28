import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:eunora/features/analysis/analysis.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/home/presentation/pages/calendar_page.dart';
import 'package:eunora/features/home/presentation/widgets/calendar/calendar_insights_banner.dart';
import 'package:eunora/features/home/presentation/widgets/calendar/calendar_patterns_card.dart';
import 'package:eunora/features/home/presentation/widgets/calendar/calendar_weekly_trends_card.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final testDate = DateTime(2026, 9, 20); // Sunday

  DailyLog createTestLog({
    required DateTime date,
    bool isCompleted = true,
    List<LoggedSymptom> symptoms = const [],
    List<String> triggers = const [],
    double sleepDuration = 7.0,
  }) {
    return DailyLog(
      id: date.toIso8601String().substring(0, 10),
      userId: 'user_1',
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
    String? severity = 'Moderate',
  }) {
    return LoggedSymptom(
      symptom: Symptom(id: id, name: name, iconName: 'medical_services'),
      severity: severity,
    );
  }

  group('Task 6: Patterns Card Tests', () {
    testWidgets('renders top 2 displayable patterns with required format', (tester) async {
      const pattern1 = PatternInsight(
        triggerId: 'coffee',
        triggerDisplayName: 'Coffee',
        outcomeId: 'hot_flash',
        outcomeDisplayName: 'Hot Flashes',
        isOverallDayLevel: false,
        lag: PatternLag.lag1,
        type: PatternType.worsening,
        confidence: PatternConfidence.high,
        rawCorrelation: 0.72,
        strength: 0.72,
        correlationPercent: 72,
        effect: 1.5,
        exposedAverage: 3.5,
        unexposedAverage: 2.0,
        eventCount: 8,
        comparisonDaysCount: 15,
        hitRateCount: 7,
        headlineText: '',
        evidenceText: '',
        hitRateText: '',
        disclaimer: '',
        secondaryOutcomes: [],
      );

      const pattern2 = PatternInsight(
        triggerId: 'exercise',
        triggerDisplayName: 'Exercise',
        outcomeId: 'overall_day_level',
        outcomeDisplayName: 'Overall severity',
        isOverallDayLevel: true,
        lag: PatternLag.lag0,
        type: PatternType.protective,
        confidence: PatternConfidence.standard,
        rawCorrelation: -0.45,
        strength: 0.45,
        correlationPercent: 45,
        effect: -1.0,
        exposedAverage: 1.5,
        unexposedAverage: 2.5,
        eventCount: 10,
        comparisonDaysCount: 14,
        hitRateCount: 8,
        headlineText: '',
        evidenceText: '',
        hitRateText: '',
        disclaimer: '',
        secondaryOutcomes: [],
      );

      const pattern3 = PatternInsight(
        triggerId: 'alcohol',
        triggerDisplayName: 'Alcohol',
        outcomeId: 'fatigue',
        outcomeDisplayName: 'Fatigue',
        isOverallDayLevel: false,
        lag: PatternLag.lag1,
        type: PatternType.worsening,
        confidence: PatternConfidence.standard,
        rawCorrelation: 0.35,
        strength: 0.35,
        correlationPercent: 35,
        effect: 0.8,
        exposedAverage: 3.0,
        unexposedAverage: 2.2,
        eventCount: 7,
        comparisonDaysCount: 14,
        hitRateCount: 5,
        headlineText: '',
        evidenceText: '',
        hitRateText: '',
        disclaimer: '',
        secondaryOutcomes: [],
      );

      const result = PatternEngineResult(
        requestedPeriod: AnalysisPeriod.days30,
        effectiveDaysInWindow: 30,
        patterns: [pattern1, pattern2, pattern3],
        buildingItems: [],
        emptyStateType: SD10EmptyType.none,
      );

      bool seeAllTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarPatternsCard(
              patternResult: result,
              onSeeAll: () => seeAllTapped = true,
            ),
          ),
        ),
      );

      // Verify header
      expect(find.text('Patterns'), findsOneWidget);
      expect(find.text('See all'), findsOneWidget);

      // Verify row 1: "Coffee → Hot Flashes next day · 72% · 8 events"
      expect(find.text('Coffee → Hot Flashes next day · 72% · 8 events'), findsOneWidget);

      // Verify row 2: "Exercise → Overall severity same day · 45% · 10 events"
      expect(find.text('Exercise → Overall severity same day · 45% · 10 events'), findsOneWidget);

      // Pattern 3 should be omitted (only top 2 shown)
      expect(find.textContaining('Alcohol'), findsNothing);

      // Tap See all
      await tester.tap(find.text('See all'));
      expect(seeAllTapped, isTrue);
    });

    testWidgets('renders Insufficient data state with progress toward nearest threshold', (tester) async {
      const result = PatternEngineResult(
        requestedPeriod: AnalysisPeriod.days30,
        effectiveDaysInWindow: 10,
        patterns: [],
        buildingItems: [
          BuildingPatternItem(
            triggerId: 'stress',
            triggerDisplayName: 'Stress',
            eventsCount: 5,
            targetCount: 7,
            displayText: 'Stress · 5 of 7 events',
          ),
        ],
        emptyStateType: SD10EmptyType.notEnoughData,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalendarPatternsCard(
              patternResult: result,
            ),
          ),
        ),
      );

      expect(find.text('INSUFFICIENT DATA'), findsOneWidget);
      expect(find.text('Stress · 5 of 7 events'), findsOneWidget);
      expect(find.text('Personal patterns unlock once at least 7 paired events are recorded.'), findsOneWidget);
    });
  });

  group('Task 6: WeeklyTrendsCalculator & Card Tests', () {
    const calc = WeeklyTrendsCalculator();

    test('enforces value minimum (>= 2 logged days) and comparison minimum (>= 3 in both)', () {
      // 1 logged day in current week -> value not shown
      final logsSingleDay = [
        createTestLog(date: DateTime(2026, 9, 14), sleepDuration: 8.0),
      ];

      final res1 = calc.calculate(
        logs: logsSingleDay,
        selectedDate: testDate,
        today: testDate,
      );

      expect(res1.hasEnoughDataForValues, isFalse);
      expect(res1.hasEnoughDataForComparison, isFalse);
      expect(res1.intensityDisplay, '—');
      expect(res1.intensityChangeDisplay, 'Not enough data to compare yet');
      expect(res1.sleepChangeDisplay, 'Not enough data to compare yet');

      // 2 logged days in current week -> value shown, comparison not ready
      final logsTwoDays = [
        createTestLog(
          date: DateTime(2026, 9, 14),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')],
          sleepDuration: 8.0,
        ),
        createTestLog(
          date: DateTime(2026, 9, 15),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')],
          sleepDuration: 7.0,
        ),
      ];

      final res2 = calc.calculate(
        logs: logsTwoDays,
        selectedDate: testDate,
        today: testDate,
      );

      expect(res2.hasEnoughDataForValues, isTrue);
      expect(res2.hasEnoughDataForComparison, isFalse);
      expect(res2.intensityDisplay, contains('Mild · 1.0'));
      expect(res2.sleepDisplay, '7.5 hrs');
      expect(res2.intensityChangeDisplay, 'Not enough data to compare yet');
      expect(res2.sleepChangeDisplay, 'Not enough data to compare yet');

      // 3 logged days in both weeks -> comparison ready!
      final logsBothWeeks = [
        // Prev week: Sep 7, 8, 9 (Mon, Tue, Wed)
        createTestLog(
          date: DateTime(2026, 9, 7),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Severe')],
          sleepDuration: 6.0,
        ),
        createTestLog(
          date: DateTime(2026, 9, 8),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Severe')],
          sleepDuration: 6.0,
        ),
        createTestLog(
          date: DateTime(2026, 9, 9),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Severe')],
          sleepDuration: 6.0,
        ),
        // Current week: Sep 14, 15, 16 (Mon, Tue, Wed)
        createTestLog(
          date: DateTime(2026, 9, 14),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')],
          sleepDuration: 8.0,
        ),
        createTestLog(
          date: DateTime(2026, 9, 15),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')],
          sleepDuration: 8.0,
        ),
        createTestLog(
          date: DateTime(2026, 9, 16),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')],
          sleepDuration: 8.0,
        ),
      ];

      final res3 = calc.calculate(
        logs: logsBothWeeks,
        selectedDate: testDate,
        today: testDate,
      );

      expect(res3.hasEnoughDataForValues, isTrue);
      expect(res3.hasEnoughDataForComparison, isTrue);
      expect(res3.intensityChangeDisplay, contains('↓')); // Improved from 5.0 to 1.0
      expect(res3.sleepChangeDisplay, '+2.0 h'); // Improved from 6.0 to 8.0
    });

    test('preserves null empty slots for unlogged days in 7 mini-bars', () {
      final logs = [
        createTestLog(date: DateTime(2026, 9, 14)), // Monday
        // Tue unlogged
        createTestLog(date: DateTime(2026, 9, 16)), // Wednesday
      ];

      final res = calc.calculate(
        logs: logs,
        selectedDate: testDate,
        today: testDate,
      );

      expect(res.intensityMiniBars.length, 7);
      expect(res.sleepMiniBars.length, 7);

      // Mon (idx 0) has value
      expect(res.intensityMiniBars[0], isNotNull);
      expect(res.sleepMiniBars[0], isNotNull);

      // Tue (idx 1) is null gap
      expect(res.intensityMiniBars[1], isNull);
      expect(res.sleepMiniBars[1], isNull);

      // Wed (idx 2) has value
      expect(res.intensityMiniBars[2], isNotNull);
      expect(res.sleepMiniBars[2], isNotNull);
    });

    test('correctly counts sleep disruption days', () {
      final logs = [
        createTestLog(
          date: DateTime(2026, 9, 14),
          symptoms: [createSymptom(id: 'night_wakings', name: 'Night wakings')],
        ),
        createTestLog(
          date: DateTime(2026, 9, 15),
          symptoms: [createSymptom(id: 'difficulty_falling_asleep', name: 'Difficulty falling asleep')],
        ),
        createTestLog(
          date: DateTime(2026, 9, 16),
          symptoms: [createSymptom(id: 'hot_flash', name: 'Hot flashes')],
        ),
      ];

      final res = calc.calculate(
        logs: logs,
        selectedDate: testDate,
        today: testDate,
      );

      expect(res.sleepDisruptionDays, 2);
    });

    testWidgets('CalendarWeeklyTrendsCard renders metrics, mini-bars, and handles taps', (tester) async {
      bool tappedIntensity = false;
      bool tappedSleep = false;

      final data = WeeklyTrendsData(
        weekStart: DateTime(2026, 9, 14),
        weekEnd: DateTime(2026, 9, 20),
        currentWeekLoggedDays: 4,
        previousWeekLoggedDays: 4,
        hasEnoughDataForValues: true,
        hasEnoughDataForComparison: true,
        averageIntensity: 3.1,
        intensitySeverityLabel: 'Moderate',
        intensityDisplay: 'Moderate · 3.1 / 5',
        intensityChangeDisplay: '↓ 20%',
        isIntensityImproved: true,
        intensityMiniBars: [2.0, null, 3.5, 4.0, null, 3.0, null],
        averageSleepHours: 7.2,
        sleepDisplay: '7.2 hrs',
        sleepChangeHours: 0.4,
        sleepChangeDisplay: '+0.4 h',
        isSleepImproved: true,
        sleepDisruptionDays: 2,
        sleepMiniBars: [7.0, null, 6.5, 8.0, null, 7.5, null],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarWeeklyTrendsCard(
              trendsData: data,
              onTapIntensity: () => tappedIntensity = true,
              onTapSleep: () => tappedSleep = true,
            ),
          ),
        ),
      );

      // Verify titles & values
      expect(find.text('SYMPTOM INTENSITY'), findsOneWidget);
      expect(find.text('Moderate · 3.1 / 5'), findsOneWidget);
      expect(find.text('↓ 20%'), findsOneWidget);

      expect(find.text('SLEEP'), findsOneWidget);
      expect(find.text('7.2 hrs'), findsOneWidget);
      expect(find.text('+0.4 h'), findsOneWidget);
      expect(find.text('Sleep disruption: 2 days'), findsOneWidget);

      // Tap cards
      await tester.tap(find.text('SYMPTOM INTENSITY'));
      expect(tappedIntensity, isTrue);

      await tester.tap(find.text('SLEEP'));
      expect(tappedSleep, isTrue);
    });
  });

  group('Task 6: Personalized Insight Banner Tests', () {
    testWidgets('renders calm observation, reviewed tip, and Section E2 disclaimer', (tester) async {
      const pattern = PatternInsight(
        triggerId: 'coffee',
        triggerDisplayName: 'Coffee',
        outcomeId: 'hot_flash',
        outcomeDisplayName: 'Hot Flashes',
        isOverallDayLevel: false,
        lag: PatternLag.lag1,
        type: PatternType.worsening,
        confidence: PatternConfidence.high,
        rawCorrelation: 0.65,
        strength: 0.65,
        correlationPercent: 65,
        effect: 1.5,
        exposedAverage: 3.5,
        unexposedAverage: 2.0,
        eventCount: 8,
        comparisonDaysCount: 15,
        hitRateCount: 7,
        headlineText: '',
        evidenceText: '',
        hitRateText: '',
        disclaimer: '',
        secondaryOutcomes: [],
      );

      const result = PatternEngineResult(
        requestedPeriod: AnalysisPeriod.days30,
        effectiveDaysInWindow: 15,
        patterns: [pattern],
        buildingItems: [],
        emptyStateType: SD10EmptyType.none,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalendarInsightsBanner(
              patternResult: result,
              loggedDaysCount: 15,
            ),
          ),
        ),
      );

      // Observation text
      expect(
        find.text('In your data, Hot Flashes tends to be stronger the day after when you log Coffee.'),
        findsOneWidget,
      );

      // Reviewed tip for coffee
      expect(
        find.text('Consider experimenting with decaffeinated alternatives or smaller servings to see if symptoms ease.'),
        findsOneWidget,
      );

      // Approved disclaimer
      expect(
        find.text(kApprovedTriggerDisclaimer),
        findsOneWidget,
      );

      // Must NOT contain hours or time of day
      expect(find.textContaining('12 PM'), findsNothing);
      expect(find.textContaining('hours prior'), findsNothing);
      expect(find.textContaining('evening'), findsNothing);
    });

    testWidgets('renders observation without tip when trigger not in reviewed library', (tester) async {
      const pattern = PatternInsight(
        triggerId: 'rare_custom_trigger',
        triggerDisplayName: 'Rare Custom Trigger',
        outcomeId: 'fatigue',
        outcomeDisplayName: 'Fatigue',
        isOverallDayLevel: false,
        lag: PatternLag.lag0,
        type: PatternType.worsening,
        confidence: PatternConfidence.standard,
        rawCorrelation: 0.5,
        strength: 0.5,
        correlationPercent: 50,
        effect: 1.2,
        exposedAverage: 3.0,
        unexposedAverage: 1.8,
        eventCount: 7,
        comparisonDaysCount: 14,
        hitRateCount: 6,
        headlineText: '',
        evidenceText: '',
        hitRateText: '',
        disclaimer: '',
        secondaryOutcomes: [],
      );

      const result = PatternEngineResult(
        requestedPeriod: AnalysisPeriod.days30,
        effectiveDaysInWindow: 15,
        patterns: [pattern],
        buildingItems: [],
        emptyStateType: SD10EmptyType.none,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalendarInsightsBanner(
              patternResult: result,
              loggedDaysCount: 15,
            ),
          ),
        ),
      );

      expect(
        find.text('In your data, Fatigue tends to be stronger on days you log it when you log Rare Custom Trigger.'),
        findsOneWidget,
      );
      expect(find.text(kApprovedTriggerDisclaimer), findsOneWidget);
    });

    testWidgets('renders fallback "Log X more days to unlock personal insights" when no pattern', (tester) async {
      const result = PatternEngineResult(
        requestedPeriod: AnalysisPeriod.days30,
        effectiveDaysInWindow: 8,
        patterns: [],
        buildingItems: [],
        emptyStateType: SD10EmptyType.notEnoughData,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalendarInsightsBanner(
              patternResult: result,
              loggedDaysCount: 8,
            ),
          ),
        ),
      );

      expect(find.text('Log 6 more days to unlock personal insights.'), findsOneWidget);
      expect(find.text(kApprovedTriggerDisclaimer), findsOneWidget);
    });
  });

  group('Task 6: CalendarPage Integration Tests', () {
    testWidgets('renders real analysis sections when customLogs provided', (tester) async {
      final logs = List.generate(14, (i) {
        final date = DateTime(2026, 9, 7 + i);
        return createTestLog(
          date: date,
          symptoms: [createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Moderate')],
          triggers: ['coffee'],
          sleepDuration: 7.5,
        );
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: CalendarPage(
              initialSelectedDate: DateTime(2026, 9, 20),
              customLogs: logs,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Patterns card is present
      expect(find.text('Patterns'), findsOneWidget);

      // Verify Weekly Trends card is present
      expect(find.text('Weekly Trends'), findsOneWidget);
      expect(find.text('SYMPTOM INTENSITY'), findsOneWidget);
      expect(find.text('SLEEP'), findsOneWidget);

      // Verify Personalized Insight is present
      expect(find.text('Personalized Insight'), findsOneWidget);
      expect(find.text(kApprovedTriggerDisclaimer), findsOneWidget);

      // Verify NO fake mock text ("Red wine (evening)") exists
      expect(find.textContaining('Red wine (evening)'), findsNothing);
    });
  });
}
