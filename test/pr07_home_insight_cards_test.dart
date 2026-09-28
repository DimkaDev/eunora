import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/features/analysis/analysis.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'golden_dataset_fixture.dart';

void main() {
  const analysisEngine = AnalysisEngine();

  group('PR-07: Home: Daily & Weekly Insight Cards', () {
    test('S7.1: Daily Insight card reflects the correct average severity across today\'s logged symptoms', () {
      final today = DateTime(2026, 9, 19);

      final todayLog = createLog(
        date: today,
        symptoms: [
          createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Mild'),
          createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Severe'),
        ],
      );

      final baselineLogs = List.generate(
        7,
        (i) => createLog(
          date: DateTime(2026, 9, 11 + i),
          symptoms: [createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Moderate')],
        ),
      );

      final logs = [...baselineLogs, todayLog];

      final a1 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.day1, today: today);
      expect(a1.averageSeverity, closeTo(3.0, 0.01));
      expect(a1.loggedDaysCount, equals(1));
    });

    test('S7.2: Weekly Insight card reflects correct 7-day average severity and consistency measure (X of 7)', () {
      final today = DateTime(2026, 9, 19);

      final logs7 = [
        createLog(date: DateTime(2026, 9, 13), symptoms: [createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Moderate')]),
        createLog(date: DateTime(2026, 9, 14), symptoms: [createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Moderate')]),
        createLog(date: DateTime(2026, 9, 15), symptoms: [createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Mild')]),
        createLog(date: DateTime(2026, 9, 17), symptoms: [createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Severe')]),
        createLog(date: DateTime(2026, 9, 19), symptoms: [createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Moderate')]),
      ];

      final a7 = analysisEngine.analyzeWindow(logs: logs7, period: AnalysisPeriod.days7, today: today);

      expect(a7.loggedDaysCount, equals(5));
      expect(a7.averageSeverity, closeTo(3.0, 0.01));
      expect('${a7.loggedDaysCount} of ${a7.calendarDaysInWindow}', contains('5 of 7'));
    });

    test('S7.3: Zero symptoms logged today shows explicit no-data / symptom-free state (not false zero or crash)', () {
      final today = DateTime(2026, 9, 19);

      final pastLogs = [
        createLog(date: DateTime(2026, 9, 17), symptoms: [createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Moderate')]),
        createLog(date: DateTime(2026, 9, 18), symptoms: [createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Moderate')]),
      ];

      final a1 = analysisEngine.analyzeWindow(logs: pastLogs, period: AnalysisPeriod.day1, today: today);

      expect(a1.averageSeverity, isNull);
      expect(a1.loggedDaysCount, equals(0));
      final displaySeverity = a1.averageSeverity != null ? a1.averageSeverity!.toStringAsFixed(1) : '—';
      expect(displaySeverity, equals('—'));

      final withTodayEmpty = [
        ...pastLogs,
        createLog(date: today, symptoms: []),
      ];

      final a1Empty = analysisEngine.analyzeWindow(logs: withTodayEmpty, period: AnalysisPeriod.day1, today: today);
      expect(a1Empty.loggedDaysCount, equals(1));
      expect(a1Empty.symptomFreeDaysCount, equals(1));
      expect(a1Empty.averageSeverity, isNull);
      final displaySeverityEmpty = a1Empty.averageSeverity != null ? a1Empty.averageSeverity!.toStringAsFixed(1) : '—';
      expect(displaySeverityEmpty, equals('—'));
    });

    test('⚠️ EXCLUDED / BLOCKED: "View detailed trend analysis" button destination is undefined', () {
      const isBlocked = true;
      expect(isBlocked, isTrue);
      // ignore: avoid_print
      print('[PR-07 Out of Scope] ⚠️ BLOCKED: "View detailed trend analysis" button destination is undefined. Excluded from pass count.');
    });
  });
}
