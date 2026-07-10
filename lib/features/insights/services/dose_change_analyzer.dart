class DoseChangeAnalysisResult {
  final bool isGatingMet;
  final int daysRemaining;
  final String? gapReason;
  final List<SymptomChange> symptomChanges;

  const DoseChangeAnalysisResult({
    required this.isGatingMet,
    required this.daysRemaining,
    this.gapReason,
    required this.symptomChanges,
  });
}

class SymptomChange {
  final String symptomId;
  final String symptomLabel;
  final double avgBefore;
  final double avgAfter;
  final double percentDelta;

  const SymptomChange({
    required this.symptomId,
    required this.symptomLabel,
    required this.avgBefore,
    required this.avgAfter,
    required this.percentDelta,
  });
}

class DoseChangeAnalyzer {
  /// Analyzes symptom levels before and after a dose change.
  /// [changeDate] is the date of the change.
  /// [currentDate] is the evaluation date (usually today).
  /// [dailyLogs] is a list of all logged days.
  /// [hrtHistoryDaysBefore] is the number of days of active HRT history before the change.
  static DoseChangeAnalysisResult analyze({
    required DateTime changeDate,
    required DateTime currentDate,
    required List<Map<String, dynamic>> dailyLogs, // Log structure containing 'date' and 'symptoms' (list of {id, intensity})
    required int hrtHistoryDaysBefore,
  }) {
    // Normalize dates to midnight UTC/Local
    final DateTime changeMidnight = DateTime(changeDate.year, changeDate.month, changeDate.day);
    final DateTime currentMidnight = DateTime(currentDate.year, currentDate.month, currentDate.day);

    final int daysElapsed = currentMidnight.difference(changeMidnight).inDays;
    final int daysRemaining = 14 - daysElapsed;

    // Window A (before) = 14 days preceding the change date: [changeMidnight - 14, changeMidnight)
    final DateTime startA = changeMidnight.subtract(const Duration(days: 14));
    final DateTime endA = changeMidnight;

    // Window B (after) = 14 days starting on change date: [changeMidnight, changeMidnight + 14)
    final DateTime startB = changeMidnight;
    final DateTime endB = changeMidnight.add(const Duration(days: 14));

    // Filter logs for Window A and Window B
    final List<Map<String, dynamic>> logsA = [];
    final List<Map<String, dynamic>> logsB = [];

    for (final log in dailyLogs) {
      final DateTime logDate = log['date'] as DateTime;
      final DateTime logMidnight = DateTime(logDate.year, logDate.month, logDate.day);

      if (logMidnight.isAtSameMomentAs(startA) || (logMidnight.isAfter(startA) && logMidnight.isBefore(endA))) {
        logsA.add(log);
      } else if (logMidnight.isAtSameMomentAs(startB) || (logMidnight.isAfter(startB) && logMidnight.isBefore(endB))) {
        logsB.add(log);
      }
    }

    // Gating checks:
    // a) Window A has >= 14 calendar days of HRT history available AND >= 7 symptom log entries within it
    if (hrtHistoryDaysBefore < 14) {
      return DoseChangeAnalysisResult(
        isGatingMet: false,
        daysRemaining: daysRemaining > 0 ? daysRemaining : 0,
        gapReason: 'Needs at least 14 days of HRT history prior to the change.',
        symptomChanges: const [],
      );
    }
    if (logsA.length < 7) {
      return DoseChangeAnalysisResult(
        isGatingMet: false,
        daysRemaining: daysRemaining > 0 ? daysRemaining : 0,
        gapReason: 'Needs at least 7 symptom logs in the period before the change (currently has ${logsA.length}).',
        symptomChanges: const [],
      );
    }

    // b) Window B has >= 14 calendar days elapsed since change AND >= 7 symptom log entries within it
    if (daysElapsed < 14) {
      return DoseChangeAnalysisResult(
        isGatingMet: false,
        daysRemaining: daysRemaining,
        gapReason: 'Needs 14 days to elapse after the change.',
        symptomChanges: const [],
      );
    }
    if (logsB.length < 7) {
      return DoseChangeAnalysisResult(
        isGatingMet: false,
        daysRemaining: 0,
        gapReason: 'Needs at least 7 symptom logs in the period after the change (currently has ${logsB.length}).',
        symptomChanges: const [],
      );
    }

    // Find all symptom IDs reported in either window
    final Set<String> allSymptomIds = {};
    final Map<String, String> symptomLabels = {};

    for (final log in [...logsA, ...logsB]) {
      final List symptoms = log['symptoms'] as List? ?? [];
      for (final s in symptoms) {
        final Map<String, dynamic> sym = Map<String, dynamic>.from(s as Map);
        final String id = sym['id'] as String;
        final String name = sym['name'] as String? ?? id;
        allSymptomIds.add(id);
        symptomLabels[id] = name;
      }
    }

    final List<SymptomChange> symptomChanges = [];

    // Analyze each symptom
    for (final symptomId in allSymptomIds) {
      int countA = 0;
      double sumIntensityA = 0.0;
      for (final log in logsA) {
        final List symptoms = log['symptoms'] as List? ?? [];
        double intensity = 0.0;
        for (final s in symptoms) {
          final Map<String, dynamic> sym = Map<String, dynamic>.from(s as Map);
          if (sym['id'] == symptomId) {
            intensity = (sym['intensity'] as num? ?? 0.0).toDouble();
            if (intensity > 0) {
              countA++;
            }
            break;
          }
        }
        sumIntensityA += intensity;
      }

      int countB = 0;
      double sumIntensityB = 0.0;
      for (final log in logsB) {
        final List symptoms = log['symptoms'] as List? ?? [];
        double intensity = 0.0;
        for (final s in symptoms) {
          final Map<String, dynamic> sym = Map<String, dynamic>.from(s as Map);
          if (sym['id'] == symptomId) {
            intensity = (sym['intensity'] as num? ?? 0.0).toDouble();
            if (intensity > 0) {
              countB++;
            }
            break;
          }
        }
        sumIntensityB += intensity;
      }

      // Gating c) At least 1 symptom category has sufficient density in both windows (>= 5 logged/experienced values in each window)
      if (countA >= 5 && countB >= 5) {
        final double avgBefore = sumIntensityA / logsA.length;
        final double avgAfter = sumIntensityB / logsB.length;
        final double percentDelta = avgBefore == 0.0 ? 0.0 : ((avgAfter - avgBefore) / avgBefore) * 100.0;

        symptomChanges.add(SymptomChange(
          symptomId: symptomId,
          symptomLabel: symptomLabels[symptomId] ?? symptomId,
          avgBefore: avgBefore,
          avgAfter: avgAfter,
          percentDelta: percentDelta,
        ));
      }
    }

    if (symptomChanges.isEmpty) {
      return DoseChangeAnalysisResult(
        isGatingMet: false,
        daysRemaining: 0,
        gapReason: 'No symptom had sufficient density (>= 5 logged values in both periods) to compare.',
        symptomChanges: const [],
      );
    }

    return DoseChangeAnalysisResult(
      isGatingMet: true,
      daysRemaining: 0,
      symptomChanges: symptomChanges,
    );
  }
}
