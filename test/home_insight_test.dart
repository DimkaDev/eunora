import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/features/analysis/analysis.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';

void main() {
  const selector = HomeInsightSelector();
  const analysisEngine = AnalysisEngine();
  const patternEngine = PatternEngine();
  final refDate = DateTime(2026, 9, 20);

  DailyLog createLog({
    required DateTime date,
    bool isCompleted = true,
    List<LoggedSymptom> symptoms = const [],
    List<String> triggers = const [],
    int caffeineCups = 0,
    int alcoholGlasses = 0,
    String stressLevel = 'Moderate',
    double sleepDuration = 7.0,
    DateTime? createdAt,
  }) {
    return DailyLog(
      id: date.toIso8601String().substring(0, 10),
      userId: 'test_user',
      date: date,
      isCompleted: isCompleted,
      symptoms: symptoms,
      triggers: triggers,
      caffeineCups: caffeineCups,
      alcoholGlasses: alcoholGlasses,
      stressLevel: stressLevel,
      sleepDuration: sleepDuration,
      createdAt: createdAt ?? date,
    );
  }

  LoggedSymptom createSymptom({
    required String id,
    required String name,
    String? severity,
    int? intensity,
    int? durationMinutes,
  }) {
    return LoggedSymptom(
      symptom: Symptom(id: id, name: name, iconName: 'medical_services'),
      severity: severity,
      intensity: intensity,
      durationMinutes: durationMinutes,
    );
  }

  PatternEngineResult makePatternResult({
    List<PatternInsight> patterns = const [],
    List<BuildingPatternItem> buildingItems = const [],
    SD10EmptyType emptyStateType = SD10EmptyType.none,
  }) {
    return PatternEngineResult(
      requestedPeriod: AnalysisPeriod.days30,
      effectiveDaysInWindow: 30,
      patterns: patterns,
      buildingItems: buildingItems,
      emptyStateType: emptyStateType,
    );
  }

  group('Task 4: High Severity Alert', () {
    test('fires when 3 consecutive logged days have severe hot flashes', () {
      final logs = [
        createLog(
          date: DateTime(2026, 9, 18),
          symptoms: [createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Severe')],
        ),
        createLog(
          date: DateTime(2026, 9, 19),
          symptoms: [createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Severe')],
        ),
        createLog(
          date: DateTime(2026, 9, 20),
          symptoms: [createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Severe')],
        ),
      ];

      final analysis30 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days30, today: refDate);
      final analysis7 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: refDate);
      final patterns = patternEngine.analyze(logs: logs, period: AnalysisPeriod.days30, today: refDate);

      final bundle = selector.selectInsights(
        logs: logs,
        today: refDate,
        analysis30: analysis30,
        analysis7: analysis7,
        patternsResult: patterns,
        hrtResult: const HrtAnalysisResult(groups: []),
        medications: const [],
      );

      expect(bundle.highSeverityAlert?.isActive, isTrue);
      expect(
        bundle.highSeverityAlert?.alertMessage,
        "You've logged severe hot flashes for 3 consecutive days. We recommend consulting your healthcare provider to discuss your current management plan.",
      );
    });

    test('does NOT fire if one day in the 3-day sequence is missing/unlogged', () {
      final logs = [
        createLog(
          date: DateTime(2026, 9, 18),
          symptoms: [createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Severe')],
        ),
        // Sep 19 is unlogged
        createLog(
          date: DateTime(2026, 9, 20),
          symptoms: [createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Severe')],
        ),
      ];

      final analysis30 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days30, today: refDate);
      final analysis7 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: refDate);
      final patterns = patternEngine.analyze(logs: logs, period: AnalysisPeriod.days30, today: refDate);

      final bundle = selector.selectInsights(
        logs: logs,
        today: refDate,
        analysis30: analysis30,
        analysis7: analysis7,
        patternsResult: patterns,
        hrtResult: const HrtAnalysisResult(groups: []),
        medications: const [],
      );

      expect(bundle.highSeverityAlert?.isActive ?? false, isFalse);
    });

    test('does NOT fire for non-hot-flash symptoms even if 3 consecutive days severe', () {
      final logs = [
        createLog(
          date: DateTime(2026, 9, 18),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Severe')],
        ),
        createLog(
          date: DateTime(2026, 9, 19),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Severe')],
        ),
        createLog(
          date: DateTime(2026, 9, 20),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Severe')],
        ),
      ];

      final analysis30 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days30, today: refDate);
      final analysis7 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: refDate);
      final patterns = patternEngine.analyze(logs: logs, period: AnalysisPeriod.days30, today: refDate);

      final bundle = selector.selectInsights(
        logs: logs,
        today: refDate,
        analysis30: analysis30,
        analysis7: analysis7,
        patternsResult: patterns,
        hrtResult: const HrtAnalysisResult(groups: []),
        medications: const [],
      );

      expect(bundle.highSeverityAlert?.isActive ?? false, isFalse);
    });
  });

  group('Task 4: Daily Insight Hierarchy', () {
    test('D-1: Symptom-free day when baseline >= 3 logged days', () {
      final logs = [
        createLog(
          date: DateTime(2026, 9, 15),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')],
        ),
        createLog(
          date: DateTime(2026, 9, 16),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Moderate')],
        ),
        createLog(
          date: DateTime(2026, 9, 17),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')],
        ),
        createLog(date: DateTime(2026, 9, 20), symptoms: const []),
      ];

      final analysis30 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days30, today: refDate);
      final analysis7 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: refDate);
      final patterns = patternEngine.analyze(logs: logs, period: AnalysisPeriod.days30, today: refDate);

      final bundle = selector.selectInsights(
        logs: logs,
        today: refDate,
        analysis30: analysis30,
        analysis7: analysis7,
        patternsResult: patterns,
        hrtResult: const HrtAnalysisResult(groups: []),
        medications: const [],
      );

      expect(bundle.dailyInsight.candidateType, 'D-1');
      expect(bundle.dailyInsight.headline, 'No symptoms logged today.');
      expect(bundle.dailyInsight.tag, HomeInsightTag.positiveTrend);
    });

    test('D-2: Lighter than usual when today is at least 0.5 below 30d norm', () {
      final logs = List.generate(7, (i) {
        return createLog(
          date: DateTime(2026, 9, 1 + i),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Severe')],
        );
      });
      logs.add(
        createLog(
          date: DateTime(2026, 9, 20),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')],
        ),
      );

      final analysis30 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days30, today: refDate);
      final analysis7 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: refDate);
      final patterns = patternEngine.analyze(logs: logs, period: AnalysisPeriod.days30, today: refDate);

      final bundle = selector.selectInsights(
        logs: logs,
        today: refDate,
        analysis30: analysis30,
        analysis7: analysis7,
        patternsResult: patterns,
        hrtResult: const HrtAnalysisResult(groups: []),
        medications: const [],
      );

      expect(bundle.dailyInsight.candidateType, 'D-2');
      expect(bundle.dailyInsight.headline, contains('milder than your usual'));
      expect(bundle.dailyInsight.tag, HomeInsightTag.positiveTrend);
    });

    test('D-3: Stronger than usual when today is at least 0.5 above 30d norm (no advice)', () {
      final logs = List.generate(7, (i) {
        return createLog(
          date: DateTime(2026, 9, 1 + i),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')],
        );
      });
      logs.add(
        createLog(
          date: DateTime(2026, 9, 20),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Severe')],
        ),
      );

      final analysis30 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days30, today: refDate);
      final analysis7 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: refDate);
      final patterns = patternEngine.analyze(logs: logs, period: AnalysisPeriod.days30, today: refDate);

      final bundle = selector.selectInsights(
        logs: logs,
        today: refDate,
        analysis30: analysis30,
        analysis7: analysis7,
        patternsResult: patterns,
        hrtResult: const HrtAnalysisResult(groups: []),
        medications: const [],
      );

      expect(bundle.dailyInsight.candidateType, 'D-3');
      expect(bundle.dailyInsight.headline, contains('stronger than your usual'));
      expect(bundle.dailyInsight.headline, contains("Tomorrow's log will show whether this continues."));
      expect(bundle.dailyInsight.tag, HomeInsightTag.worthNoting);
    });

    test('D-5: Protective habit logged today with ready protective pattern', () {
      final logs = <DailyLog>[];
      for (int i = 1; i <= 14; i++) {
        final hasYoga = i % 2 == 0;
        logs.add(
          createLog(
            date: DateTime(2026, 9, i),
            triggers: hasYoga ? ['yoga'] : [],
            symptoms: [
              createSymptom(
                id: 'fatigue',
                name: 'Fatigue',
                severity: 'Mild',
              ),
            ],
          ),
        );
      }
      // Today (Sep 20) with yoga and mild fatigue (same severity as norm, so D-2 and D-3 don't trigger)
      logs.add(
        createLog(
          date: DateTime(2026, 9, 20),
          triggers: ['yoga'],
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')],
        ),
      );

      final analysis30 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days30, today: refDate);
      final analysis7 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: refDate);

      const readyProtective = PatternInsight(
        triggerId: 'yoga',
        triggerDisplayName: 'Yoga',
        outcomeId: 'fatigue',
        outcomeDisplayName: 'Fatigue',
        isOverallDayLevel: false,
        lag: PatternLag.lag0,
        type: PatternType.protective,
        confidence: PatternConfidence.high,
        rawCorrelation: -0.65,
        strength: 0.65,
        correlationPercent: 65,
        effect: -1.2,
        exposedAverage: 1.0,
        unexposedAverage: 2.2,
        eventCount: 8,
        comparisonDaysCount: 8,
        hitRateCount: 7,
        headlineText: 'Yoga may ease Fatigue',
        evidenceText: 'Fatigue averaged 1.0 on days with Yoga vs 2.2 on other days.',
        hitRateText: 'Lower on 7 of 8 days.',
      );

      final patternsResult = makePatternResult(patterns: [readyProtective]);

      final bundle = selector.selectInsights(
        logs: logs,
        today: refDate,
        analysis30: analysis30,
        analysis7: analysis7,
        patternsResult: patternsResult,
        hrtResult: const HrtAnalysisResult(groups: []),
        medications: const [],
      );

      expect(bundle.dailyInsight.candidateType, 'D-5');
      expect(bundle.dailyInsight.headline, contains('You logged Yoga today'));
      expect(bundle.dailyInsight.headline, contains('Fatigue tends to be milder'));
      expect(bundle.dailyInsight.tag, HomeInsightTag.positiveTrend);
    });

    test('D-4: Known trigger logged today with ready pattern', () {
      final logs = <DailyLog>[];
      for (int i = 1; i <= 14; i++) {
        final hasCaffeine = i % 2 == 0;
        logs.add(
          createLog(
            date: DateTime(2026, 9, i),
            triggers: hasCaffeine ? ['caffeine'] : [],
            caffeineCups: hasCaffeine ? 3 : 0,
            symptoms: [
              createSymptom(
                id: 'hot_flash',
                name: 'Hot Flashes',
                severity: 'Moderate',
              ),
            ],
          ),
        );
      }
      // Today (Sep 20) with caffeine and moderate hot flashes (same severity as norm)
      logs.add(
        createLog(
          date: DateTime(2026, 9, 20),
          triggers: ['caffeine'],
          caffeineCups: 3,
          symptoms: [createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Moderate')],
        ),
      );

      final analysis30 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days30, today: refDate);
      final analysis7 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: refDate);

      const readyTrigger = PatternInsight(
        triggerId: 'caffeine',
        triggerDisplayName: 'Caffeine',
        outcomeId: 'hot_flash',
        outcomeDisplayName: 'Hot Flashes',
        isOverallDayLevel: false,
        lag: PatternLag.lag0,
        type: PatternType.worsening,
        confidence: PatternConfidence.high,
        rawCorrelation: 0.65,
        strength: 0.65,
        correlationPercent: 65,
        effect: 1.5,
        exposedAverage: 3.5,
        unexposedAverage: 2.0,
        eventCount: 8,
        comparisonDaysCount: 8,
        hitRateCount: 7,
        headlineText: 'Caffeine may trigger Hot Flashes',
        evidenceText: 'Hot Flashes averaged 3.5 on days with Caffeine vs 2.0 on other days.',
        hitRateText: 'Higher on 7 of 8 days.',
      );

      final patternsResult = makePatternResult(patterns: [readyTrigger]);

      final bundle = selector.selectInsights(
        logs: logs,
        today: refDate,
        analysis30: analysis30,
        analysis7: analysis7,
        patternsResult: patternsResult,
        hrtResult: const HrtAnalysisResult(groups: []),
        medications: const [],
      );

      expect(bundle.dailyInsight.candidateType, 'D-4');
      expect(bundle.dailyInsight.headline, contains('You logged Caffeine today'));
      expect(bundle.dailyInsight.headline, contains('Hot Flashes tends to be stronger'));
      expect(bundle.dailyInsight.tag, HomeInsightTag.pattern);
    });

    test('D-6: HRT pending countdown', () {
      final logs = List.generate(7, (i) {
        return createLog(
          date: DateTime(2026, 9, 14 + i),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Moderate')],
        );
      });

      final analysis30 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days30, today: refDate);
      final analysis7 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: refDate);

      // HRT change happened 5 days ago (Sep 15) -> Day 5 of 14, ready in 9 days
      final hrtGroup = HrtRegimenGroup(
        changeDate: DateTime(2026, 9, 15),
        events: [
          HrtRegimenEvent(
            id: 'e1',
            medicationId: 'm1',
            medicationName: 'Estradiol',
            eventType: HrtRegimenEventType.doseIncreased,
            changeDate: DateTime(2026, 9, 15),
            previousValue: '1mg',
            newValue: '2mg',
          ),
        ],
        summaryTitle: 'Estradiol dose ↑',
        status: HrtChangeStatus.pending,
        statusMessage: 'Day 5 of 14',
        daysToGo: 9,
        daysSinceChange: 4,
        beforeWindowLoggedDays: 10,
        afterWindowLoggedDays: 4,
      );

      final bundle = selector.selectInsights(
        logs: logs,
        today: refDate,
        analysis30: analysis30,
        analysis7: analysis7,
        patternsResult: makePatternResult(),
        hrtResult: HrtAnalysisResult(groups: [hrtGroup]),
        medications: const [],
      );

      expect(bundle.dailyInsight.candidateType, 'D-6');
      expect(bundle.dailyInsight.headline, contains('Day 5 of 14 since your regimen changed'));
      expect(bundle.dailyInsight.headline, contains('comparison ready in 9 days'));
    });

    test('D-7: Logged 7 of last 7 days (no streak wording)', () {
      final logs = List.generate(7, (i) {
        return createLog(
          date: DateTime(2026, 9, 14 + i),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Moderate')],
        );
      });

      final analysis30 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days30, today: refDate);
      final analysis7 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: refDate);

      final bundle = selector.selectInsights(
        logs: logs,
        today: refDate,
        analysis30: analysis30,
        analysis7: analysis7,
        patternsResult: makePatternResult(),
        hrtResult: const HrtAnalysisResult(groups: []),
        medications: const [],
      );

      expect(bundle.dailyInsight.candidateType, 'D-7');
      expect(bundle.dailyInsight.headline, "You've logged 7 of the last 7 days.");
      expect(bundle.dailyInsight.headline.toLowerCase(), isNot(contains('streak')));
    });

    test('D-8: Fallback when fewer than 7 logged days in baseline', () {
      final logs = [
        createLog(
          date: DateTime(2026, 9, 20),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Moderate')],
        ),
      ];

      final analysis30 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days30, today: refDate);
      final analysis7 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: refDate);

      final bundle = selector.selectInsights(
        logs: logs,
        today: refDate,
        analysis30: analysis30,
        analysis7: analysis7,
        patternsResult: makePatternResult(emptyStateType: SD10EmptyType.notEnoughData),
        hrtResult: const HrtAnalysisResult(groups: []),
        medications: const [],
      );

      expect(bundle.dailyInsight.candidateType, 'D-8');
      expect(bundle.dailyInsight.headline, 'Log 6 more days to unlock personal insights.');
    });

    test('Yesterday fallback when today is unlogged', () {
      final logs = [
        createLog(
          date: DateTime(2026, 9, 17),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')],
        ),
        createLog(
          date: DateTime(2026, 9, 18),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')],
        ),
        createLog(date: DateTime(2026, 9, 19), symptoms: const []),
        // Sep 20 is NOT logged
      ];

      final analysis30 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days30, today: refDate);
      final analysis7 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: refDate);

      final bundle = selector.selectInsights(
        logs: logs,
        today: refDate,
        analysis30: analysis30,
        analysis7: analysis7,
        patternsResult: makePatternResult(),
        hrtResult: const HrtAnalysisResult(groups: []),
        medications: const [],
      );

      expect(bundle.dailyInsight.title, "Yesterday's Insight");
      expect(bundle.dailyInsight.headline, 'No symptoms were logged yesterday.');
    });

    test('Gentle prompt to log when today and yesterday are unlogged', () {
      final logs = [
        createLog(date: DateTime(2026, 9, 10), symptoms: const []),
      ];

      final analysis30 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days30, today: refDate);
      final analysis7 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: refDate);

      final bundle = selector.selectInsights(
        logs: logs,
        today: refDate,
        analysis30: analysis30,
        analysis7: analysis7,
        patternsResult: makePatternResult(),
        hrtResult: const HrtAnalysisResult(groups: []),
        medications: const [],
      );

      expect(bundle.dailyInsight.title, 'Daily Insight');
      expect(bundle.dailyInsight.headline, 'Log today to keep your picture up to date.');
      expect(bundle.dailyInsight.tag, HomeInsightTag.insight);
    });
  });

  group('Task 4: Weekly Insight Hierarchy', () {
    test('W-1: Overall material improvement compared with previous 7 days', () {
      // 7 days in previous week with severe symptoms (level = 4.0)
      // 7 days in current week with mild symptoms (level = 1.0)
      final logs = <DailyLog>[];
      for (int i = 7; i <= 13; i++) {
        logs.add(createLog(
          date: DateTime(2026, 9, i),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Severe')],
        ));
      }
      for (int i = 14; i <= 20; i++) {
        logs.add(createLog(
          date: DateTime(2026, 9, i),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')],
        ));
      }

      final analysis30 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days30, today: refDate);
      final analysis7 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: refDate);

      final bundle = selector.selectInsights(
        logs: logs,
        today: refDate,
        analysis30: analysis30,
        analysis7: analysis7,
        patternsResult: makePatternResult(),
        hrtResult: const HrtAnalysisResult(groups: []),
        medications: const [],
      );

      expect(bundle.weeklyInsight.candidateType, 'W-1');
      expect(bundle.weeklyInsight.headline, contains('improved'));
      expect(bundle.weeklyInsight.headline, contains('compared with the previous 7 days'));
      expect(bundle.weeklyInsight.tag, HomeInsightTag.positiveTrend);
    });

    test('W-1: Overall material worsening compared with previous 7 days', () {
      // 7 days in previous week with mild symptoms (level = 1.0)
      // 7 days in current week with severe symptoms (level = 4.0)
      final logs = <DailyLog>[];
      for (int i = 7; i <= 13; i++) {
        logs.add(createLog(
          date: DateTime(2026, 9, i),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')],
        ));
      }
      for (int i = 14; i <= 20; i++) {
        logs.add(createLog(
          date: DateTime(2026, 9, i),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Severe')],
        ));
      }

      final analysis30 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days30, today: refDate);
      final analysis7 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: refDate);

      final bundle = selector.selectInsights(
        logs: logs,
        today: refDate,
        analysis30: analysis30,
        analysis7: analysis7,
        patternsResult: makePatternResult(),
        hrtResult: const HrtAnalysisResult(groups: []),
        medications: const [],
      );

      expect(bundle.weeklyInsight.candidateType, 'W-1');
      expect(bundle.weeklyInsight.headline, contains('rose'));
      expect(bundle.weeklyInsight.headline, contains('compared with the previous 7 days'));
      expect(bundle.weeklyInsight.tag, HomeInsightTag.worthNoting);
    });

    test('W-3: Sleep split insight when >= 3 days < 6h and >= 3 days >= 6h', () {
      final logs = [
        // 3 days with < 6h sleep (severity 4.0)
        createLog(
          date: DateTime(2026, 9, 14),
          sleepDuration: 5.0,
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Severe')],
        ),
        createLog(
          date: DateTime(2026, 9, 15),
          sleepDuration: 4.5,
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Severe')],
        ),
        createLog(
          date: DateTime(2026, 9, 16),
          sleepDuration: 5.5,
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Severe')],
        ),
        // 3 days with >= 6h sleep (severity 1.0)
        createLog(
          date: DateTime(2026, 9, 17),
          sleepDuration: 7.5,
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')],
        ),
        createLog(
          date: DateTime(2026, 9, 18),
          sleepDuration: 8.0,
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')],
        ),
        createLog(
          date: DateTime(2026, 9, 19),
          sleepDuration: 7.0,
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')],
        ),
      ];

      final analysis30 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days30, today: refDate);
      final analysis7 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: refDate);

      final bundle = selector.selectInsights(
        logs: logs,
        today: refDate,
        analysis30: analysis30,
        analysis7: analysis7,
        patternsResult: makePatternResult(),
        hrtResult: const HrtAnalysisResult(groups: []),
        medications: const [],
      );

      expect(bundle.weeklyInsight.candidateType, 'W-3');
      expect(bundle.weeklyInsight.headline, contains('On days with under 6 hours of sleep, symptom severity averaged'));
      expect(bundle.weeklyInsight.tag, HomeInsightTag.pattern);
    });

    test('W-4: Strongest pattern this week', () {
      final logs = List.generate(7, (i) {
        return createLog(
          date: DateTime(2026, 9, 14 + i),
          symptoms: [createSymptom(id: 'insomnia', name: 'Insomnia', severity: 'Moderate')],
        );
      });

      final analysis30 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days30, today: refDate);
      final analysis7 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: refDate);

      const readyPattern = PatternInsight(
        triggerId: 'alcohol',
        triggerDisplayName: 'Alcohol',
        outcomeId: 'insomnia',
        outcomeDisplayName: 'Insomnia',
        isOverallDayLevel: false,
        lag: PatternLag.lag0,
        type: PatternType.worsening,
        confidence: PatternConfidence.high,
        rawCorrelation: 0.72,
        strength: 0.72,
        correlationPercent: 72,
        effect: 1.8,
        exposedAverage: 3.2,
        unexposedAverage: 1.4,
        eventCount: 9,
        comparisonDaysCount: 12,
        hitRateCount: 8,
        headlineText: 'Alcohol may trigger Insomnia',
        evidenceText: 'Insomnia averaged 3.2 on days with Alcohol vs 1.4 on other days.',
        hitRateText: 'Higher on 8 of 9 days.',
      );

      final patternsResult = makePatternResult(patterns: [readyPattern]);

      final bundle = selector.selectInsights(
        logs: logs,
        today: refDate,
        analysis30: analysis30,
        analysis7: analysis7,
        patternsResult: patternsResult,
        hrtResult: const HrtAnalysisResult(groups: []),
        medications: const [],
      );

      expect(bundle.weeklyInsight.candidateType, 'W-4');
      expect(bundle.weeklyInsight.headline, "This week's strongest pattern: Alcohol → Insomnia (72%).");
      expect(bundle.weeklyInsight.tag, HomeInsightTag.pattern);
    });

    test('W-6: Coverage below 100% when no higher candidate', () {
      final logs = [
        createLog(date: DateTime(2026, 9, 14), symptoms: const []),
        createLog(date: DateTime(2026, 9, 15), symptoms: const []),
        createLog(date: DateTime(2026, 9, 16), symptoms: const []),
        createLog(date: DateTime(2026, 9, 17), symptoms: const []),
      ];

      final analysis30 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days30, today: refDate);
      final analysis7 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: refDate);

      final bundle = selector.selectInsights(
        logs: logs,
        today: refDate,
        analysis30: analysis30,
        analysis7: analysis7,
        patternsResult: makePatternResult(),
        hrtResult: const HrtAnalysisResult(groups: []),
        medications: const [],
      );

      expect(bundle.weeklyInsight.candidateType, 'W-6');
      expect(bundle.weeklyInsight.headline, 'You logged 4 of 7 days this week.');
    });

    test('W-7: Fallback when 0 days logged this week', () {
      final analysis30 = analysisEngine.analyzeWindow(logs: const [], period: AnalysisPeriod.days30, today: refDate);
      final analysis7 = analysisEngine.analyzeWindow(logs: const [], period: AnalysisPeriod.days7, today: refDate);

      final bundle = selector.selectInsights(
        logs: const [],
        today: refDate,
        analysis30: analysis30,
        analysis7: analysis7,
        patternsResult: makePatternResult(),
        hrtResult: const HrtAnalysisResult(groups: []),
        medications: const [],
      );

      expect(bundle.weeklyInsight.candidateType, 'W-7');
      expect(bundle.weeklyInsight.headline, 'Keep logging — your weekly picture builds as you go.');
    });
  });

  group('Task 4: Anti-Repetition Rule', () {
    test('suppresses same kind and subject when key number has not materially changed', () {
      final logs = List.generate(7, (i) {
        return createLog(
          date: DateTime(2026, 9, 1 + i),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Moderate')],
        );
      });
      logs.add(
        createLog(
          date: DateTime(2026, 9, 20),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')],
        ),
      );

      final analysis30 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days30, today: refDate);
      final analysis7 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: refDate);

      // Previous insight was D-2 with severity 1.1 (very close to 1.0, not material change |1.0 - 1.1| = 0.1 < 0.5)
      const previousInsight = HomeInsightCardData(
        candidateType: 'D-2',
        subjectKey: 'd2_lighter',
        keyNumber: 1.1,
        title: 'Daily Insight',
        headline: "Today's symptoms were milder than your usual (1.1 vs 2.0).",
        tag: HomeInsightTag.positiveTrend,
        averageSeverityDisplay: 'Mild · 1.1 / 5',
        consistencyPercent: 80,
        targetMetric: 'overall_severity',
        targetPeriod: AnalysisPeriod.days30,
        evidenceSummary: 'milder',
      );

      final bundle = selector.selectInsights(
        logs: logs,
        today: refDate,
        analysis30: analysis30,
        analysis7: analysis7,
        patternsResult: makePatternResult(),
        hrtResult: const HrtAnalysisResult(groups: []),
        medications: const [],
        previousDayDailyInsight: previousInsight,
      );

      // Should skip D-2 and choose the next eligible candidate (e.g. D-8 or another candidate)
      expect(bundle.dailyInsight.candidateType, isNot('D-2'));
    });
  });
}
