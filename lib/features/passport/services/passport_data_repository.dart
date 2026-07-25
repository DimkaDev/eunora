import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eunora/core/services/firestore_service.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/home/domain/entities/hrt_dose_change.dart';
import 'package:eunora/features/onboarding/domain/models/user_profile.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';
import 'package:eunora/features/insights/models/insight_result.dart';
import 'package:eunora/features/passport/models/passport_data.dart';

class PassportDataRepository {
  final FirestoreService _firestoreService;

  PassportDataRepository(this._firestoreService);

  /// Assembles the unified PassportData DTO by fetching and aggregating raw data.
  Future<PassportData> fetchPassportData({
    required String uid,
    required DateTime startDate,
    required DateTime endDate,
    required UserProfile userProfile,
  }) async {
    // 1. Fetch raw logs history
    final List<DailyLog> rawLogs = await _firestoreService.getDailyLogsHistory(uid, startDate, endDate);
    final List<DailyLog> allLogs = rawLogs.where((l) => l.isCompleted).toList();
    
    // Sort logs oldest first
    allLogs.sort((a, b) => a.date.compareTo(b.date));

    // Earliest log date across all-time history
    final DateTime firstLogDate = allLogs.isEmpty ? startDate : allLogs.first.date;

    // Filter logs strictly within the selected report period
    final List<DailyLog> periodLogs = allLogs.where((log) {
      final logMidnight = DateTime(log.date.year, log.date.month, log.date.day);
      final startMidnight = DateTime(startDate.year, startDate.month, startDate.day);
      final endMidnight = DateTime(endDate.year, endDate.month, endDate.day);
      return (logMidnight.isAtSameMomentAs(startMidnight) || logMidnight.isAfter(startMidnight)) &&
             (logMidnight.isAtSameMomentAs(endMidnight) || logMidnight.isBefore(endMidnight));
    }).toList();

    // 2. Fetch Dose Changes
    final List<HrtDoseChange> changes = await _firestoreService.getHrtDoseChanges(uid);
    changes.sort((a, b) => a.changeDate.compareTo(b.changeDate));

    // 3. Current HRT Summary mapping
    final List<CurrentHrtSummary> currentHrt = [];
    final meds = userProfile.medications;
    for (final med in meds) {
      currentHrt.add(CurrentHrtSummary(
        drugName: med.name,
        doseValue: med.dose,
        doseUnit: med.unit,
        form: med.type.displayName,
        startDate: firstLogDate,
      ));
    }

    // 4. Section 2: Symptom Stats calculation
    final List<SymptomStatRow> symptomStats = _calculateSymptomStats(periodLogs, startDate, endDate);

    // 5. Section 3: Charts Data calculations
    final ChartData hotFlashFrequency = _calculateHotFlashChartData(periodLogs);
    final ChartData sleepQualityRollingAvg = _calculateSleepChartData(periodLogs);
    final ChartData moodStackedWeekly = _calculateMoodChartData(periodLogs, startDate, endDate);

    // 6. Section 4: Top persistent AI patterns from Firestore
    final List<InsightResult> topPatterns = await _fetchTopPatterns(uid);

    // 7. Section 5: HRT History & Impact
    final List<HrtPhase> hrtHistory = _calculateHrtHistory(allLogs, changes, firstLogDate);

    // 8. Section 6: Full Log Table rows
    final List<LogTableRow> fullLog = periodLogs.map((log) {
      final String symptomsStr = log.symptoms.map((s) {
        final double intensity = s.intensity?.toDouble() ?? (s.severity == 'Mild' ? 1.0 : s.severity == 'Moderate' ? 3.0 : 5.0);
        final dur = s.durationMinutes != null ? " (${s.durationMinutes} min)" : "";
        return "${s.symptom.name} ${intensity.toStringAsFixed(0)}/5$dur";
      }).join(', ');

      final String hrtStr = [
        if (log.estradiolChecked) "Estradiol: Yes" else "Estradiol: No",
        if (log.progesteroneChecked) "Progesterone: Yes" else "Progesterone: No",
      ].join(', ');

      return LogTableRow(
        date: log.date,
        time: log.estradiolTime.isNotEmpty ? log.estradiolTime : 'Logged',
        symptomsLogged: symptomsStr.isEmpty ? "None" : symptomsStr,
        hrtTaken: hrtStr,
        triggers: log.triggers.join(', '),
      );
    }).toList();

    final String derivedName = userProfile.email.isNotEmpty 
        ? userProfile.email.split('@').first 
        : "Sarah Johnson";
    final String formattedName = derivedName.isNotEmpty 
        ? derivedName[0].toUpperCase() + derivedName.substring(1) 
        : "Sarah";

    return PassportData(
      displayName: formattedName,
      dateOfBirth: DateTime(DateTime.now().year - userProfile.age, 1, 1),
      stage: userProfile.menopauseStage.name,
      firstLogDate: firstLogDate,
      reportStart: startDate,
      reportEnd: endDate,
      totalEntries: periodLogs.length,
      currentHrt: currentHrt,
      symptomStats: symptomStats,
      hotFlashFrequency: hotFlashFrequency,
      sleepQualityRollingAvg: sleepQualityRollingAvg,
      moodStackedWeekly: moodStackedWeekly,
      topPatterns: topPatterns,
      hrtHistory: hrtHistory,
      fullLog: fullLog,
      generatedAt: DateTime.now(),
    );
  }

  // --- Calculations Helpers ---

  List<SymptomStatRow> _calculateSymptomStats(List<DailyLog> logs, DateTime start, DateTime end) {
    final Map<String, List<double>> intensitiesBySymptom = {};
    final Map<String, List<MapEntry<DateTime, double>>> rawSymptomTimeSeries = {};
    final Map<String, String> symptomLabels = {};

    for (final log in logs) {
      for (final s in log.symptoms) {
        final id = s.symptom.id;
        final double intensity = s.intensity?.toDouble() ?? (s.severity == 'Mild' ? 1.0 : s.severity == 'Moderate' ? 3.0 : 5.0);
        intensitiesBySymptom.putIfAbsent(id, () => []).add(intensity);
        rawSymptomTimeSeries.putIfAbsent(id, () => []).add(MapEntry(log.date, intensity));
        symptomLabels[id] = s.symptom.name;
      }
    }

    final List<SymptomStatRow> rows = [];
    final midPeriod = start.add(Duration(days: end.difference(start).inDays ~/ 2));

    for (final entry in intensitiesBySymptom.entries) {
      final symptomId = entry.key;
      final label = symptomLabels[symptomId] ?? symptomId;
      final intensities = entry.value;

      final double avg = intensities.reduce((a, b) => a + b) / intensities.length;

      // Peak day calculation
      final timeSeries = rawSymptomTimeSeries[symptomId] ?? [];
      timeSeries.sort((a, b) => b.value.compareTo(a.value));
      final DateTime? peakDay = timeSeries.isNotEmpty ? timeSeries.first.key : null;

      // Trend calculation
      final firstHalf = timeSeries.where((e) => e.key.isBefore(midPeriod)).map((e) => e.value).toList();
      final secondHalf = timeSeries.where((e) => e.key.isAfter(midPeriod) || e.key.isAtSameMomentAs(midPeriod)).map((e) => e.value).toList();

      final double avgFirst = firstHalf.isEmpty ? 0.0 : firstHalf.reduce((a, b) => a + b) / firstHalf.length;
      final double avgSecond = secondHalf.isEmpty ? 0.0 : secondHalf.reduce((a, b) => a + b) / secondHalf.length;

      String trend = 'Stable';
      if (avgFirst > 0.0) {
        final change = (avgSecond - avgFirst) / avgFirst;
        if (change <= -0.05) {
          trend = 'Improving';
        } else if (change >= 0.05) {
          trend = 'Worsening';
        }
      } else if (avgSecond > 0.0) {
        trend = 'Worsening';
      }

      rows.add(SymptomStatRow(
        category: label,
        daysLogged: intensities.length,
        avgSeverity: avg,
        peakDay: peakDay,
        trend: trend,
      ));
    }

    return rows;
  }

  ChartData _calculateHotFlashChartData(List<DailyLog> logs) {
    final List<ChartDataPoint> points = [];
    for (final log in logs) {
      double intensity = 0.0;
      for (final s in log.symptoms) {
        if (s.symptom.id == 's_hot_flashes') {
          intensity = s.intensity?.toDouble() ?? (s.severity == 'Mild' ? 1.0 : s.severity == 'Moderate' ? 3.0 : 5.0);
          break;
        }
      }
      points.add(ChartDataPoint(date: log.date, value: intensity));
    }
    return ChartData(points: points);
  }

  ChartData _calculateSleepChartData(List<DailyLog> logs) {
    final List<ChartDataPoint> points = [];

    // Calculate 7-day rolling average for each daily log
    for (int i = 0; i < logs.length; i++) {
      final currentLog = logs[i];
      final limitDate = currentLog.date.subtract(const Duration(days: 7));

      // Get sleep duration values for logs in the trailing 7 days
      final trailingLogs = logs
          .where((l) => l.date.isAfter(limitDate) && (l.date.isBefore(currentLog.date) || l.date.isAtSameMomentAs(currentLog.date)))
          .map((l) => l.sleepDuration)
          .toList();

      final double avg = trailingLogs.isEmpty ? 0.0 : trailingLogs.reduce((a, b) => a + b) / trailingLogs.length;
      points.add(ChartDataPoint(date: currentLog.date, value: avg));
    }
    return ChartData(points: points);
  }

  ChartData _calculateMoodChartData(List<DailyLog> logs, DateTime start, DateTime end) {
    final List<WeeklyMoodPoint> weeklyPoints = [];
    final int totalDays = end.difference(start).inDays;
    final int totalWeeks = (totalDays / 7).ceil().clamp(1, 15);

    for (int w = 0; w < totalWeeks; w++) {
      final weekStart = start.add(Duration(days: w * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));

      final weekLogs = logs.where((l) {
        final midnight = DateTime(l.date.year, l.date.month, l.date.day);
        return (midnight.isAtSameMomentAs(weekStart) || midnight.isAfter(weekStart)) && midnight.isBefore(weekEnd);
      }).toList();

      double sumAnxiety = 0.0;
      double sumIrritability = 0.0;
      double sumBrainFog = 0.0;

      for (final log in weekLogs) {
        for (final s in log.symptoms) {
          final id = s.symptom.id;
          final double val = s.intensity?.toDouble() ?? (s.severity == 'Mild' ? 1.0 : s.severity == 'Moderate' ? 3.0 : 5.0);
          if (id == 's_mood' || id == 's_anxiety') sumAnxiety += val;
          else if (id == 's_irritability') sumIrritability += val;
          else if (id == 's_brain_fog') sumBrainFog += val;
        }
      }

      final int denom = weekLogs.isEmpty ? 1 : weekLogs.length;

      weeklyPoints.add(WeeklyMoodPoint(
        weekStart: weekStart,
        anxiety: sumAnxiety / denom,
        irritability: sumIrritability / denom,
        brainFog: sumBrainFog / denom,
      ));
    }

    return ChartData(points: const [], weeklyMoods: weeklyPoints);
  }

  Future<List<InsightResult>> _fetchTopPatterns(String uid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('correlations')
        .where('direction', isNull: false)
        .get();

    final List<InsightResult> list = snapshot.docs
        .map((doc) => InsightResult.fromJson(doc.data()))
        .toList();

    // Sort by correlation strength descending
    list.sort((a, b) => (b.correlationPercent ?? 0).compareTo(a.correlationPercent ?? 0));

    // Limit to top 5
    return list.take(5).toList();
  }

  List<HrtPhase> _calculateHrtHistory(List<DailyLog> logs, List<HrtDoseChange> changes, DateTime trackingStart) {
    final List<HrtPhase> phases = [];
    if (changes.isEmpty) {
      // Single continuous phase
      final int duration = DateTime.now().difference(trackingStart).inDays.clamp(1, 9999);
      final double avgHotFlashes = _calculateAvgSymptom(logs, trackingStart, DateTime.now(), 's_hot_flashes');
      final double avgSleep = _calculateAvgSymptom(logs, trackingStart, DateTime.now(), 'sleep');

      phases.add(HrtPhase(
        periodLabel: "Phase 1",
        drugName: "Estradiol",
        dose: 50.0,
        unit: "mcg",
        durationDays: duration,
        observedEffect: "Hot flashes avg ${avgHotFlashes.toStringAsFixed(1)}/day · Sleep duration ${avgSleep.toStringAsFixed(1)}h",
        isDoseChangeMarker: false,
      ));
      return phases;
    }

    DateTime phaseStart = trackingStart;
    for (int i = 0; i < changes.length; i++) {
      final change = changes[i];
      final DateTime phaseEnd = change.changeDate.subtract(const Duration(days: 1));

      final int duration = phaseEnd.difference(phaseStart).inDays.clamp(1, 9999);
      final double avgHotFlashes = _calculateAvgSymptom(logs, phaseStart, phaseEnd, 's_hot_flashes');
      final double avgSleep = _calculateAvgSymptom(logs, phaseStart, phaseEnd, 'sleep');

      phases.add(HrtPhase(
        periodLabel: "Phase ${i + 1}",
        drugName: change.medicationName,
        dose: change.oldDose,
        unit: change.unit,
        durationDays: duration,
        observedEffect: "Hot flashes avg ${avgHotFlashes.toStringAsFixed(1)}/day · Sleep duration ${avgSleep.toStringAsFixed(1)}h",
        isDoseChangeMarker: false,
      ));

      // Dose Change Marker
      phases.add(HrtPhase(
        periodLabel: "",
        drugName: change.medicationName,
        dose: change.newDose,
        unit: change.unit,
        durationDays: 0,
        observedEffect: "",
        isDoseChangeMarker: true,
        changeDirection: change.newDose > change.oldDose ? 'increased' : 'decreased',
        changeReason: "Dose change from ${change.oldDose} to ${change.newDose}",
        changeDate: change.changeDate,
      ));

      phaseStart = change.changeDate;
    }

    // Add final phase
    final int finalDuration = DateTime.now().difference(phaseStart).inDays.clamp(1, 9999);
    final double avgHotFlashes = _calculateAvgSymptom(logs, phaseStart, DateTime.now(), 's_hot_flashes');
    final double avgSleep = _calculateAvgSymptom(logs, phaseStart, DateTime.now(), 'sleep');
    final lastChange = changes.last;

    phases.add(HrtPhase(
      periodLabel: "Phase ${changes.length + 1}",
      drugName: lastChange.medicationName,
      dose: lastChange.newDose,
      unit: lastChange.unit,
      durationDays: finalDuration,
      observedEffect: "Hot flashes avg ${avgHotFlashes.toStringAsFixed(1)}/day · Sleep duration ${avgSleep.toStringAsFixed(1)}h",
      isDoseChangeMarker: false,
    ));

    return phases;
  }

  double _calculateAvgSymptom(List<DailyLog> logs, DateTime start, DateTime end, String type) {
    final filtered = logs.where((l) {
      final mid = DateTime(l.date.year, l.date.month, l.date.day);
      final sMid = DateTime(start.year, start.month, start.day);
      final eMid = DateTime(end.year, end.month, end.day);
      return (mid.isAtSameMomentAs(sMid) || mid.isAfter(sMid)) && (mid.isAtSameMomentAs(eMid) || mid.isBefore(eMid));
    }).toList();

    if (filtered.isEmpty) return 0.0;

    double sum = 0.0;
    for (final log in filtered) {
      if (type == 'sleep') {
        sum += log.sleepDuration;
      } else {
        double intensity = 0.0;
        for (final s in log.symptoms) {
          if (s.symptom.id == type) {
            intensity = s.intensity?.toDouble() ?? (s.severity == 'Mild' ? 1.0 : s.severity == 'Moderate' ? 3.0 : 5.0);
            break;
          }
        }
        sum += intensity;
      }
    }
    return sum / filtered.length;
  }
}
