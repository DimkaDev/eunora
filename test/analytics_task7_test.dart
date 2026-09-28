import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eunora/features/analysis/domain/models/analysis_period.dart';
import 'package:eunora/features/analysis/domain/models/hrt_change_result.dart';
import 'package:eunora/features/analysis/domain/models/pattern_result.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/onboarding/domain/models/medication.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';
import 'package:eunora/features/home/presentation/pages/analytics_page.dart';
import 'package:eunora/features/home/presentation/widgets/analytics/what_affects_you_card.dart';
import 'package:eunora/features/home/presentation/widgets/analytics/ai_correlations_hrt_card.dart';
import 'package:eunora/features/home/presentation/widgets/analytics/most_frequent_symptoms_card.dart';
import 'package:eunora/features/home/presentation/widgets/analytics/severity_trend_card.dart';
import 'package:eunora/features/analysis/presentation/widgets/symptom_detail_sheet.dart';

void main() {
  group('Task 7: WhatAffectsYouCard Tests', () {
    testWidgets('shows <= 3 items, none from HRT, with correct chips and window label', (tester) async {
      const pattern1 = PatternInsight(
        triggerId: 'coffee',
        triggerDisplayName: 'Coffee',
        outcomeId: 'hot_flashes',
        outcomeDisplayName: 'Hot Flashes',
        isOverallDayLevel: false,
        lag: PatternLag.lag1,
        type: PatternType.worsening,
        confidence: PatternConfidence.high,
        rawCorrelation: 0.72,
        strength: 0.72,
        correlationPercent: 72,
        effect: 1.5,
        exposedAverage: 3.8,
        unexposedAverage: 2.3,
        eventCount: 14,
        comparisonDaysCount: 16,
        hitRateCount: 10,
        headlineText: '',
        evidenceText: '',
        hitRateText: '',
        disclaimer: '',
        secondaryOutcomes: [],
      );

      const pattern2 = PatternInsight(
        triggerId: 'exercise',
        triggerDisplayName: 'Exercise',
        outcomeId: 'hot_flashes',
        outcomeDisplayName: 'Hot Flashes',
        isOverallDayLevel: false,
        lag: PatternLag.lag0,
        type: PatternType.protective,
        confidence: PatternConfidence.standard,
        rawCorrelation: -0.45,
        strength: 0.45,
        correlationPercent: 45,
        effect: -1.0,
        exposedAverage: 2.0,
        unexposedAverage: 3.0,
        eventCount: 8,
        comparisonDaysCount: 12,
        hitRateCount: 6,
        headlineText: '',
        evidenceText: '',
        hitRateText: '',
        disclaimer: '',
        secondaryOutcomes: [],
      );

      const pattern3 = PatternInsight(
        triggerId: 'hot_weather',
        triggerDisplayName: 'Hot Weather',
        outcomeId: 'night_sweats',
        outcomeDisplayName: 'Night Sweats',
        isOverallDayLevel: false,
        lag: PatternLag.lag0,
        type: PatternType.worsening,
        confidence: PatternConfidence.standard,
        rawCorrelation: 0.50,
        strength: 0.50,
        correlationPercent: 50,
        effect: 1.2,
        exposedAverage: 3.5,
        unexposedAverage: 2.3,
        eventCount: 7,
        comparisonDaysCount: 10,
        hitRateCount: 5,
        headlineText: '',
        evidenceText: '',
        hitRateText: '',
        disclaimer: '',
        secondaryOutcomes: [],
      );

      const pattern4 = PatternInsight(
        triggerId: 'alcohol',
        triggerDisplayName: 'Alcohol',
        outcomeId: 'headache',
        outcomeDisplayName: 'Headache',
        isOverallDayLevel: false,
        lag: PatternLag.lag1,
        type: PatternType.worsening,
        confidence: PatternConfidence.standard,
        rawCorrelation: 0.35,
        strength: 0.35,
        correlationPercent: 35,
        effect: 0.8,
        exposedAverage: 2.8,
        unexposedAverage: 2.0,
        eventCount: 7,
        comparisonDaysCount: 10,
        hitRateCount: 5,
        headlineText: '',
        evidenceText: '',
        hitRateText: '',
        disclaimer: '',
        secondaryOutcomes: [],
      );

      const result = PatternEngineResult(
        requestedPeriod: AnalysisPeriod.days7,
        effectiveDaysInWindow: 30,
        patterns: [pattern1, pattern2, pattern3, pattern4],
        buildingItems: [],
        emptyStateType: SD10EmptyType.none,
      );

      bool seeAllTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WhatAffectsYouCard(
              patternResult: result,
              selectedPeriod: AnalysisPeriod.days7,
              onSeeAllEffects: () => seeAllTapped = true,
            ),
          ),
        ),
      );

      // Verify header & window notice
      expect(find.text('WHAT AFFECTS YOU?'), findsOneWidget);
      expect(find.text('Based on last 30 days'), findsOneWidget);
      expect(find.text('See all effects'), findsOneWidget);

      // Verify top 3 items
      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('Exercise'), findsOneWidget);
      expect(find.text('Hot Weather'), findsOneWidget);

      // 4th item (Alcohol) omitted because max 3
      expect(find.text('Alcohol'), findsNothing);

      // Verify chips
      expect(find.text('Trigger'), findsOneWidget);
      expect(find.text('Protective'), findsOneWidget);
      expect(find.text('Environment'), findsOneWidget);
      expect(find.text('High confidence'), findsOneWidget); // Only pattern1 has high confidence

      // Tap See all effects
      await tester.tap(find.text('See all effects'));
      expect(seeAllTapped, isTrue);
    });

    testWidgets('renders SD-10 progress toward nearest threshold when no patterns displayable', (tester) async {
      const result = PatternEngineResult(
        requestedPeriod: AnalysisPeriod.days30,
        effectiveDaysInWindow: 30,
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
            body: WhatAffectsYouCard(
              patternResult: result,
              selectedPeriod: AnalysisPeriod.days30,
            ),
          ),
        ),
      );

      expect(find.text('WHAT AFFECTS YOU?'), findsOneWidget);
      expect(find.text('INSUFFICIENT DATA'), findsOneWidget);
      expect(find.text('Stress · 5 of 7 events'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('suppresses sleep pattern when sleep trust fails per SD-6', (tester) async {
      const sleepPattern = PatternInsight(
        triggerId: 'poor_sleep',
        triggerDisplayName: 'Poor Sleep',
        outcomeId: 'fatigue',
        outcomeDisplayName: 'Fatigue',
        isOverallDayLevel: false,
        lag: PatternLag.lag0,
        type: PatternType.worsening,
        confidence: PatternConfidence.standard,
        rawCorrelation: 0.55,
        strength: 0.55,
        correlationPercent: 55,
        effect: 1.5,
        exposedAverage: 3.5,
        unexposedAverage: 2.0,
        eventCount: 8,
        comparisonDaysCount: 10,
        hitRateCount: 6,
        headlineText: '',
        evidenceText: '',
        hitRateText: '',
        disclaimer: '',
        secondaryOutcomes: [],
      );

      const result = PatternEngineResult(
        requestedPeriod: AnalysisPeriod.days30,
        effectiveDaysInWindow: 30,
        patterns: [sleepPattern],
        buildingItems: [],
        emptyStateType: SD10EmptyType.none,
      );

      // When sleep trust is false
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WhatAffectsYouCard(
              patternResult: result,
              selectedPeriod: AnalysisPeriod.days30,
              isSleepTrusted: false,
            ),
          ),
        ),
      );

      // Sleep pattern should be suppressed
      expect(find.text('Poor Sleep'), findsNothing);
    });
  });

  group('Task 7: AiCorrelationsHrtCard Tests', () {
    testWidgets('renders strongest pattern and HRT status when HRT is set up', (tester) async {
      const pattern = PatternInsight(
        triggerId: 'coffee',
        triggerDisplayName: 'Coffee',
        outcomeId: 'hot_flashes',
        outcomeDisplayName: 'Hot Flashes',
        isOverallDayLevel: false,
        lag: PatternLag.lag1,
        type: PatternType.worsening,
        confidence: PatternConfidence.high,
        rawCorrelation: 0.72,
        strength: 0.72,
        correlationPercent: 72,
        effect: 1.5,
        exposedAverage: 3.8,
        unexposedAverage: 2.3,
        eventCount: 8,
        comparisonDaysCount: 16,
        hitRateCount: 7,
        headlineText: '',
        evidenceText: '',
        hitRateText: '',
        disclaimer: '',
        secondaryOutcomes: [],
      );

      const patternResult = PatternEngineResult(
        requestedPeriod: AnalysisPeriod.days30,
        effectiveDaysInWindow: 30,
        patterns: [pattern],
        buildingItems: [],
        emptyStateType: SD10EmptyType.none,
      );

      final hrtGroup = HrtRegimenGroup(
        changeDate: DateTime(2026, 9, 13),
        events: const [],
        summaryTitle: 'Regimen changed on Sep 13: Estradiol dose ↑',
        headlineText: 'Regimen changed on Sep 13: Estradiol dose ↑',
        status: HrtChangeStatus.ready,
        statusMessage: 'Ready for before/after comparison',
        daysSinceChange: 14,
        beforeWindowLoggedDays: 8,
        afterWindowLoggedDays: 8,
      );

      final hrtResult = HrtAnalysisResult(groups: [hrtGroup]);

      bool seeAllTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiCorrelationsHrtCard(
              patternResult: patternResult,
              hrtResult: hrtResult,
              isHrtSetUp: true,
              onSeeAllInsights: () => seeAllTapped = true,
            ),
          ),
        ),
      );

      // Verify Header
      expect(find.text('AI CORRELATIONS & HRT IMPACT'), findsOneWidget);
      expect(find.text('See all insights'), findsOneWidget);

      // Verify Line 1 (strongest pattern)
      expect(find.text('STRONGEST PATTERN'), findsOneWidget);
      expect(find.textContaining('Coffee → Hot Flashes the day after · 72% · 8 events'), findsOneWidget);
      expect(find.text('High confidence'), findsOneWidget);

      // Verify Line 2 (HRT status)
      expect(find.text('LATEST HRT STATUS'), findsOneWidget);
      expect(find.text('Regimen changed on Sep 13: Estradiol dose ↑'), findsOneWidget);

      // Tap See all insights
      await tester.tap(find.text('See all insights'));
      expect(seeAllTapped, isTrue);
    });

    testWidgets('hides HRT line completely when HRT is NOT set up', (tester) async {
      const pattern = PatternInsight(
        triggerId: 'coffee',
        triggerDisplayName: 'Coffee',
        outcomeId: 'hot_flashes',
        outcomeDisplayName: 'Hot Flashes',
        isOverallDayLevel: false,
        lag: PatternLag.lag1,
        type: PatternType.worsening,
        confidence: PatternConfidence.standard,
        rawCorrelation: 0.50,
        strength: 0.50,
        correlationPercent: 50,
        effect: 1.0,
        exposedAverage: 3.0,
        unexposedAverage: 2.0,
        eventCount: 7,
        comparisonDaysCount: 14,
        hitRateCount: 6,
        headlineText: '',
        evidenceText: '',
        hitRateText: '',
        disclaimer: '',
        secondaryOutcomes: [],
      );

      const patternResult = PatternEngineResult(
        requestedPeriod: AnalysisPeriod.days30,
        effectiveDaysInWindow: 30,
        patterns: [pattern],
        buildingItems: [],
        emptyStateType: SD10EmptyType.none,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiCorrelationsHrtCard(
              patternResult: patternResult,
              isHrtSetUp: false, // NOT SET UP
            ),
          ),
        ),
      );

      expect(find.text('AI CORRELATIONS & HRT IMPACT'), findsOneWidget);
      expect(find.text('STRONGEST PATTERN'), findsOneWidget);
      expect(find.text('LATEST HRT STATUS'), findsNothing);
      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('renders SD-10 building progress in Line 1 when no patterns ready', (tester) async {
      const patternResult = PatternEngineResult(
        requestedPeriod: AnalysisPeriod.days30,
        effectiveDaysInWindow: 30,
        patterns: [],
        buildingItems: [
          BuildingPatternItem(
            triggerId: 'coffee',
            triggerDisplayName: 'Coffee',
            eventsCount: 4,
            targetCount: 7,
            displayText: 'Coffee · 4 of 7 events',
          ),
        ],
        emptyStateType: SD10EmptyType.notEnoughData,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiCorrelationsHrtCard(
              patternResult: patternResult,
              isHrtSetUp: false,
            ),
          ),
        ),
      );

      expect(find.text('PATTERN STATUS'), findsOneWidget);
      expect(find.text('Coffee · 4 of 7 events'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders pending HRT status progress in Line 2', (tester) async {
      const patternResult = PatternEngineResult(
        requestedPeriod: AnalysisPeriod.days30,
        effectiveDaysInWindow: 30,
        patterns: [],
        buildingItems: [],
        emptyStateType: SD10EmptyType.notEnoughData,
      );

      final hrtGroup = HrtRegimenGroup(
        changeDate: DateTime.now().subtract(const Duration(days: 5)),
        events: const [],
        summaryTitle: 'Started Estradiol',
        status: HrtChangeStatus.pending,
        statusMessage: 'Comparison ready in 9 days',
        daysSinceChange: 5,
        daysToGo: 9,
        beforeWindowLoggedDays: 7,
        afterWindowLoggedDays: 3,
      );

      final hrtResult = HrtAnalysisResult(groups: [hrtGroup]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiCorrelationsHrtCard(
              patternResult: patternResult,
              hrtResult: hrtResult,
              isHrtSetUp: true,
            ),
          ),
        ),
      );

      expect(find.text('LATEST HRT STATUS'), findsOneWidget);
      expect(find.text('Day 5 of 14 since regimen changed'), findsOneWidget);
      expect(find.text('Comparison ready in 9 days.'), findsOneWidget);
    });
  });

  group('Task 7: MostFrequentSymptomsCard & SeverityTrendCard Tests', () {
    testWidgets('MostFrequentSymptomsCard shows SD-3 scale and coverage caption, opens modal on tap', (tester) async {
      final symptomLog = DailyLog(
        id: '2026-09-10',
        userId: 'user1',
        date: DateTime.now().subtract(const Duration(days: 1)),
        symptoms: [
          LoggedSymptom(
            symptom: const Symptom(id: 'hot_flashes', name: 'Hot Flashes', iconName: 'local_fire_department', category: 'Vasomotor'),
            severity: 'Severe',
            intensity: 4,
          ),
        ],
        isCompleted: true,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MostFrequentSymptomsCard(
              filteredLogs: [symptomLog],
              periodDays: 30,
              loggedDaysCount: 18,
            ),
          ),
        ),
      );

      // Verify header & coverage caption
      expect(find.text('MOST FREQUENT SYMPTOMS'), findsOneWidget);
      expect(find.text('Logged 18 / 30 days'), findsOneWidget);

      // Verify SD-3 label and score
      expect(find.text('Hot Flashes'), findsOneWidget);
      expect(find.text('Severe · 4.0 / 5'), findsOneWidget);
      expect(find.text('1 day'), findsOneWidget);

      // Tap symptom row opens SymptomDetailSheet
      await tester.tap(find.text('Hot Flashes'));
      await tester.pumpAndSettle();

      expect(find.byType(SymptomDetailSheet), findsOneWidget);
    });

    testWidgets('SeverityTrendCard shows coverage caption and invokes tap callback', (tester) async {
      final symptomLog = DailyLog(
        id: '2026-09-10',
        userId: 'user1',
        date: DateTime.now().subtract(const Duration(days: 1)),
        symptoms: [
          LoggedSymptom(
            symptom: const Symptom(id: 'hot_flashes', name: 'Hot Flashes', iconName: 'local_fire_department', category: 'Vasomotor'),
            severity: 'Severe',
            intensity: 4,
          ),
        ],
        isCompleted: true,
        createdAt: DateTime.now(),
      );

      bool trendTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeverityTrendCard(
              filteredLogs: [symptomLog],
              periodDays: 30,
              loggedDaysCount: 18,
              onTap: () => trendTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('SEVERITY TREND'), findsOneWidget);
      expect(find.text('Logged 18 / 30 days'), findsOneWidget);

      await tester.tap(find.text('SEVERITY TREND'));
      expect(trendTapped, isTrue);
    });
  });

  group('Task 7: AnalyticsPage Integration Tests', () {
    testWidgets('AnalyticsPage renders all sections with customLogs and customMeds', (tester) async {
      final now = DateTime.now();
      final logs = List.generate(14, (i) {
        final d = now.subtract(Duration(days: 13 - i));
        return DailyLog(
          id: 'log_$i',
          userId: 'user1',
          date: d,
          isCompleted: true,
          createdAt: d,
          triggers: i.isEven ? ['coffee'] : ['exercise'],
          symptoms: [
            LoggedSymptom(
              symptom: const Symptom(id: 'hot_flashes', name: 'Hot Flashes', iconName: 'local_fire_department', category: 'Vasomotor'),
              severity: i.isEven ? 'Severe' : 'Mild',
              intensity: i.isEven ? 4 : 1,
            ),
          ],
        );
      });

      final med = Medication(
        id: 'med_estradiol',
        name: 'Estradiol',
        type: MedicationType.patch,
        dose: 50.0,
        unit: 'mcg',
        frequency: 'Daily',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AnalyticsPage(
              customLogs: logs,
              customMeds: [med],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Page Title
      expect(find.text('Your Insights'), findsOneWidget);

      // Section 2 & 3: Coverage caption in both Most Frequent Symptoms and Severity Trend
      expect(find.text('MOST FREQUENT SYMPTOMS'), findsOneWidget);
      expect(find.text('Logged 14 / 30 days'), findsNWidgets(2));

      // Section 3: Severity Trend
      expect(find.text('SEVERITY TREND'), findsOneWidget);

      // Section 4: What Affects You?
      expect(find.text('WHAT AFFECTS YOU?'), findsOneWidget);

      // Section 5b: AI Correlations & HRT Impact
      expect(find.text('AI CORRELATIONS & HRT IMPACT'), findsOneWidget);
      expect(find.text('LATEST HRT STATUS'), findsOneWidget);

      // Tap 7 days in PeriodSelectorWidget
      await tester.tap(find.text('7 days'));
      await tester.pumpAndSettle();

      // Most Frequent Symptoms & Severity Trend should now both display 7 days caption
      expect(find.text('Logged 7 / 7 days'), findsNWidgets(2));

      // What Affects You? displays "Based on last 30 days" notice because selected is 7 days
      expect(find.text('Based on last 30 days'), findsOneWidget);

      // HRT status is invariant across period switching
      expect(find.text('LATEST HRT STATUS'), findsOneWidget);
    });
  });
}
