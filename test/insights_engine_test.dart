import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/features/insights/services/correlation_engine.dart';
import 'package:eunora/features/insights/services/dose_change_analyzer.dart';
import 'package:eunora/features/insights/services/progress_estimator.dart';
import 'package:eunora/features/insights/providers/insights_provider.dart';

void main() {
  group('Pearson Correlation & CorrelationEngine Tests', () {
    test('Dataset 1: Hand-computed positive correlation check', () {
      final xSeries = [1.0, 1.0, 0.0, 0.0, 1.0, 0.0];
      final ySeries = [5.0, 4.0, 1.0, 2.0, 4.0, 2.0];

      final result = CorrelationEngine.calculate(xSeries: xSeries, ySeries: ySeries);

      // Hand computed r = 0.9428, effectSize = 2.6667, eventCount = 3
      expect(result.r, closeTo(0.9428, 0.001));
      expect(result.effectSize, closeTo(2.6667, 0.001));
      expect(result.eventCount, equals(3));
    });

    test('Dataset 2: Hand-computed negative correlation check', () {
      final xSeries = [1.0, 0.0, 1.0, 0.0];
      final ySeries = [1.0, 5.0, 1.0, 5.0];

      final result = CorrelationEngine.calculate(xSeries: xSeries, ySeries: ySeries);

      // Hand computed r = -1.0, effectSize = -4.0, eventCount = 2
      expect(result.r, closeTo(-1.0, 0.001));
      expect(result.effectSize, closeTo(-4.0, 0.001));
      expect(result.eventCount, equals(2));
    });

    test('Zero standard deviation (all values same) doesn\'t throw or yield NaN', () {
      final xSeries = [1.0, 1.0, 1.0];
      final ySeries = [3.0, 3.0, 3.0];

      final result = CorrelationEngine.calculate(xSeries: xSeries, ySeries: ySeries);

      expect(result.r, equals(0.0));
      expect(result.effectSize, equals(3.0));
      expect(result.eventCount, equals(3));
    });
  });

  group('Threshold Gating (eventCount 6 vs 7)', () {
    test('Exactly 6 events -> displayable=false', () {
      // 6 days of trigger and symptom presence
      final xSeries = List.generate(30, (i) => i < 6 ? 1.0 : 0.0);
      final ySeries = List.generate(30, (i) => i < 6 ? 3.0 : 0.0);

      final result = CorrelationEngine.calculate(xSeries: xSeries, ySeries: ySeries);
      expect(result.eventCount, equals(6));
      
      final bool displayable = result.eventCount >= 7;
      expect(displayable, isFalse);
    });

    test('Exactly 7 events -> displayable=true', () {
      // 7 days of trigger and symptom presence
      final xSeries = List.generate(30, (i) => i < 7 ? 1.0 : 0.0);
      final ySeries = List.generate(30, (i) => i < 7 ? 3.0 : 0.0);

      final result = CorrelationEngine.calculate(xSeries: xSeries, ySeries: ySeries);
      expect(result.eventCount, equals(7));

      final bool displayable = result.eventCount >= 7;
      expect(displayable, isTrue);
    });
  });

  group('Dose Change Analyzer & Boundary Tests', () {
    final DateTime changeDate = DateTime(2026, 6, 15);

    test('Boundary: 13 days post-change -> not shown (gating fails)', () {
      final DateTime evaluationDate = DateTime(2026, 6, 28); // 13 days post change
      final List<Map<String, dynamic>> logs = [];
      // Generate 8 logs in before period, 8 logs in after period
      for (int i = -14; i < 14; i++) {
        logs.add({
          'date': changeDate.add(Duration(days: i)),
          'symptoms': [
            {'id': 's_hot_flashes', 'intensity': 3.0}
          ]
        });
      }

      final result = DoseChangeAnalyzer.analyze(
        changeDate: changeDate,
        currentDate: evaluationDate,
        dailyLogs: logs,
        hrtHistoryDaysBefore: 14,
      );

      expect(result.isGatingMet, isFalse);
      expect(result.daysRemaining, equals(1));
    });

    test('Boundary: 14 days post-change -> shown (gating succeeds)', () {
      final DateTime evaluationDate = DateTime(2026, 6, 29); // 14 days post change
      final List<Map<String, dynamic>> logs = [];
      for (int i = -14; i < 14; i++) {
        logs.add({
          'date': changeDate.add(Duration(days: i)),
          'symptoms': [
            {'id': 's_hot_flashes', 'intensity': 3.0, 'name': 'Hot Flashes'}
          ]
        });
      }

      final result = DoseChangeAnalyzer.analyze(
        changeDate: changeDate,
        currentDate: evaluationDate,
        dailyLogs: logs,
        hrtHistoryDaysBefore: 14,
      );

      expect(result.isGatingMet, isTrue);
      expect(result.daysRemaining, equals(0));
      expect(result.symptomChanges.first.symptomId, equals('s_hot_flashes'));
    });
  });

  group('Progress Estimator Tests', () {
    test('Zero rate (no events in last 14 days) does not throw or return infinity', () {
      final result = ProgressEstimator.estimate(
        currentEvents: 3,
        targetEvents: 7,
        trailing14DayEvents: 0,
        triggerLabel: 'Caffeine',
      );

      expect(result.estimatedDaysRemaining, equals(999));
      expect(result.label, contains('some more time'));
    });

    test('Valid rate computes expected remaining days correctly', () {
      // 2 co-occurring events in last 14 days -> rate is 2/14 = 1/7 events per day.
      // Need 4 more events. daysRemaining = ceil(4 / (1/7)) = 28 days.
      final result = ProgressEstimator.estimate(
        currentEvents: 3,
        targetEvents: 7,
        trailing14DayEvents: 2,
        triggerLabel: 'Caffeine',
      );

      expect(result.estimatedDaysRemaining, equals(28));
      expect(result.label, contains('about 28 more days'));
    });
  });

  group('Isolate Pure Function Signature Check', () {
    test('Confirm performInsightsCalculation executes with serialized data structures', () {
      final input = {
        'dailyLogs': [
          {
            'date': DateTime(2026, 6, 10),
            'triggers': ['Caffeine: 1 cup'],
            'symptoms': [
              {'id': 's_hot_flashes', 'intensity': 4.0, 'severity': 'Moderate'}
            ]
          }
        ],
        'hrtDoseChanges': [],
        'triggerOptions': [
          {'id': 't_caffeine', 'name': 'Caffeine'}
        ],
        'symptomIds': ['s_hot_flashes'],
        'currentDate': DateTime(2026, 6, 11).toIso8601String(),
        'hrtHistoryDaysBefore': 14,
      };

      // Ensure this top level pure function can be called directly without throwing
      final results = performInsightsCalculation(input);
      expect(results, isNotNull);
      expect(results.length, greaterThan(0));
    });
  });
}
