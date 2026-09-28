import '../../home/domain/entities/daily_log.dart';
import '../../symptom_log/data/symptom_library.dart';
import '../domain/models/period_comparison.dart';
import 'analysis_engine.dart';
import 'symptom_categorizer.dart';

DateTime _normalizeDate(DateTime dt) => AnalysisEngine.normalizeDate(dt);
DateTime _addDays(DateTime dt, int days) => dt.add(Duration(days: days));

/// Holds computed weekly trend data for a specific calendar week (Mon–Sun).
class WeeklyTrendsData {
  final DateTime weekStart; // Monday
  final DateTime weekEnd; // Sunday
  final int currentWeekLoggedDays;
  final int previousWeekLoggedDays;

  // Stated minimums
  final bool hasEnoughDataForValues; // >= 2 logged days in week
  final bool hasEnoughDataForComparison; // >= 3 in both weeks

  // Symptom Intensity
  final double? averageIntensity;
  final String? intensitySeverityLabel;
  final String intensityDisplay;
  final MetricComparison? intensityComparison;
  final String intensityChangeDisplay;
  final bool? isIntensityImproved;
  final List<double?> intensityMiniBars; // 7 slots (Mon..Sun); null = empty slot

  // Sleep (hours)
  final double? averageSleepHours;
  final String sleepDisplay;
  final double? sleepChangeHours;
  final String sleepChangeDisplay;
  final bool? isSleepImproved;
  final int sleepDisruptionDays;
  final List<double?> sleepMiniBars; // 7 slots (Mon..Sun); null = empty slot

  const WeeklyTrendsData({
    required this.weekStart,
    required this.weekEnd,
    required this.currentWeekLoggedDays,
    required this.previousWeekLoggedDays,
    required this.hasEnoughDataForValues,
    required this.hasEnoughDataForComparison,
    this.averageIntensity,
    this.intensitySeverityLabel,
    required this.intensityDisplay,
    this.intensityComparison,
    required this.intensityChangeDisplay,
    this.isIntensityImproved,
    required this.intensityMiniBars,
    this.averageSleepHours,
    required this.sleepDisplay,
    this.sleepChangeHours,
    required this.sleepChangeDisplay,
    this.isSleepImproved,
    required this.sleepDisruptionDays,
    required this.sleepMiniBars,
  });
}

/// Service that computes weekly trend metrics comparing a calendar week
/// to the previous week by same weekdays per Task 6 specifications.
class WeeklyTrendsCalculator {
  final AnalysisEngine _engine;
  final SymptomCategorizer _categorizer;

  const WeeklyTrendsCalculator({
    AnalysisEngine engine = const AnalysisEngine(),
    SymptomCategorizer categorizer = const SymptomCategorizer(),
  })  : _engine = engine,
        _categorizer = categorizer;

  /// Computes weekly trend metrics for the week containing [selectedDate].
  WeeklyTrendsData calculate({
    required List<DailyLog> logs,
    required DateTime selectedDate,
    DateTime? today,
  }) {
    final refToday = _normalizeDate(today ?? DateTime.now());
    final normSelected = _normalizeDate(selectedDate);

    // Monday of the selected date's week
    final int weekday = normSelected.weekday; // 1 = Mon, 7 = Sun
    final DateTime currentMonday = _addDays(normSelected, -(weekday - 1));
    final DateTime currentSunday = _addDays(currentMonday, 6);

    // Previous week's Monday and Sunday
    final DateTime prevMonday = _addDays(currentMonday, -7);

    // Map completed logs by normalized date
    final Map<DateTime, DailyLog> logsByDate = {};
    for (final log in logs) {
      if (!log.isCompleted) continue;
      final d = _normalizeDate(log.date);
      if (!logsByDate.containsKey(d) || log.createdAt.isAfter(logsByDate[d]!.createdAt)) {
        logsByDate[d] = log;
      }
    }

    // Determine evaluate range for same weekdays comparison
    // If the week is currently ongoing, compare up to min(refToday.weekday, 7)
    final bool isCurrentWeek = !refToday.isBefore(currentMonday) && !refToday.isAfter(currentSunday);
    final int maxWeekdayToCompare = isCurrentWeek ? refToday.weekday : 7;

    // Build 7-day mini-bars & collect current week values
    final List<double?> intensityBars = [];
    final List<double?> sleepBars = [];
    final List<double> currentIntensityScores = [];
    final List<double> currentSleepHoursList = [];
    int currentLoggedDays = 0;
    int sleepDisruptionCount = 0;

    for (int i = 0; i < 7; i++) {
      final date = _addDays(currentMonday, i);
      final log = logsByDate[date];

      if (log == null) {
        // Unlogged day is an empty slot (null)
        intensityBars.add(null);
        sleepBars.add(null);
      } else {
        currentLoggedDays++;
        final dayPic = _engine.analyzeDay(log, date, today: refToday);

        // Day severity level: 0 on symptom-free, mean of present symptoms
        final level = dayPic.dayLevel ?? 0.0;
        intensityBars.add(level);
        currentIntensityScores.add(level);

        // Sleep duration
        final sleep = dayPic.sleepHours ?? log.sleepDuration;
        sleepBars.add(sleep);
        currentSleepHoursList.add(sleep);

        // Check for sleep disruption (night wakings, difficulty falling asleep, etc.)
        bool hasDisruption = false;
        for (final entry in dayPic.symptomScores.entries) {
          if (entry.value > 0.0) {
            final cat = _categorizer.getCategory(entry.key);
            final key = entry.key.toLowerCase();
            if (cat.displayName == 'Sleep' ||
                key.contains('sleep') ||
                key.contains('waking') ||
                key.contains('insomnia')) {
              hasDisruption = true;
              break;
            }
          }
        }
        if (!hasDisruption && dayPic.symptomsWithoutSeverity.isNotEmpty) {
          for (final id in dayPic.symptomsWithoutSeverity) {
            final cat = _categorizer.getCategory(id);
            final key = id.toLowerCase();
            if (cat.displayName == 'Sleep' ||
                key.contains('sleep') ||
                key.contains('waking') ||
                key.contains('insomnia')) {
              hasDisruption = true;
              break;
            }
          }
        }
        if (hasDisruption) {
          sleepDisruptionCount++;
        }
      }
    }

    // Previous week logged days & same-weekday comparisons
    int prevLoggedDays = 0;
    final List<double> prevIntensityScoresSameWeekdays = [];
    final List<double> currIntensityScoresSameWeekdays = [];
    final List<double> prevSleepHoursSameWeekdays = [];
    final List<double> currSleepHoursSameWeekdays = [];

    for (int i = 0; i < 7; i++) {
      final prevDate = _addDays(prevMonday, i);
      final currDate = _addDays(currentMonday, i);

      final prevLog = logsByDate[prevDate];
      final currLog = logsByDate[currDate];

      if (prevLog != null) {
        prevLoggedDays++;
      }

      // Comparison by same weekdays up to maxWeekdayToCompare
      if (i < maxWeekdayToCompare) {
        if (prevLog != null) {
          final pic = _engine.analyzeDay(prevLog, prevDate, today: refToday);
          prevIntensityScoresSameWeekdays.add(pic.dayLevel ?? 0.0);
          prevSleepHoursSameWeekdays.add(pic.sleepHours ?? prevLog.sleepDuration);
        }
        if (currLog != null) {
          final pic = _engine.analyzeDay(currLog, currDate, today: refToday);
          currIntensityScoresSameWeekdays.add(pic.dayLevel ?? 0.0);
          currSleepHoursSameWeekdays.add(pic.sleepHours ?? currLog.sleepDuration);
        }
      }
    }

    // Evaluate minimums per Task 6:
    // Value is shown with at least 2 logged days in the week;
    // The change with at least 3 logged days in both weeks; otherwise "Not enough data to compare yet".
    final bool hasEnoughDataForValues = currentLoggedDays >= 2;
    final bool hasEnoughDataForComparison = currentLoggedDays >= 3 && prevLoggedDays >= 3;

    // Compute Symptom Intensity
    double? avgIntensity;
    String? intensityLabel;
    String intensityDisplay = '—';
    MetricComparison? intensityComparison;
    String intensityChangeDisplay = 'Not enough data to compare yet';
    bool? isIntensityImproved;

    if (hasEnoughDataForValues && currentIntensityScores.isNotEmpty) {
      avgIntensity = currentIntensityScores.reduce((a, b) => a + b) / currentIntensityScores.length;
      if (avgIntensity < 2.0) {
        intensityLabel = 'Mild';
      } else if (avgIntensity < 4.0) {
        intensityLabel = 'Moderate';
      } else {
        intensityLabel = 'Severe';
      }
      intensityDisplay = '$intensityLabel · ${avgIntensity.toStringAsFixed(1)} / 5';
    }

    if (hasEnoughDataForComparison &&
        currIntensityScoresSameWeekdays.isNotEmpty &&
        prevIntensityScoresSameWeekdays.isNotEmpty) {
      final currSameAvg = currIntensityScoresSameWeekdays.reduce((a, b) => a + b) /
          currIntensityScoresSameWeekdays.length;
      final prevSameAvg = prevIntensityScoresSameWeekdays.reduce((a, b) => a + b) /
          prevIntensityScoresSameWeekdays.length;

      intensityComparison = MetricComparison.evaluate(
        current: currSameAvg,
        previous: prevSameAvg,
        lowerIsBetter: true,
      );

      if (intensityComparison.changeType == MaterialChangeType.steady) {
        intensityChangeDisplay = 'steady';
        isIntensityImproved = null;
      } else if (intensityComparison.changeType == MaterialChangeType.improved) {
        final pct = intensityComparison.percentChange?.abs() ?? 0;
        intensityChangeDisplay = '↓ $pct%';
        isIntensityImproved = true;
      } else if (intensityComparison.changeType == MaterialChangeType.worsened) {
        final pct = intensityComparison.percentChange?.abs() ?? 0;
        intensityChangeDisplay = '↑ $pct%';
        isIntensityImproved = false;
      } else if (intensityComparison.changeType == MaterialChangeType.newOccurrence) {
        intensityChangeDisplay = 'new';
        isIntensityImproved = false;
      } else if (intensityComparison.changeType == MaterialChangeType.cleared) {
        intensityChangeDisplay = 'cleared';
        isIntensityImproved = true;
      }
    }

    // Compute Sleep (hours)
    double? avgSleep;
    String sleepDisplay = '—';
    double? sleepDeltaHours;
    String sleepChangeDisplay = 'Not enough data to compare yet';
    bool? isSleepImproved;

    if (hasEnoughDataForValues && currentSleepHoursList.isNotEmpty) {
      avgSleep = currentSleepHoursList.reduce((a, b) => a + b) / currentSleepHoursList.length;
      sleepDisplay = '${avgSleep.toStringAsFixed(1)} hrs';
    }

    if (hasEnoughDataForComparison &&
        currSleepHoursSameWeekdays.isNotEmpty &&
        prevSleepHoursSameWeekdays.isNotEmpty) {
      final currSameSleep = currSleepHoursSameWeekdays.reduce((a, b) => a + b) /
          currSleepHoursSameWeekdays.length;
      final prevSameSleep = prevSleepHoursSameWeekdays.reduce((a, b) => a + b) /
          prevSleepHoursSameWeekdays.length;

      sleepDeltaHours = currSameSleep - prevSameSleep;
      final sign = sleepDeltaHours >= 0 ? '+' : '';
      sleepChangeDisplay = '$sign${sleepDeltaHours.toStringAsFixed(1)} h';
      if (sleepDeltaHours.abs() >= 0.2) {
        isSleepImproved = sleepDeltaHours > 0;
      } else {
        isSleepImproved = null;
      }
    }

    return WeeklyTrendsData(
      weekStart: currentMonday,
      weekEnd: currentSunday,
      currentWeekLoggedDays: currentLoggedDays,
      previousWeekLoggedDays: prevLoggedDays,
      hasEnoughDataForValues: hasEnoughDataForValues,
      hasEnoughDataForComparison: hasEnoughDataForComparison,
      averageIntensity: avgIntensity,
      intensitySeverityLabel: intensityLabel,
      intensityDisplay: intensityDisplay,
      intensityComparison: intensityComparison,
      intensityChangeDisplay: intensityChangeDisplay,
      isIntensityImproved: isIntensityImproved,
      intensityMiniBars: intensityBars,
      averageSleepHours: avgSleep,
      sleepDisplay: sleepDisplay,
      sleepChangeHours: sleepDeltaHours,
      sleepChangeDisplay: sleepChangeDisplay,
      isSleepImproved: isSleepImproved,
      sleepDisruptionDays: sleepDisruptionCount,
      sleepMiniBars: sleepBars,
    );
  }
}
