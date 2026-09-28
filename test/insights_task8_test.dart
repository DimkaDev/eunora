import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eunora/features/analysis/domain/models/analysis_period.dart';
import 'package:eunora/features/analysis/domain/models/hrt_change_result.dart';
import 'package:eunora/features/analysis/domain/models/pattern_result.dart';
import 'package:eunora/features/analysis/domain/models/period_comparison.dart';
import 'package:eunora/features/onboarding/domain/models/medication.dart';
import 'package:eunora/features/insights/presentation/pages/insights_screen.dart';
import 'package:eunora/features/insights/presentation/widgets/insights_hero_card.dart';
import 'package:eunora/features/insights/presentation/widgets/pattern_card.dart';
import 'package:eunora/features/insights/presentation/widgets/pattern_detail_sheet.dart';
import 'package:eunora/features/insights/presentation/widgets/building_patterns_section.dart';
import 'package:eunora/features/insights/presentation/widgets/hrt_impact_section.dart';
import 'package:eunora/features/insights/presentation/widgets/hrt_change_detail_sheet.dart';
import 'package:eunora/features/insights/presentation/widgets/calculation_methods_sheet.dart';

void main() {
  final pattern1 = PatternInsight(
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
    headlineText: 'Coffee → Hot Flashes tends to be stronger the day after.',
    evidenceText: 'Average 3.8 vs 2.3 on other days · 72% correlation · 14 events',
    hitRateText: 'You logged Coffee on 14 days. Hot Flashes was higher than usual 10 of those times.',
    disclaimer: kApprovedTriggerDisclaimer,
    eventDays: [
      PatternEventDay(
        date: DateTime(2026, 9, 10),
        outcomeScore: 4.0,
        isLagged: true,
      ),
      PatternEventDay(
        date: DateTime(2026, 9, 12),
        outcomeScore: 3.5,
        isLagged: true,
      ),
    ],
  );

  final pattern2 = const PatternInsight(
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
    headlineText: 'Exercise → Hot Flashes tends to be milder on days you log it.',
    evidenceText: 'Average 2.0 vs 3.0 on other days · 45% correlation · 8 events',
    hitRateText: 'You logged Exercise on 8 days. Hot Flashes was lower than usual 6 of those times.',
    disclaimer: kApprovedTriggerDisclaimer,
  );

  final pattern3 = const PatternInsight(
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
    headlineText: 'Hot Weather → Night Sweats tends to be stronger on the same day.',
    evidenceText: 'Average 3.5 vs 2.3 on other days · 50% correlation · 7 events',
    hitRateText: 'You logged Hot Weather on 7 days. Night Sweats was higher than usual 5 of those times.',
    disclaimer: kApprovedTriggerDisclaimer,
  );

  group('Task 8: Hero Card & Methodology Sheet Tests', () {
    testWidgets('InsightsHeroCard renders pattern count, window label, and visible disclaimer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InsightsHeroCard(
              patternsCount: 3,
              windowNotice: 'Based on last 30 days',
            ),
          ),
        ),
      );

      expect(find.text('3 patterns identified'), findsOneWidget);
      expect(find.text('Based on last 30 days'), findsOneWidget);
      expect(find.text(kApprovedTriggerDisclaimer), findsOneWidget);
      expect(find.text('How are these calculated?'), findsOneWidget);
    });

    testWidgets('InsightsHeroCard renders SD-10 empty states when patternsCount is 0', (tester) async {
      // (a) Not enough data
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InsightsHeroCard(
              patternsCount: 0,
              emptyStateType: SD10EmptyType.notEnoughData,
              nearestBuildingItem: BuildingPatternItem(
                triggerId: 'stress',
                triggerDisplayName: 'Stress',
                eventsCount: 5,
                targetCount: 7,
                displayText: 'Stress · 5 of 7 events',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Building your patterns'), findsOneWidget);
      expect(find.text('Stress · 5 of 7 events'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text(kApprovedTriggerDisclaimer), findsOneWidget);

      // (b) Not enough variety
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InsightsHeroCard(
              patternsCount: 0,
              emptyStateType: SD10EmptyType.notEnoughVariety,
              emptyStateMessage: 'We need a few days without Coffee to compare.',
            ),
          ),
        ),
      );

      expect(find.text('More variety needed'), findsOneWidget);
      expect(find.text('We need a few days without Coffee to compare.'), findsOneWidget);

      // (c) Nothing notable
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InsightsHeroCard(
              patternsCount: 0,
              emptyStateType: SD10EmptyType.nothingNotable,
              emptyStateMessage: 'No clear patterns yet — we keep checking as you log.',
            ),
          ),
        ),
      );

      expect(find.text('No strong patterns yet'), findsOneWidget);
      expect(find.text('No clear patterns yet — we keep checking as you log.'), findsOneWidget);
    });

    testWidgets('Tapping How are these calculated? opens CalculationMethodsSheet', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InsightsHeroCard(
              patternsCount: 2,
            ),
          ),
        ),
      );

      await tester.tap(find.text('How are these calculated?'));
      await tester.pumpAndSettle();

      expect(find.byType(CalculationMethodsSheet), findsOneWidget);
      expect(find.text('How Are Insights Calculated?'), findsOneWidget);
      expect(find.text('What is an event?'), findsOneWidget);
      expect(find.text('The analysis window'), findsOneWidget);
      expect(find.text('Personal correlation strength'), findsOneWidget);
      expect(find.text('The 7-event minimum'), findsOneWidget);
      expect(find.text('30% display threshold'), findsOneWidget);
      expect(find.text('Exploratory insights'), findsOneWidget);
      expect(find.text('Correlation is not causation'), findsOneWidget);
    });
  });

  group('Task 8: PatternCard & PatternDetailSheet Tests', () {
    testWidgets('PatternCard renders trigger, chips, effect, hit-rate, stats, and visible disclaimer', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PatternCard(
              pattern: pattern1,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('Trigger'), findsOneWidget);
      expect(find.text('High confidence'), findsOneWidget);
      expect(find.text('Coffee → Hot Flashes tends to be stronger the day after.'), findsOneWidget);
      expect(find.text('You logged Coffee on 14 days. Hot Flashes was higher than usual 10 of those times.'), findsOneWidget);
      expect(find.text('72% correlation · 14 events'), findsOneWidget);
      // Visible disclaimer on card itself without tapping
      expect(find.text(kApprovedTriggerDisclaimer), findsOneWidget);

      await tester.tap(find.byType(PatternCard));
      expect(tapped, isTrue);
    });

    testWidgets('PatternCard correctly applies Environment and Protective chips', (tester) async {
      // Protective chip
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PatternCard(pattern: pattern2),
          ),
        ),
      );
      expect(find.text('Protective'), findsOneWidget);
      expect(find.text('High confidence'), findsNothing); // standard confidence

      // Environment chip
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PatternCard(pattern: pattern3),
          ),
        ),
      );
      expect(find.text('Environment'), findsOneWidget);
    });

    testWidgets('PatternDetailSheet displays comparative bars, event days, and method note', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => PatternDetailSheet.show(context, pattern: pattern1),
                child: const Text('Open Detail'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Detail'));
      await tester.pumpAndSettle();

      expect(find.byType(PatternDetailSheet), findsOneWidget);
      expect(find.text('Coffee → Hot Flashes'), findsOneWidget);
      expect(find.text('AVERAGE OUTCOME COMPARISON'), findsOneWidget);
      // Comparative bars text
      expect(find.text('On days after Coffee'), findsOneWidget);
      expect(find.text('Moderate · 3.8 / 5'), findsOneWidget);
      expect(find.text('Other days'), findsOneWidget);
      expect(find.text('Moderate · 2.3 / 5'), findsOneWidget);

      // Event days list
      expect(find.text('RECORDED EVENT DAYS'), findsOneWidget);
      expect(find.text('Thu, Sep 10'), findsOneWidget);
      expect(find.text('Sat, Sep 12'), findsOneWidget);
      expect(find.text('+1d lag'), findsNWidgets(2));

      // Method note
      expect(find.text('METHOD NOTE'), findsOneWidget);
      expect(find.textContaining('Evaluated across 14 exposed days and 16 comparison days'), findsOneWidget);
    });
  });

  group('Task 8: BuildingPatternsSection Tests', () {
    testWidgets('BuildingPatternsSection renders up to 3 items with progress', (tester) async {
      final items = [
        const BuildingPatternItem(
          triggerId: 'stress',
          triggerDisplayName: 'Stress',
          eventsCount: 5,
          targetCount: 7,
          displayText: 'Stress · 5 of 7 events',
        ),
        const BuildingPatternItem(
          triggerId: 'alcohol',
          triggerDisplayName: 'Alcohol',
          eventsCount: 4,
          targetCount: 7,
          displayText: 'Alcohol · 4 of 7 events',
        ),
        const BuildingPatternItem(
          triggerId: 'sugar',
          triggerDisplayName: 'Sugar',
          eventsCount: 2,
          targetCount: 7,
          displayText: 'Sugar · 2 of 7 events',
        ),
        const BuildingPatternItem(
          triggerId: 'spicy',
          triggerDisplayName: 'Spicy Food',
          eventsCount: 1,
          targetCount: 7,
          displayText: 'Spicy Food · 1 of 7 events',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BuildingPatternsSection(items: items),
          ),
        ),
      );

      expect(find.text('BUILDING PATTERNS'), findsOneWidget);
      expect(find.text('Stress · 5 of 7 events'), findsOneWidget);
      expect(find.text('Alcohol · 4 of 7 events'), findsOneWidget);
      expect(find.text('Sugar · 2 of 7 events'), findsOneWidget);
      // 4th item omitted (capped at 3)
      expect(find.text('Spicy Food · 1 of 7 events'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
    });
  });

  group('Task 8: HrtImpactSection & HrtChangeDetailSheet Tests', () {
    final group1 = HrtRegimenGroup(
      changeDate: DateTime(2026, 9, 13),
      events: const [],
      summaryTitle: 'Regimen changed on Sep 13: Estradiol dose ↑',
      headlineText: 'Regimen changed on Sep 13: Estradiol dose ↑',
      status: HrtChangeStatus.ready,
      statusMessage: 'Ready for before/after comparison',
      daysSinceChange: 14,
      overlappingNotes: const ['Overlaps with Progesterone change on Sep 18'],
      beforeWindowLoggedDays: 10,
      afterWindowLoggedDays: 12,
      adherence: const HrtAdherenceResult(
        scheduledDoses: 14,
        takenDoses: 14,
        adherencePercent: 100,
        adherenceText: '14 of 14 scheduled doses taken (100%)',
        needsGentleNote: false,
      ),
      symptomResults: [
        HrtSymptomChangeResult(
          symptomId: 'hot_flashes',
          symptomDisplayName: 'Hot Flashes',
          daysPresentBefore: 8,
          loggedDaysBefore: 10,
          frequencyBefore: 0.8,
          daysPresentAfter: 4,
          loggedDaysAfter: 12,
          frequencyAfter: 0.33,
          averageSeverityBefore: 4.0,
          averageSeverityAfter: 2.0,
          burdenBefore: 3.2,
          burdenAfter: 1.0,
          comparison: const MetricComparison(
            status: ComparisonStatus.eligible,
            currentValue: 1.0,
            previousValue: 3.2,
            delta: -2.2,
            percentChange: -69,
            changeType: MaterialChangeType.improved,
          ),
          directionWording: 'milder',
          dailyScores: {
            DateTime(2026, 9, 1): 4.0,
            DateTime(2026, 9, 2): 3.0,
            DateTime(2026, 9, 13): null, // Change date gap
            DateTime(2026, 9, 14): 2.0,
            DateTime(2026, 9, 15): 1.0,
          },
        ),
        HrtSymptomChangeResult(
          symptomId: 'headache',
          symptomDisplayName: 'Headache',
          daysPresentBefore: 3,
          loggedDaysBefore: 10,
          frequencyBefore: 0.3,
          daysPresentAfter: 3,
          loggedDaysAfter: 12,
          frequencyAfter: 0.25,
          averageSeverityBefore: 2.0,
          averageSeverityAfter: 2.0,
          burdenBefore: 1.0,
          burdenAfter: 0.8,
          comparison: const MetricComparison(
            status: ComparisonStatus.eligible,
            currentValue: 0.8,
            previousValue: 1.0,
            delta: -0.2,
            percentChange: -20,
            changeType: MaterialChangeType.steady,
          ),
          directionWording: 'about the same',
        ),
      ],
    );

    testWidgets('HrtImpactSection omitted completely when isHrtSetUp is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HrtImpactSection(
              groups: [group1],
              isHrtSetUp: false, // NOT SET UP
            ),
          ),
        ),
      );

      expect(find.text('HRT REGIMEN IMPACT'), findsNothing);
      expect(find.text('Regimen changed on Sep 13: Estradiol dose ↑'), findsNothing);
    });

    testWidgets('HrtImpactSection renders group card with headline, status, overlapping note, and disclaimer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HrtImpactSection(
              groups: [group1],
              isHrtSetUp: true,
            ),
          ),
        ),
      );

      expect(find.text('HRT REGIMEN IMPACT'), findsOneWidget);
      expect(find.text('Regimen changed on Sep 13: Estradiol dose ↑'), findsOneWidget);
      expect(find.text('READY'), findsOneWidget);
      expect(find.text('Note: Overlaps with Progesterone change on Sep 18'), findsOneWidget);
      expect(find.text('14 of 14 scheduled doses taken (100%)'), findsOneWidget);
      expect(find.text(kApprovedHrtDisclaimer), findsOneWidget);
    });

    testWidgets('HrtChangeDetailSheet selects largest change symptom by default and shows chart & averages', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => HrtChangeDetailSheet.show(context, group: group1),
                child: const Text('Open Change Detail'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Change Detail'));
      await tester.pumpAndSettle();

      expect(find.byType(HrtChangeDetailSheet), findsOneWidget);
      expect(find.text('Regimen changed on Sep 13: Estradiol dose ↑'), findsOneWidget);

      // Default symptom chip is Hot Flashes (largest change: 3.2 -> 1.0 vs 1.0 -> 0.8)
      expect(find.text('Hot Flashes Daily Scores'), findsOneWidget);
      expect(find.text('Improved'), findsOneWidget);

      // Legend averages
      expect(find.text('Before Avg: 3.2'), findsOneWidget);
      expect(find.text('After Avg: 1.0'), findsOneWidget);

      // Table comparisons
      expect(find.text('8 of 10 days'), findsOneWidget);
      expect(find.text('4 of 12 days'), findsOneWidget);
      expect(find.text('Severe (4.0)'), findsOneWidget);
      expect(find.text('Moderate (2.0)'), findsOneWidget);

      // Can switch to Headache via chips
      await tester.tap(find.text('Headache'));
      await tester.pumpAndSettle();

      expect(find.text('Headache Daily Scores'), findsOneWidget);
      expect(find.text('Steady'), findsOneWidget);
      expect(find.text('Before Avg: 1.0'), findsOneWidget);
      expect(find.text('After Avg: 0.8'), findsOneWidget);
    });
  });

  group('Task 8: InsightsScreen Full Integration Tests', () {
    testWidgets('InsightsScreen renders Hero, Patterns, Building, and HRT sections', (tester) async {
      final hrtGroup = HrtRegimenGroup(
        changeDate: DateTime(2026, 9, 13),
        events: const [],
        summaryTitle: 'Regimen changed on Sep 13: Estradiol dose ↑',
        status: HrtChangeStatus.ready,
        statusMessage: 'Ready for before/after comparison',
        daysSinceChange: 14,
        beforeWindowLoggedDays: 8,
        afterWindowLoggedDays: 8,
      );

      final patternResult = PatternEngineResult(
        requestedPeriod: AnalysisPeriod.days30,
        effectiveDaysInWindow: 30,
        patterns: [pattern1, pattern2, pattern3],
        buildingItems: const [
          BuildingPatternItem(
            triggerId: 'stress',
            triggerDisplayName: 'Stress',
            eventsCount: 5,
            targetCount: 7,
            displayText: 'Stress · 5 of 7 events',
          ),
        ],
        emptyStateType: SD10EmptyType.none,
      );

      final hrtResult = HrtAnalysisResult(groups: [hrtGroup]);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: InsightsScreen(
              customPatternResult: patternResult,
              customHrtResult: hrtResult,
              isHrtSetUp: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Hero
      expect(find.text('3 patterns identified'), findsOneWidget);
      expect(find.text('Based on last 30 days'), findsOneWidget);

      // Patterns list
      expect(find.text('IDENTIFIED PATTERNS'), findsOneWidget);
      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('Exercise'), findsOneWidget);
      expect(find.text('Hot Weather'), findsOneWidget);

      // Building list
      expect(find.text('BUILDING PATTERNS'), findsOneWidget);
      expect(find.text('Stress · 5 of 7 events'), findsOneWidget);

      // HRT section
      expect(find.text('HRT REGIMEN IMPACT'), findsOneWidget);
      expect(find.text('Regimen changed on Sep 13: Estradiol dose ↑'), findsOneWidget);
    });

    testWidgets('InsightsScreen omits HRT section when isHrtSetUp is false', (tester) async {
      final patternResult = PatternEngineResult(
        requestedPeriod: AnalysisPeriod.days30,
        effectiveDaysInWindow: 30,
        patterns: [pattern1],
        buildingItems: const [],
        emptyStateType: SD10EmptyType.none,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: InsightsScreen(
              customPatternResult: patternResult,
              isHrtSetUp: false, // NOT SET UP
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 pattern identified'), findsOneWidget);
      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('HRT REGIMEN IMPACT'), findsNothing);
    });
  });
}
