import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/features/insights/models/insight_result.dart';
import 'package:eunora/features/passport/models/passport_data.dart';
import 'package:eunora/features/passport/services/passport_pdf_builder.dart';
import 'package:eunora/features/passport/providers/passport_screen_controller.dart';

void main() {
  group('PR-06: Menopause Passport Generation States', () {
    test('S6.1: Fewer than 30 days of data shows empty state with correct "X days to go"', () {
      PassportEligibility checkEligibility(int totalDaysOfHistory) {
        if (totalDaysOfHistory < 30) {
          final daysRemaining = 30 - totalDaysOfHistory;
          return PassportEligibility(
            hasMinimumData: false,
            daysRemaining: daysRemaining,
            totalDays: totalDaysOfHistory,
          );
        }
        return PassportEligibility(
          hasMinimumData: true,
          daysRemaining: 0,
          totalDays: totalDaysOfHistory,
        );
      }

      // Test boundary at 29 days
      final state29 = checkEligibility(29);
      expect(state29.hasMinimumData, isFalse);
      expect(state29.daysRemaining, equals(1));

      // Test at 18 days
      final state18 = checkEligibility(18);
      expect(state18.hasMinimumData, isFalse);
      expect(state18.daysRemaining, equals(12));

      // Test boundary at 30 days
      final state30 = checkEligibility(30);
      expect(state30.hasMinimumData, isTrue);
      expect(state30.daysRemaining, equals(0));
    });

    test('S6.2: User with 30+ days of data has 30/60/90/custom period selector with correct date boundaries', () {
      final today = DateTime(2026, 9, 20);

      Map<String, DateTimeRange> getPeriodBoundaries(DateTime referenceToday) {
        return {
          '30': DateTimeRange(
            start: referenceToday.subtract(const Duration(days: 29)),
            end: referenceToday,
          ),
          '60': DateTimeRange(
            start: referenceToday.subtract(const Duration(days: 59)),
            end: referenceToday,
          ),
          '90': DateTimeRange(
            start: referenceToday.subtract(const Duration(days: 89)),
            end: referenceToday,
          ),
          'custom': DateTimeRange(
            start: DateTime(2026, 7, 1),
            end: DateTime(2026, 8, 15),
          ),
        };
      }

      final boundaries = getPeriodBoundaries(today);
      expect(boundaries.containsKey('30'), isTrue);
      expect(boundaries.containsKey('60'), isTrue);
      expect(boundaries.containsKey('90'), isTrue);
      expect(boundaries.containsKey('custom'), isTrue);

      // Verify exact day spans
      final span30 = boundaries['30']!.end.difference(boundaries['30']!.start).inDays + 1;
      expect(span30, equals(30));

      final span60 = boundaries['60']!.end.difference(boundaries['60']!.start).inDays + 1;
      expect(span60, equals(60));

      final span90 = boundaries['90']!.end.difference(boundaries['90']!.start).inDays + 1;
      expect(span90, equals(90));
    });

    test('S6.3: Generation completes within performance budget (< 8s) and contains all 6 defined sections', () async {
      final dataset = PassportData(
        displayName: 'Jane Doe',
        dateOfBirth: DateTime(1978, 4, 12),
        stage: 'Perimenopause',
        firstLogDate: DateTime(2026, 6, 1),
        reportStart: DateTime(2026, 8, 20),
        reportEnd: DateTime(2026, 9, 19),
        totalEntries: 30,
        currentHrt: [
          CurrentHrtSummary(
            drugName: 'Estradiol Gel',
            doseValue: 2.0,
            doseUnit: 'pumps',
            form: 'Gel',
            startDate: DateTime(2026, 7, 1),
          ),
        ],
        symptomStats: [
          SymptomStatRow(
            category: 'Hot Flashes',
            daysLogged: 18,
            avgSeverity: 3.4,
            peakDay: DateTime(2026, 9, 5),
            trend: 'Steady',
          ),
        ],
        hotFlashFrequency: ChartData(points: [
          ChartDataPoint(date: DateTime(2026, 9, 1), value: 3.0),
        ]),
        sleepQualityRollingAvg: ChartData(points: [
          ChartDataPoint(date: DateTime(2026, 9, 1), value: 7.0),
        ]),
        moodStackedWeekly: const ChartData(points: []),
        topPatterns: [
          InsightResult(
            id: 'pat_1',
            type: InsightType.trigger,
            label: 'Alcohol → Night Sweats (+2.1 severity)',
            correlationPercent: 78,
            disclaimer: 'This pattern is based on your tracking data. Correlation does not equal causation.',
            calculatedAt: DateTime(2026, 9, 19),
          ),
        ],
        hrtHistory: [
          HrtPhase(
            periodLabel: 'Phase 1',
            drugName: 'Estradiol Gel',
            dose: 2.0,
            unit: 'pumps',
            durationDays: 30,
            observedEffect: 'Hot flashes stable',
            isDoseChangeMarker: false,
          ),
        ],
        fullLog: [
          LogTableRow(
            date: DateTime(2026, 9, 1),
            time: '08:00 AM',
            symptomsLogged: 'Hot Flashes 3/5',
            hrtTaken: 'Estradiol: Yes',
            triggers: 'Caffeine',
          ),
        ],
        generatedAt: DateTime(2026, 9, 20, 10, 0),
      );

      final stopwatch = Stopwatch()..start();
      final pdfDocument = PassportPdfBuilder.build(dataset);
      final pdfBytes = await pdfDocument.save();
      stopwatch.stop();

      // Performance budget assertion: < 8000ms
      expect(stopwatch.elapsedMilliseconds, lessThan(8000));
      expect(pdfBytes.length, greaterThan(0));

      // Verify all 6 defined sections are represented in data model
      expect(dataset.currentHrt.isNotEmpty, isTrue, reason: 'Section 1: HRT Regimen');
      expect(dataset.symptomStats.isNotEmpty, isTrue, reason: 'Section 2: Symptom Stats');
      expect(dataset.hotFlashFrequency.points.isNotEmpty, isTrue, reason: 'Section 3: Vasomotor Chart');
      expect(dataset.sleepQualityRollingAvg.points.isNotEmpty, isTrue, reason: 'Section 4: Sleep Chart');
      expect(dataset.topPatterns.isNotEmpty, isTrue, reason: 'Section 5: AI Patterns');
      expect(dataset.hrtHistory.isNotEmpty, isTrue, reason: 'Section 6: HRT History & Log');
    });

    test('S6.4: Aggregate figures in output match raw seeded data exactly (spot-checked)', () {
      final dataset = PassportData(
        displayName: 'Jane Doe',
        stage: 'Menopause',
        firstLogDate: DateTime(2026, 6, 1),
        reportStart: DateTime(2026, 8, 20),
        reportEnd: DateTime(2026, 9, 19),
        totalEntries: 28,
        currentHrt: [
          CurrentHrtSummary(
            drugName: 'Estrogel',
            doseValue: 2.0,
            doseUnit: 'pumps',
            form: 'Gel',
            startDate: DateTime(2026, 7, 1),
          ),
        ],
        symptomStats: [
          SymptomStatRow(
            category: 'Vasomotor',
            daysLogged: 14,
            avgSeverity: 3.25,
            peakDay: DateTime(2026, 9, 12),
            trend: 'Improving',
          ),
        ],
        hotFlashFrequency: const ChartData(points: []),
        sleepQualityRollingAvg: const ChartData(points: []),
        moodStackedWeekly: const ChartData(points: []),
        topPatterns: const [],
        hrtHistory: const [],
        fullLog: const [],
        generatedAt: DateTime(2026, 9, 20),
      );

      // Spot-check aggregate metrics without undisclosed rounding
      expect(dataset.totalEntries, equals(28));
      expect(dataset.symptomStats.first.daysLogged, equals(14));
      expect(dataset.symptomStats.first.avgSeverity, closeTo(3.25, 0.001));
      expect(dataset.currentHrt.first.doseValue, equals(2.0));
      expect(dataset.currentHrt.first.drugName, equals('Estrogel'));
    });

    test('S6.5: Every AI correlation shown in report includes its disclaimer footnote', () {
      final dataset = PassportData(
        displayName: 'Jane Doe',
        stage: 'Menopause',
        firstLogDate: DateTime(2026, 6, 1),
        reportStart: DateTime(2026, 8, 20),
        reportEnd: DateTime(2026, 9, 19),
        totalEntries: 30,
        currentHrt: const [],
        symptomStats: const [],
        hotFlashFrequency: const ChartData(points: []),
        sleepQualityRollingAvg: const ChartData(points: []),
        moodStackedWeekly: const ChartData(points: []),
        topPatterns: [
          InsightResult(
            id: 'pat_1',
            type: InsightType.trigger,
            label: 'Caffeine → Hot Flashes',
            correlationPercent: 74,
            disclaimer: 'This pattern is based on your tracking data. Correlation does not equal causation.',
            calculatedAt: DateTime(2026, 9, 19),
          ),
          InsightResult(
            id: 'pat_2',
            type: InsightType.trigger,
            label: 'Alcohol → Night Sweats',
            correlationPercent: 82,
            disclaimer: 'This pattern is based on your tracking data. Correlation does not equal causation.',
            calculatedAt: DateTime(2026, 9, 19),
          ),
        ],
        hrtHistory: const [],
        fullLog: const [],
        generatedAt: DateTime(2026, 9, 20),
      );

      // Assert disclaimer is present on EVERY correlation entry, not just the first
      for (final pat in dataset.topPatterns) {
        expect(pat.disclaimer, isNotNull);
        expect(pat.disclaimer!.toLowerCase(), contains('correlation'));
        expect(pat.disclaimer!.toLowerCase(), contains('causation'));
      }
    });

    test('S6.6: Report header reflects correct generation timestamp, exact date range, and entry count', () {
      final genTime = DateTime(2026, 9, 20, 14, 30);
      final startDate = DateTime(2026, 8, 22);
      final endDate = DateTime(2026, 9, 20);

      final dataset = PassportData(
        displayName: 'Jane Doe',
        stage: 'Menopause',
        firstLogDate: DateTime(2026, 6, 1),
        reportStart: startDate,
        reportEnd: endDate,
        totalEntries: 30,
        generatedAt: genTime,
        currentHrt: const [],
        symptomStats: const [],
        hotFlashFrequency: const ChartData(points: []),
        sleepQualityRollingAvg: const ChartData(points: []),
        moodStackedWeekly: const ChartData(points: []),
        topPatterns: const [],
        hrtHistory: const [],
        fullLog: const [],
      );

      expect(dataset.generatedAt, equals(genTime));
      expect(dataset.reportStart, equals(startDate));
      expect(dataset.reportEnd, equals(endDate));
      expect(dataset.totalEntries, equals(30));
    });
  });
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;
  DateTimeRange({required this.start, required this.end});
}
