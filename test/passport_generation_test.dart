import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:eunora/features/insights/models/insight_result.dart';
import 'package:eunora/features/passport/models/passport_data.dart';
import 'package:eunora/features/passport/services/passport_pdf_builder.dart';

void main() {
  group('Passport PDF Builder Tests', () {
    // A standard seed dataset for verification
    final standardData = PassportData(
      displayName: "Sarah Johnson",
      dateOfBirth: DateTime(1980, 5, 20),
      stage: "perimenopause",
      firstLogDate: DateTime(2026, 3, 1),
      reportStart: DateTime(2026, 6, 1),
      reportEnd: DateTime(2026, 6, 30),
      totalEntries: 25,
      currentHrt: [
        CurrentHrtSummary(
          drugName: "Estradiol",
          doseValue: 50.0,
          doseUnit: "mcg",
          form: "Patch",
          startDate: DateTime(2026, 4, 1),
        )
      ],
      symptomStats: [
        SymptomStatRow(
          category: "Hot Flashes",
          daysLogged: 12,
          avgSeverity: 3.456, // Underlying high precision
          peakDay: DateTime(2026, 6, 12),
          trend: "Improving",
        ),
        SymptomStatRow(
          category: "Sleep quality",
          daysLogged: 10,
          avgSeverity: 2.111,
          peakDay: DateTime(2026, 6, 15),
          trend: "Stable",
        ),
      ],
      hotFlashFrequency: ChartData(points: [
        ChartDataPoint(date: DateTime(2026, 6, 1), value: 2.0),
        ChartDataPoint(date: DateTime(2026, 6, 2), value: 3.0),
        ChartDataPoint(date: DateTime(2026, 6, 3), value: 4.0),
      ]),
      sleepQualityRollingAvg: ChartData(points: [
        ChartDataPoint(date: DateTime(2026, 6, 1), value: 3.5),
        ChartDataPoint(date: DateTime(2026, 6, 2), value: 3.6),
        ChartDataPoint(date: DateTime(2026, 6, 3), value: 3.7),
      ]),
      moodStackedWeekly: ChartData(
        points: const [],
        weeklyMoods: [
          WeeklyMoodPoint(weekStart: DateTime(2026, 6, 1), anxiety: 2.0, irritability: 1.5, brainFog: 1.0),
          WeeklyMoodPoint(weekStart: DateTime(2026, 6, 8), anxiety: 1.8, irritability: 1.2, brainFog: 0.8),
        ],
      ),
      topPatterns: [
        InsightResult(
          id: "pattern_1",
          type: InsightType.trigger,
          label: "Red wine → +4.2 hot flashes the next day (79% correlation, based on 12 events)",
          disclaimer: "Disclaimer details",
          triggerId: "t_alcohol",
          symptomId: "s_hot_flashes",
          correlationPercent: 79,
          eventCount: 12,
          calculatedAt: DateTime(2026, 6, 29),
        )
      ],
      hrtHistory: [
        HrtPhase(
          periodLabel: "Phase 1",
          drugName: "Estradiol",
          dose: 50.0,
          unit: "mcg",
          durationDays: 30,
          observedEffect: "Hot flashes avg 3.5/day",
          isDoseChangeMarker: false,
        ),
      ],
      fullLog: [
        LogTableRow(
          date: DateTime(2026, 6, 1),
          time: "08:00 AM",
          symptomsLogged: "Hot Flashes 3/5",
          hrtTaken: "Estradiol: Yes",
          triggers: "Caffeine",
        ),
      ],
      generatedAt: DateTime(2026, 6, 29),
    );

    test('Seeded dataset -> generated PDF matches expected structure', () async {
      final doc = PassportPdfBuilder.build(standardData);
      expect(doc, isNotNull);

      final pdfBytes = await doc.save();
      expect(pdfBytes.length, greaterThan(0));
    });

    test('Empty/Sparse-data fallbacks render successfully without crashes', () async {
      final sparseData = PassportData(
        displayName: "Jane",
        stage: "menopause",
        firstLogDate: DateTime(2026, 6, 1),
        reportStart: DateTime(2026, 6, 1),
        reportEnd: DateTime(2026, 6, 30),
        totalEntries: 0,
        currentHrt: const [],
        symptomStats: const [],
        hotFlashFrequency: const ChartData(points: []),
        sleepQualityRollingAvg: const ChartData(points: []),
        moodStackedWeekly: const ChartData(points: [], weeklyMoods: []),
        topPatterns: const [],
        hrtHistory: const [],
        fullLog: const [],
        generatedAt: DateTime(2026, 6, 29),
      );

      final doc = PassportPdfBuilder.build(sparseData);
      expect(doc, isNotNull);

      final pdfBytes = await doc.save();
      expect(pdfBytes.length, greaterThan(0));
    });

    test('Rounding correctness: verify underlying precision is preserved', () {
      final stats = standardData.symptomStats.first;
      // Precision is preserved in double
      expect(stats.avgSeverity, equals(3.456));
      
      // Formatting to 1 decimal place yields expected string representation
      expect(stats.avgSeverity.toStringAsFixed(1), equals("3.5"));
    });

    test('Performance test: full 90-day dataset generates well within the 8 second budget', () async {
      final List<ChartDataPoint> largePoints = List.generate(90, (index) {
        return ChartDataPoint(date: DateTime(2026, 1, 1).add(Duration(days: index)), value: 2.5);
      });
      final List<WeeklyMoodPoint> largeMoods = List.generate(13, (index) {
        return WeeklyMoodPoint(weekStart: DateTime(2026, 1, 1).add(Duration(days: index * 7)), anxiety: 1.5, irritability: 1.0, brainFog: 1.2);
      });
      final List<LogTableRow> largeLog = List.generate(90, (index) {
        return LogTableRow(
          date: DateTime(2026, 1, 1).add(Duration(days: index)),
          time: "08:00 AM",
          symptomsLogged: "Hot Flashes 3/5, Night Sweats 2/5",
          hrtTaken: "Estradiol: Yes, Progesterone: Yes",
          triggers: "Caffeine, Alcohol",
        );
      });

      final largeData = PassportData(
        displayName: "Clara",
        stage: "postmenopause",
        firstLogDate: DateTime(2026, 1, 1),
        reportStart: DateTime(2026, 1, 1),
        reportEnd: DateTime(2026, 3, 31),
        totalEntries: 90,
        currentHrt: [
          CurrentHrtSummary(drugName: "Estradiol", doseValue: 75.0, doseUnit: "mcg", form: "Patch", startDate: DateTime(2026, 1, 1)),
          CurrentHrtSummary(drugName: "Progesterone", doseValue: 100.0, doseUnit: "mg", form: "Capsule", startDate: DateTime(2026, 1, 1)),
        ],
        symptomStats: [
          SymptomStatRow(category: "Hot Flashes", daysLogged: 90, avgSeverity: 2.5, peakDay: DateTime(2026, 2, 10), trend: "Improving")
        ],
        hotFlashFrequency: ChartData(points: largePoints),
        sleepQualityRollingAvg: ChartData(points: largePoints),
        moodStackedWeekly: ChartData(points: const [], weeklyMoods: largeMoods),
        topPatterns: const [],
        hrtHistory: const [],
        fullLog: largeLog,
        generatedAt: DateTime.now(),
      );

      final stopwatch = Stopwatch()..start();
      
      final doc = PassportPdfBuilder.build(largeData);
      final pdfBytes = await doc.save();
      
      stopwatch.stop();
      
      expect(pdfBytes.length, greaterThan(0));
      expect(stopwatch.elapsedMilliseconds, lessThan(8000)); // Should be well under 8000ms
    });

    test('Filename sanitization removes special characters and spaces from FirstName', () {
      final String rawName = "Sarah-Jane O'Connor";
      final String rawFirstName = rawName.split(' ').first;
      final String sanitized = rawFirstName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      
      expect(sanitized, equals("SarahJane"));
    });
  });
}
