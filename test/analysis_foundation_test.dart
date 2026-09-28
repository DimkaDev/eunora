import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/features/analysis/analysis.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';

void main() {
  const engine = AnalysisEngine();

  // Helper to build a DailyLog
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

  // Helper for logged symptoms
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

  group('SD-1 Day Model & Date Handling', () {
    test('local calendar date keying ignores timestamp variations and incomplete logs', () {
      final today = DateTime(2026, 9, 20); // Sunday
      final date = DateTime(2026, 9, 19, 23, 45, 12); // Late evening

      final historyStartLog = createLog(
        date: DateTime(2026, 9, 14),
        isCompleted: true,
        symptoms: [createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Mild')],
      );

      final completedLog = createLog(
        date: date,
        isCompleted: true,
        symptoms: [createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Moderate')],
      );

      final incompleteLog = createLog(
        date: DateTime(2026, 9, 18, 10, 0),
        isCompleted: false,
        symptoms: [createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Severe')],
      );

      final result = engine.analyzeWindow(
        logs: [historyStartLog, completedLog, incompleteLog],
        period: AnalysisPeriod.days7,
        today: today,
      );

      // Incomplete log on Sep 18 is ignored (marked notLogged)
      final sep18 = result.dailyPictures.firstWhere((p) => p.date == DateTime(2026, 9, 18));
      expect(sep18.status, DayStatus.notLogged);
      expect(sep18.dayLevel, isNull);

      // Completed log on Sep 19 is normalized to calendar day
      final sep19 = result.dailyPictures.firstWhere((p) => p.date == DateTime(2026, 9, 19));
      expect(sep19.status, DayStatus.logged);
      expect(sep19.dayLevel, 3.0); // Moderate = 3.0

      // Today (Sep 20) with no log is pending
      final sep20 = result.dailyPictures.firstWhere((p) => p.date == DateTime(2026, 9, 20));
      expect(sep20.status, DayStatus.pending);
      expect(sep20.dayLevel, isNull);
    });

    test('symptom-free days have score 0 and are included in denominators', () {
      final today = DateTime(2026, 9, 20);
      final logs = [
        createLog(
          date: DateTime(2026, 9, 19),
          isCompleted: true,
          symptoms: [], // Symptom free!
        ),
        createLog(
          date: DateTime(2026, 9, 20),
          isCompleted: true,
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Severe')], // 5.0
        ),
      ];

      final result = engine.analyzeWindow(
        logs: logs,
        period: AnalysisPeriod.days7,
        today: today,
      );

      expect(result.symptomFreeDaysCount, 1);
      final sep19 = result.dailyPictures.firstWhere((p) => p.date == DateTime(2026, 9, 19));
      expect(sep19.isSymptomFree, isTrue);
      expect(sep19.dayLevel, 0.0);

      // Burden includes symptom-free day: 5.0 on Sep 20 + 0.0 on Sep 19 / 2 logged days = 2.5
      final fatigueMetric = result.symptomsMap['fatigue']!;
      expect(fatigueMetric.burden, 2.5);
      // Day rate: 1 present / 2 logged days = 0.5
      expect(fatigueMetric.dayRate, 0.5);
      // Average severity only counts present occurrences: 5.0
      expect(fatigueMetric.averageSeverity, 5.0);
    });

    test('DST transitions do not distort calendar arithmetic or day count', () {
      // European DST fall-back is last Sunday of October (e.g. Oct 25, 2026: 25h day)
      final start = DateTime(2026, 10, 24);
      final end = DateTime(2026, 10, 26);
      expect(AnalysisEngine.calendarDaysBetween(start, end), 3);

      final dayPlus1 = AnalysisEngine.addDays(start, 1);
      expect(dayPlus1.year, 2026);
      expect(dayPlus1.month, 10);
      expect(dayPlus1.day, 25);
      expect(dayPlus1.hour, 0); // Preserves midnight, no shift to 23:00 or 01:00
    });

    test('results are deterministic and order-independent', () {
      final today = DateTime(2026, 9, 20);
      final log1 = createLog(
        date: DateTime(2026, 9, 18),
        symptoms: [createSymptom(id: 'headache', name: 'Headache', severity: 'Mild')],
      );
      final log2 = createLog(
        date: DateTime(2026, 9, 19),
        symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Moderate')],
      );
      final log3 = createLog(
        date: DateTime(2026, 9, 20),
        symptoms: [createSymptom(id: 'anxiety', name: 'Anxiety', severity: 'Severe')],
      );

      final resultForward = engine.analyzeWindow(
        logs: [log1, log2, log3],
        period: AnalysisPeriod.days7,
        today: today,
      );

      final resultReversed = engine.analyzeWindow(
        logs: [log3, log1, log2],
        period: AnalysisPeriod.days7,
        today: today,
      );

      expect(resultForward.averageSeverity, resultReversed.averageSeverity);
      expect(resultForward.coverage, resultReversed.coverage);
      expect(resultForward.symptomRankings.map((s) => s.symptomId).toList(),
          resultReversed.symptomRankings.map((s) => s.symptomId).toList());
    });
  });

  group('SD-2 Periods & Windows', () {
    test('coverage and consistency calculations', () {
      final today = DateTime(2026, 9, 20);
      // 4 logged days in the last 7 days
      final logs = [
        createLog(date: DateTime(2026, 9, 14)),
        createLog(date: DateTime(2026, 9, 16)),
        createLog(date: DateTime(2026, 9, 18)),
        createLog(date: DateTime(2026, 9, 20)),
      ];

      final result = engine.analyzeWindow(
        logs: logs,
        period: AnalysisPeriod.days7,
        today: today,
        accountCreatedDate: DateTime(2026, 9, 1),
      );

      expect(result.calendarDaysInWindow, 7);
      expect(result.loggedDaysCount, 4);
      expect(result.coverage, closeTo(4 / 7, 0.001));
      expect(result.consistency, closeTo(4 / 7, 0.001));
    });

    test('consistency is clamped to account age when account is newer than 7 days', () {
      final today = DateTime(2026, 9, 20);
      // Account created 3 days ago (Sep 18)
      final accountCreated = DateTime(2026, 9, 18);
      final logs = [
        createLog(date: DateTime(2026, 9, 18)),
        createLog(date: DateTime(2026, 9, 20)),
      ];

      final result = engine.analyzeWindow(
        logs: logs,
        period: AnalysisPeriod.days7,
        today: today,
        accountCreatedDate: accountCreated,
      );

      // Trailing span is 3 days (Sep 18, 19, 20), 2 logged days -> 2/3
      expect(result.consistency, closeTo(2 / 3, 0.001));
    });

    test('history shorter than window clamps window start and disables previous window', () {
      final today = DateTime(2026, 9, 20);
      // User only started logging 5 days ago (Sep 16)
      final logs = [
        createLog(date: DateTime(2026, 9, 16)),
        createLog(date: DateTime(2026, 9, 18)),
        createLog(date: DateTime(2026, 9, 20)),
      ];

      final result = engine.analyzeWindow(
        logs: logs,
        period: AnalysisPeriod.days30, // Requesting 30-day window
        today: today,
      );

      expect(result.isHistoryClamped, isTrue);
      expect(result.windowStart, DateTime(2026, 9, 16));
      expect(result.calendarDaysInWindow, 5);
      expect(result.daysOfData, 5);
      expect(result.previousWindowPictures, isNull);
      expect(result.severityComparison!.status, ComparisonStatus.notEnoughData);
      expect(result.severityComparison!.reason, NotEnoughDataReason.historyShorterThanWindow);
    });
  });

  group('SD-3 Severity Scale & Labels', () {
    test('normalizes Mild=1, Moderate=3, Severe=5 and intensity/2 onto 0-5 scale', () {
      final today = DateTime(2026, 9, 20);
      final logs = [
        createLog(
          date: DateTime(2026, 9, 19),
          symptoms: [
            createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Mild'), // 1.0
            createSymptom(id: 'anxiety', name: 'Anxiety', intensity: 8), // 8 / 2 = 4.0
          ],
        ),
        createLog(
          date: DateTime(2026, 9, 20),
          symptoms: [
            createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Severe'), // 5.0
            createSymptom(id: 'night_wakings', name: 'Night Wakings', severity: 'Moderate'), // 3.0
          ],
        ),
      ];

      final result = engine.analyzeWindow(
        logs: logs,
        period: AnalysisPeriod.days7,
        today: today,
      );

      // Average severity: (1.0 + 4.0 + 5.0 + 3.0) / 4 = 13.0 / 4 = 3.25
      expect(result.averageSeverity, 3.25);
      expect(result.severityLabel, 'Moderate');
      expect(result.severityDisplay, 'Moderate · 3.3 / 5');

      // Check Hot Flash metric: Mild(1) + Severe(5) / 2 occurrences = 3.0
      final hf = result.symptomsMap['hot_flash']!;
      expect(hf.averageSeverity, 3.0);
      expect(hf.severityLabel, 'Moderate');
      expect(hf.category, 'Vasomotor');
    });

    test('symptoms present without severity counted in daysPresent but excluded from severity average', () {
      final today = DateTime(2026, 9, 20);
      final logs = [
        createLog(
          date: DateTime(2026, 9, 20),
          symptoms: [
            createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Moderate'), // 3.0
            createSymptom(id: 'joint_pain', name: 'Joint Pain'), // No severity or intensity
          ],
        ),
      ];

      final result = engine.analyzeWindow(
        logs: logs,
        period: AnalysisPeriod.days7,
        today: today,
      );

      // Overall average severity only includes the 3.0
      expect(result.averageSeverity, 3.0);

      // Joint pain is present for 1 day, day rate 1.0, but averageSeverity is null
      final jp = result.symptomsMap['joint_pain']!;
      expect(jp.daysPresent, 1);
      expect(jp.dayRate, 1.0);
      expect(jp.burden, 0.0);
      expect(jp.averageSeverity, isNull);
      expect(jp.severityLabel, isNull);
    });

    test('symptom ranking: ties broken alphabetically by identifier', () {
      final today = DateTime(2026, 9, 20);
      final logs = [
        createLog(
          date: DateTime(2026, 9, 20),
          symptoms: [
            createSymptom(id: 'b_symptom', name: 'B Symptom', severity: 'Moderate'),
            createSymptom(id: 'a_symptom', name: 'A Symptom', severity: 'Moderate'),
            createSymptom(id: 'c_symptom', name: 'C Symptom', severity: 'Severe'), // Higher burden
          ],
        ),
      ];

      final result = engine.analyzeWindow(
        logs: logs,
        period: AnalysisPeriod.days7,
        today: today,
      );

      // c_symptom has burden 5.0 -> rank 1
      // a_symptom and b_symptom both have dayRate 1.0, burden 3.0 -> a_symptom rank 2, b_symptom rank 3
      expect(result.symptomRankings[0].symptomId, 'c_symptom');
      expect(result.symptomRankings[0].ranking, 1);
      expect(result.symptomRankings[1].symptomId, 'a_symptom');
      expect(result.symptomRankings[1].ranking, 2);
      expect(result.symptomRankings[2].symptomId, 'b_symptom');
      expect(result.symptomRankings[2].ranking, 3);
    });
  });

  group('SD-4 Comparison Minimums & Material Change', () {
    test('1-day period never allows comparison', () {
      final today = DateTime(2026, 9, 20);
      final logs = [createLog(date: today)];

      final result = engine.analyzeWindow(
        logs: logs,
        period: AnalysisPeriod.day1,
        today: today,
      );

      expect(result.severityComparison!.status, ComparisonStatus.notEnoughData);
      expect(result.severityComparison!.reason, NotEnoughDataReason.singleDayPeriod);
    });

    test('7-day period requires at least 3 logged days in both windows', () {
      final today = DateTime(2026, 9, 20);

      // Current window: 3 logged days (Sep 18, 19, 20)
      // Previous window (Sep 7 to Sep 13): only 2 logged days (Sep 10, 12)
      final logs = [
        createLog(date: DateTime(2026, 9, 7)),
        createLog(date: DateTime(2026, 9, 10)),
        // Only 2 days in previous window!
        createLog(date: DateTime(2026, 9, 18)),
        createLog(date: DateTime(2026, 9, 19)),
        createLog(date: DateTime(2026, 9, 20)),
      ];

      final result = engine.analyzeWindow(
        logs: logs,
        period: AnalysisPeriod.days7,
        today: today,
      );

      expect(result.severityComparison!.status, ComparisonStatus.notEnoughData);
      expect(result.severityComparison!.reason, NotEnoughDataReason.notEnoughDataPrevious);
    });

    test('material change calculation: |delta| >= 0.5 AND |relativeChange| >= 15%', () {
      // 3.0 down to 2.0: delta = -1.0 (|delta| = 1.0 >= 0.5), relative = 1.0 / 3.0 = 33.3% (>= 15%) -> improved
      final comp1 = MetricComparison.evaluate(current: 2.0, previous: 3.0, lowerIsBetter: true);
      expect(comp1.status, ComparisonStatus.eligible);
      expect(comp1.changeType, MaterialChangeType.improved);
      expect(comp1.delta, -1.0);
      expect(comp1.percentChange, -33);

      // 3.0 down to 2.7: delta = -0.3 (|delta| < 0.5, fails threshold) -> steady
      final comp2 = MetricComparison.evaluate(current: 2.7, previous: 3.0, lowerIsBetter: true);
      expect(comp2.changeType, MaterialChangeType.steady);

      // 4.5 up to 5.0: delta = +0.5 (|delta| = 0.5), relative = 0.5 / 4.5 = 11.1% (< 15%, fails threshold) -> steady
      final comp3 = MetricComparison.evaluate(current: 5.0, previous: 4.5, lowerIsBetter: true);
      expect(comp3.changeType, MaterialChangeType.steady);

      // Baseline 0 -> newOccurrence (no percent)
      final comp4 = MetricComparison.evaluate(current: 2.5, previous: 0.0);
      expect(comp4.changeType, MaterialChangeType.newOccurrence);
      expect(comp4.percentChange, isNull);

      // Cleared to 0 -> cleared (no percent)
      final comp5 = MetricComparison.evaluate(current: 0.0, previous: 2.5);
      expect(comp5.changeType, MaterialChangeType.cleared);
      expect(comp5.percentChange, isNull);

      // Percent change capped at ±100%
      final comp6 = MetricComparison.evaluate(current: 5.0, previous: 1.0);
      expect(comp6.percentChange, 100); // 400% capped to 100%
    });
  });

  group('SD-5 Trigger Normalization', () {
    test('triggers present only if explicitly selected; default counters ignored', () {
      final today = DateTime(2026, 9, 20);

      // Log has caffeineCups = 3, but 'coffee' is NOT in triggers
      final log = createLog(
        date: today,
        caffeineCups: 3,
        triggers: ['alcohol'], // Only alcohol selected
        alcoholGlasses: 2,
      );

      final picture = engine.analyzeDay(log, today, today: today);

      // Coffee must NOT be present
      expect(picture.triggers.containsKey('coffee'), isFalse);
      // Alcohol MUST be present with quantity 2
      expect(picture.triggers.containsKey('alcohol'), isTrue);
      expect(picture.triggers['alcohol']!.quantity, 2.0);
      expect(picture.triggers['alcohol']!.unit, 'drinks'); // SD-5 normalized glasses -> drinks
    });

    test('merges legacy aliases and normalizes unit synonyms', () {
      final today = DateTime(2026, 9, 20);
      final log = createLog(
        date: today,
        triggers: ['t_caffeine'], // Legacy alias
        caffeineCups: 2,
      );

      final picture = engine.analyzeDay(log, today, today: today);

      // Merged into 'coffee'
      expect(picture.triggers.containsKey('coffee'), isTrue);
      expect(picture.triggers['coffee']!.displayName, 'Coffee / caffeine');
      expect(picture.triggers['coffee']!.quantity, 2.0);
      expect(picture.triggers['coffee']!.unit, 'cups');
    });
  });

  group('SD-6 Sleep Trust Gate', () {
    test('suppresses sleep when >= 70% of logged days share identical sleep duration', () {
      final today = DateTime(2026, 9, 20);
      // 10 logged days, 7 of them have 7.0 hours (70% identical)
      final logs = List.generate(10, (i) {
        return createLog(
          date: DateTime(2026, 9, 11 + i),
          sleepDuration: i < 7 ? 7.0 : (6.0 + i * 0.5),
        );
      });

      final result = engine.analyzeWindow(
        logs: logs,
        period: AnalysisPeriod.days30,
        today: today,
      );

      expect(result.identicalSleepPercent, 0.7);
      expect(result.isSleepTrusted, isFalse);
    });

    test('trusts sleep when identical duration is under 70%', () {
      final today = DateTime(2026, 9, 20);
      // 10 logged days, 6 have 7.0 hours (60% identical)
      final logs = List.generate(10, (i) {
        return createLog(
          date: DateTime(2026, 9, 11 + i),
          sleepDuration: i < 6 ? 7.0 : (5.0 + i * 0.5),
        );
      });

      final result = engine.analyzeWindow(
        logs: logs,
        period: AnalysisPeriod.days30,
        today: today,
      );

      expect(result.identicalSleepPercent, 0.6);
      expect(result.isSleepTrusted, isTrue);
    });
  });

  group('Chart Series (Daily & 90-Day Weekly)', () {
    test('daily chart series preserves null gaps for unlogged days', () {
      final today = DateTime(2026, 9, 20);
      final logs = [
        createLog(
          date: DateTime(2026, 9, 14), // Day 1 of 7-day window
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')],
        ),
        createLog(
          date: DateTime(2026, 9, 18),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')],
        ),
        // Sep 19 unlogged!
        createLog(
          date: DateTime(2026, 9, 20),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Severe')],
        ),
      ];

      final result = engine.analyzeWindow(
        logs: logs,
        period: AnalysisPeriod.days7,
        today: today,
      );

      final series = result.chartSeries;
      expect(series.isWeekly, isFalse);
      expect(series.points.length, 7);

      final sep18 = series.points.firstWhere((p) => p.date == DateTime(2026, 9, 18));
      final sep19 = series.points.firstWhere((p) => p.date == DateTime(2026, 9, 19));
      final sep20 = series.points.firstWhere((p) => p.date == DateTime(2026, 9, 20));

      expect(sep18.value, 1.0);
      expect(sep19.value, isNull); // Gap preserved, never zero or interpolated
      expect(sep20.value, 5.0);
    });

    test('90-day chart series groups by Monday-based weeks with null for empty weeks', () {
      final today = DateTime(2026, 9, 20); // Sunday
      // Provide logs in week 1 and week 3, week 2 empty
      final logs = [
        createLog(
          date: DateTime(2026, 9, 14), // Monday of week 1
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Moderate')], // 3.0
        ),
        createLog(
          date: DateTime(2026, 9, 16), // Wednesday of week 1
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Severe')], // 5.0
        ),
        // 90 days earlier log so history isn't clamped
        createLog(
          date: DateTime(2026, 6, 20),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')],
        ),
      ];

      final result = engine.analyzeWindow(
        logs: logs,
        period: AnalysisPeriod.days90,
        today: today,
      );

      final series = result.chartSeries;
      expect(series.isWeekly, isTrue);

      // Week of Sep 14 (Mon) to Sep 20 (Sun): average is (3.0 + 5.0) / 2 = 4.0
      final lastWeekPoint = series.points.last;
      expect(lastWeekPoint.date.weekday, DateTime.monday);
      expect(lastWeekPoint.value, 4.0);

      // A week prior with no logs should have value == null
      final emptyWeek = series.points[series.points.length - 2];
      expect(emptyWeek.value, isNull);
    });
  });

  group('Calendar-Week Comparison', () {
    test('compares Mon-K of current week against Mon-K of previous week', () {
      // Wednesday Sep 16, 2026
      final today = DateTime(2026, 9, 16);

      // Current week (Mon Sep 14 - Wed Sep 16)
      final currentLogs = [
        createLog(
          date: DateTime(2026, 9, 14), // Mon
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')], // 1.0
        ),
        createLog(
          date: DateTime(2026, 9, 16), // Wed
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')], // 1.0
        ),
      ];

      // Previous week same partial weekdays (Mon Sep 7 - Wed Sep 9)
      final prevLogs = [
        createLog(
          date: DateTime(2026, 9, 7), // Mon
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Severe')], // 5.0
        ),
        createLog(
          date: DateTime(2026, 9, 8), // Tue
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Severe')], // 5.0
        ),
        // Thu Sep 10 (should be excluded from Mon-Wed partial comparison!)
        createLog(
          date: DateTime(2026, 9, 10),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')],
        ),
      ];

      final comp = engine.compareCalendarWeeks(
        logs: [...currentLogs, ...prevLogs],
        today: today,
      );

      expect(comp.status, ComparisonStatus.eligible);
      // Current Mon-Wed average = 1.0, Previous Mon-Wed average = 5.0
      expect(comp.currentValue, 1.0);
      expect(comp.previousValue, 5.0);
      expect(comp.changeType, MaterialChangeType.improved);
      expect(comp.delta, -4.0);
    });
  });

  group('SD-7 Number Safety & Edge Cases', () {
    test('handles empty logs without NaN, infinity, or crash', () {
      final today = DateTime(2026, 9, 20);
      final result = engine.analyzeWindow(
        logs: const [],
        period: AnalysisPeriod.days7,
        today: today,
      );

      expect(result.loggedDaysCount, 0);
      expect(result.coverage, 0.0);
      expect(result.consistency, 0.0);
      expect(result.averageSeverity, isNull);
      expect(result.severityLabel, isNull);
      expect(result.symptomRankings, isEmpty);
      expect(result.severityComparison!.status, ComparisonStatus.notEnoughData);
      expect(result.isSleepTrusted, isTrue);
    });

    test('handles single completed log with 0 symptoms', () {
      final today = DateTime(2026, 9, 20);
      final log = createLog(date: today, symptoms: []);

      final result = engine.analyzeWindow(
        logs: [log],
        period: AnalysisPeriod.days7,
        today: today,
      );

      expect(result.loggedDaysCount, 1);
      expect(result.symptomFreeDaysCount, 1);
      // History is clamped to 1 day since only today exists
      expect(result.isHistoryClamped, isTrue);
      expect(result.daysOfData, 1);
      expect(result.coverage, 1.0);
      expect(result.averageSeverity, isNull);

      // When an earlier log exists 7 days ago, window spans full 7 days
      final earlierLog = createLog(date: DateTime(2026, 9, 14), symptoms: []);
      final result7Days = engine.analyzeWindow(
        logs: [earlierLog, log],
        period: AnalysisPeriod.days7,
        today: today,
      );
      expect(result7Days.isHistoryClamped, isFalse);
      expect(result7Days.calendarDaysInWindow, 7);
      expect(result7Days.loggedDaysCount, 2);
      expect(result7Days.coverage, closeTo(2 / 7, 0.001));
    });
  });
}
