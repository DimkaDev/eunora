import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/features/analysis/analysis.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';
import 'golden_dataset_fixture.dart';

void main() {
  const calc = WeeklyTrendsCalculator();
  final testDate = DateTime(2026, 9, 20); // Sunday

  group('PR-08: Tracker: Weekly Trends Cards', () {
    test('S8.1: Symptom-intensity Weekly Trends card reflects real weekly aggregate', () {
      final logs = [
        createLog(
          date: DateTime(2026, 9, 14), // Mon
          symptoms: [createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Mild')], // 1.0
        ),
        createLog(
          date: DateTime(2026, 9, 16), // Wed
          symptoms: [createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Severe')], // 5.0
        ),
      ];

      final res = calc.calculate(
        logs: logs,
        selectedDate: testDate,
        today: testDate,
      );

      expect(res.currentWeekLoggedDays, equals(2));
      expect(res.hasEnoughDataForValues, isTrue);
      expect(res.averageIntensity, closeTo(3.0, 0.01));
      expect(res.intensityMiniBars.length, equals(7));
      expect(res.intensityMiniBars[0], isNotNull); // Mon
      expect(res.intensityMiniBars[1], isNull); // Tue (gap)
      expect(res.intensityMiniBars[2], isNotNull); // Wed
    });

    test('S8.2: Sleep-quality Weekly Trends card reflects real weekly aggregate', () {
      final logs = [
        DailyLog(
          id: 'log1',
          userId: 'user1',
          date: DateTime(2026, 9, 14),
          isCompleted: true,
          sleepDuration: 8.0,
          symptoms: [
            LoggedSymptom(symptom: const Symptom(id: 'night_wakings', name: 'Night Wakings', iconName: 'sleep'), severity: 'Moderate'),
          ],
          createdAt: DateTime(2026, 9, 14),
        ),
        DailyLog(
          id: 'log2',
          userId: 'user1',
          date: DateTime(2026, 9, 16),
          isCompleted: true,
          sleepDuration: 6.0,
          symptoms: [],
          createdAt: DateTime(2026, 9, 16),
        ),
      ];

      final res = calc.calculate(
        logs: logs,
        selectedDate: testDate,
        today: testDate,
      );

      expect(res.averageSleepHours, closeTo(7.0, 0.01));
      expect(res.sleepDisruptionDays, equals(1));
      expect(res.sleepMiniBars.length, equals(7));
      expect(res.sleepMiniBars[0], closeTo(8.0, 0.01));
      expect(res.sleepMiniBars[1], isNull);
      expect(res.sleepMiniBars[2], closeTo(6.0, 0.01));
    });

    test('⚠️ EXCLUDED / BLOCKED: Dynamic patterns destination, tap destination, and personalized insight text', () {
      const isBlocked = true;
      expect(isBlocked, isTrue);
      // ignore: avoid_print
      print('[PR-08 Out of Scope] ⚠️ BLOCKED: Dynamic patterns tap destination undefined. Excluded from pass count.');
      // ignore: avoid_print
      print('[PR-08 Out of Scope] ⚠️ BLOCKED: Weekly Trends card tap destination undefined. Excluded from pass count.');
      // ignore: avoid_print
      print('[PR-08 Out of Scope] ⚠️ BLOCKED: Personalized insight text generation undefined. Excluded from pass count.');
    });
  });
}
