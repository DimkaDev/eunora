import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/features/analysis/analysis.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'golden_dataset_fixture.dart';

void main() {
  const calc = WeeklyTrendsCalculator();

  group('T6 Tracker Tests', () {
    test('T6-1: Compares same weekdays (Mon-Sat 14-19 Sep vs Mon-Sat 7-12 Sep)', () {
      final gLogs = goldenDatasetLogs();
      final data = calc.calculate(
        logs: gLogs,
        selectedDate: DateTime(2026, 9, 19),
        today: DateTime(2026, 9, 19),
      );
      expect(data.hasEnoughDataForValues, isTrue);
      expect(data.hasEnoughDataForComparison, isTrue);
    });

    test('T6-2 & T6-3 & T6-4 & T6-5: Value minimum (>= 2 days) and comparison minimum (>= 3 days in both)', () {
      final today = DateTime(2026, 9, 20); // Sunday
      // 1 logged day in current week -> value hidden
      final log1 = [createLog(date: DateTime(2026, 9, 14))];
      final res1 = calc.calculate(logs: log1, selectedDate: today, today: today);
      expect(res1.hasEnoughDataForValues, isFalse);
      expect(res1.intensityDisplay, '—');

      // 2 logged days in current week -> value shown, no comparison
      final log2 = [
        createLog(date: DateTime(2026, 9, 14), symptoms: [hotFlash('Moderate')]),
        createLog(date: DateTime(2026, 9, 15), symptoms: [hotFlash('Moderate')]),
      ];
      final res2 = calc.calculate(logs: log2, selectedDate: today, today: today);
      expect(res2.hasEnoughDataForValues, isTrue);
      expect(res2.hasEnoughDataForComparison, isFalse);

      // 3 in current, 2 in previous -> no comparison
      final log3curr2prev = [
        createLog(date: DateTime(2026, 9, 7)),
        createLog(date: DateTime(2026, 9, 8)),
        createLog(date: DateTime(2026, 9, 14)),
        createLog(date: DateTime(2026, 9, 15)),
        createLog(date: DateTime(2026, 9, 16)),
      ];
      final res3c2p = calc.calculate(logs: log3curr2prev, selectedDate: today, today: today);
      expect(res3c2p.hasEnoughDataForComparison, isFalse);

      // 3 in both -> comparison eligible
      final log3both = [
        createLog(date: DateTime(2026, 9, 7)),
        createLog(date: DateTime(2026, 9, 8)),
        createLog(date: DateTime(2026, 9, 9)),
        createLog(date: DateTime(2026, 9, 14)),
        createLog(date: DateTime(2026, 9, 15)),
        createLog(date: DateTime(2026, 9, 16)),
      ];
      final res3both = calc.calculate(logs: log3both, selectedDate: today, today: today);
      expect(res3both.hasEnoughDataForComparison, isTrue);
    });

    test('T6-6: Sleep change expressed in hours with "+/-0.X h"', () {
      final today = DateTime(2026, 9, 20);
      final logs = [
        // Prev week: 7.0, 7.0, 7.0 -> avg 7.0
        createLog(date: DateTime(2026, 9, 7), sleepDuration: 7.0),
        createLog(date: DateTime(2026, 9, 8), sleepDuration: 7.0),
        createLog(date: DateTime(2026, 9, 9), sleepDuration: 7.0),
        // Curr week: 7.4, 7.4, 7.4 -> avg 7.4 (+0.4 h)
        createLog(date: DateTime(2026, 9, 14), sleepDuration: 7.4),
        createLog(date: DateTime(2026, 9, 15), sleepDuration: 7.4),
        createLog(date: DateTime(2026, 9, 16), sleepDuration: 7.4),
      ];
      final res = calc.calculate(logs: logs, selectedDate: today, today: today);
      expect(res.sleepChangeDisplay, contains('h'));
      expect(res.sleepChangeHours, closeTo(0.4, 0.05));
    });

    test('T6-7: Sleep disruption counts days with night wakings or difficulty falling asleep', () {
      final today = DateTime(2026, 9, 20);
      final logs = [
        createLog(date: DateTime(2026, 9, 14), symptoms: [nightWakings('Moderate')]),
        createLog(date: DateTime(2026, 9, 15), symptoms: [difficultyFallingAsleep('Mild')]),
        createLog(date: DateTime(2026, 9, 16), symptoms: []),
      ];
      final res = calc.calculate(logs: logs, selectedDate: today, today: today);
      expect(res.sleepDisruptionDays, 2);
    });

    test('T6-8: Unlogged day preserves null slot in 7 mini-bars', () {
      final today = DateTime(2026, 9, 20);
      final logs = [
        createLog(date: DateTime(2026, 9, 14), symptoms: [hotFlash('Severe')]),
        // 15 Sep unlogged
        createLog(date: DateTime(2026, 9, 16), symptoms: [hotFlash('Mild')]),
      ];
      final res = calc.calculate(logs: logs, selectedDate: today, today: today);
      expect(res.intensityMiniBars.length, 7);
      expect(res.intensityMiniBars[1], isNull); // Tuesday 15 Sep
    });

    test('T6-13: Golden Dataset week 14-20 Sep calculations', () {
      final gLogs = goldenDatasetLogs();
      final res = calc.calculate(logs: gLogs, selectedDate: kToday, today: kToday);
      expect(res.currentWeekLoggedDays, 6);
      expect(res.previousWeekLoggedDays, 7);
      expect(res.hasEnoughDataForValues, isTrue);
      expect(res.hasEnoughDataForComparison, isTrue);
    });
  });
}
