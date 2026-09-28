import 'dart:math' as math;
import 'package:intl/intl.dart';

import '../../home/domain/entities/daily_log.dart';
import '../../home/domain/entities/hrt_dose_change.dart';
import '../../onboarding/domain/models/medication.dart';
import '../domain/models/hrt_change_result.dart';
import '../domain/models/period_comparison.dart';
import 'analysis_engine.dart';
import 'symptom_categorizer.dart';

/// Analyzer that computes explainable before/after comparisons for HRT regimen changes.
class HrtChangeAnalyzer {
  final SymptomCategorizer symptomCategorizer;

  const HrtChangeAnalyzer({
    this.symptomCategorizer = const SymptomCategorizer(),
  });

  /// Analyzes HRT changes against daily logs.
  HrtAnalysisResult analyze({
    required List<HrtDoseChange> doseChanges,
    required List<Medication> medications,
    required List<DailyLog> logs,
    DateTime? today,
  }) {
    final refToday = AnalysisEngine.normalizeDate(today ?? DateTime.now());

    // Filter completed logs and map by normalized date
    final Map<DateTime, DailyLog> logsByDate = {};
    for (final log in logs) {
      if (!log.isCompleted) continue;
      final d = AnalysisEngine.normalizeDate(log.date);
      if (!logsByDate.containsKey(d) || log.createdAt.isAfter(logsByDate[d]!.createdAt)) {
        logsByDate[d] = log;
      }
    }

    // 1. Extract events
    final List<HrtRegimenEvent> rawEvents = [];

    // Dose / frequency changes from HrtDoseChange
    for (final change in doseChanges) {
      // Weekday-only changes are administrative and are not events
      if (change.isAdministrativeChange) continue;

      final eventType = _determineDoseChangeEventType(change);
      rawEvents.add(HrtRegimenEvent(
        id: change.id,
        medicationId: change.medicationId,
        medicationName: change.medicationName,
        eventType: eventType,
        changeDate: AnalysisEngine.normalizeDate(change.changeDate),
        previousValue: change.previousValue,
        newValue: change.newValue,
        isDoctorPrescribed: change.isDoctorPrescribed,
      ));
    }

    // Medication starts and stops from Medication list
    // Check if there are any medication starts not already covered
    final List<Medication> sortedMedsByStart = medications
        .where((m) => m.startedAt != null)
        .toList()
      ..sort((a, b) => a.startedAt!.compareTo(b.startedAt!));

    for (int i = 0; i < sortedMedsByStart.length; i++) {
      final med = sortedMedsByStart[i];
      final startDate = AnalysisEngine.normalizeDate(med.startedAt!);

      // Check if this date already has an event for this med
      final alreadyExists = rawEvents.any((e) =>
          e.medicationId == med.id &&
          e.changeDate == startDate &&
          (e.eventType == HrtRegimenEventType.medicationStarted ||
              e.eventType == HrtRegimenEventType.startedHrt));

      if (!alreadyExists) {
        // Very first HRT start is "started HRT"
        final isFirstEver = i == 0;
        final eventType = isFirstEver
            ? HrtRegimenEventType.startedHrt
            : HrtRegimenEventType.medicationStarted;

        rawEvents.add(HrtRegimenEvent(
          id: 'start_${med.id}',
          medicationId: med.id,
          medicationName: med.name,
          eventType: eventType,
          changeDate: startDate,
          previousValue: 'None',
          newValue: '${med.dose} ${med.unit}'.trim(),
        ));
      }

      // Check for soft-stop end date
      if (med.endedAt != null) {
        final endDate = AnalysisEngine.normalizeDate(med.endedAt!);
        final stopExists = rawEvents.any((e) =>
            e.medicationId == med.id &&
            e.changeDate == endDate &&
            e.eventType == HrtRegimenEventType.medicationStopped);

        if (!stopExists) {
          rawEvents.add(HrtRegimenEvent(
            id: 'stop_${med.id}',
            medicationId: med.id,
            medicationName: med.name,
            eventType: HrtRegimenEventType.medicationStopped,
            changeDate: endDate,
            previousValue: '${med.dose} ${med.unit}'.trim(),
            newValue: 'Stopped',
          ));
        }
      }
    }

    if (rawEvents.isEmpty) {
      return const HrtAnalysisResult(groups: []);
    }

    // 2. Group events on the same calendar day
    final Map<DateTime, List<HrtRegimenEvent>> eventsByDate = {};
    for (final event in rawEvents) {
      eventsByDate.putIfAbsent(event.changeDate, () => []).add(event);
    }

    // Sort group dates descending (most recent first)
    final sortedGroupDates = eventsByDate.keys.toList()..sort((a, b) => b.compareTo(a));

    // 3. Analyze each group
    final List<HrtRegimenGroup> analyzedGroups = [];

    for (final groupDate in sortedGroupDates) {
      final events = eventsByDate[groupDate]!;
      final group = _analyzeGroup(
        groupDate: groupDate,
        events: events,
        allGroupDates: sortedGroupDates,
        logsByDate: logsByDate,
        medications: medications,
        today: refToday,
      );
      analyzedGroups.add(group);
    }

    // Take up to 5 most recent groups
    return HrtAnalysisResult(
      groups: analyzedGroups.take(5).toList(),
    );
  }

  HrtRegimenEventType _determineDoseChangeEventType(HrtDoseChange change) {
    if (change.changeType == RegimenChangeType.frequencyChange) {
      return HrtRegimenEventType.frequencyChanged;
    }
    if (change.newDose > change.oldDose) {
      return HrtRegimenEventType.doseIncreased;
    }
    return HrtRegimenEventType.doseDecreased;
  }

  HrtRegimenGroup _analyzeGroup({
    required DateTime groupDate,
    required List<HrtRegimenEvent> events,
    required List<DateTime> allGroupDates,
    required Map<DateTime, DailyLog> logsByDate,
    required List<Medication> medications,
    required DateTime today,
  }) {
    // 14-day Before window: [groupDate - 14, groupDate - 1]
    final beforeStart = AnalysisEngine.addDays(groupDate, -14);
    final beforeEnd = AnalysisEngine.addDays(groupDate, -1);

    // 14-day After window: [groupDate + 1, groupDate + 14]
    final afterStart = AnalysisEngine.addDays(groupDate, 1);
    final afterEnd = AnalysisEngine.addDays(groupDate, 14);

    // Count logged days in each window
    final List<DailyLog> beforeLogs = [];
    DateTime beforeCursor = beforeStart;
    while (!beforeCursor.isAfter(beforeEnd)) {
      final log = logsByDate[beforeCursor];
      if (log != null) beforeLogs.add(log);
      beforeCursor = AnalysisEngine.addDays(beforeCursor, 1);
    }
    final int beforeLoggedCount = beforeLogs.length;

    final List<DailyLog> afterLogs = [];
    DateTime afterCursor = afterStart;
    while (!afterCursor.isAfter(afterEnd)) {
      final log = logsByDate[afterCursor];
      if (log != null) afterLogs.add(log);
      afterCursor = AnalysisEngine.addDays(afterCursor, 1);
    }
    final int afterLoggedCount = afterLogs.length;

    // Elapsed calendar days
    final int elapsedDays = math.max(0, AnalysisEngine.calendarDaysBetween(groupDate, today) - 1);

    // Overlapping changes check
    final List<String> overlappingNotes = [];
    for (final otherDate in allGroupDates) {
      if (otherDate == groupDate) continue;
      final inBefore = !otherDate.isBefore(beforeStart) && !otherDate.isAfter(beforeEnd);
      final inAfter = !otherDate.isBefore(afterStart) && !otherDate.isAfter(afterEnd);
      if (inBefore || inAfter) {
        final formattedDate = DateFormat('MMM d').format(otherDate);
        overlappingNotes.add(
          'Another change on $formattedDate falls within this comparison — read with caution.',
        );
      }
    }

    // Status evaluation in strict order:
    // 1) notEnoughBaseline (< 7 in Before window)
    // 2) pending (elapsedDays < 14)
    // 3) notEnoughFollowUp (elapsedDays >= 14 && afterLoggedCount < 7)
    // 4) ready
    final HrtChangeStatus status;
    final String statusMessage;
    int? daysToGo;

    if (beforeLoggedCount < 7) {
      status = HrtChangeStatus.notEnoughBaseline;
      statusMessage = 'Not enough history before this change to compare';
    } else if (elapsedDays < 14) {
      status = HrtChangeStatus.pending;
      daysToGo = 14 - elapsedDays;
      statusMessage = 'Keep logging — $daysToGo days to go until your before/after comparison.';
    } else if (afterLoggedCount < 7) {
      status = HrtChangeStatus.notEnoughFollowUp;
      statusMessage = 'Not enough logs after this change to compare.';
    } else {
      status = HrtChangeStatus.ready;
      statusMessage = 'Ready';
    }

    // Summary title for the group
    final String summaryTitle = _buildSummaryTitle(groupDate, events);

    // If not ready, return early with status
    if (status != HrtChangeStatus.ready) {
      return HrtRegimenGroup(
        changeDate: groupDate,
        events: events,
        summaryTitle: summaryTitle,
        status: status,
        statusMessage: statusMessage,
        daysToGo: daysToGo,
        daysSinceChange: elapsedDays,
        overlappingNotes: overlappingNotes,
        beforeWindowLoggedDays: beforeLoggedCount,
        afterWindowLoggedDays: afterLoggedCount,
      );
    }

    // Ready status: calculate per-symptom results
    final symptomResults = _computeSymptomResults(
      groupDate: groupDate,
      logsByDate: logsByDate,
      beforeLogs: beforeLogs,
      afterLogs: afterLogs,
    );

    // Overall day-level comparison
    final MetricComparison? overallDayLevelChange = _computeOverallDayLevelComparison(
      beforeLogs: beforeLogs,
      afterLogs: afterLogs,
    );

    // Adherence
    final adherence = _computeAdherence(
      afterStart: afterStart,
      afterEnd: afterEnd,
      logsByDate: logsByDate,
      medications: medications,
    );

    // Headline and counts
    final counts = _buildSummaryCounts(symptomResults);
    final headlineText = _buildHeadlineText(
      groupDate: groupDate,
      events: events,
      daysSinceChange: elapsedDays,
      symptomResults: symptomResults,
    );

    return HrtRegimenGroup(
      changeDate: groupDate,
      events: events,
      summaryTitle: summaryTitle,
      status: status,
      statusMessage: statusMessage,
      daysSinceChange: elapsedDays,
      overlappingNotes: overlappingNotes,
      beforeWindowLoggedDays: beforeLoggedCount,
      afterWindowLoggedDays: afterLoggedCount,
      symptomResults: symptomResults,
      overallDayLevelChange: overallDayLevelChange,
      adherence: adherence,
      headlineText: headlineText,
      summaryCountsText: counts,
    );
  }

  String _buildSummaryTitle(DateTime groupDate, List<HrtRegimenEvent> events) {
    if (events.length == 1) {
      final e = events.first;
      if (e.eventType == HrtRegimenEventType.startedHrt) {
        return 'Started HRT (${e.medicationName})';
      }
      return '${e.medicationName} ${e.eventType.shortLabel}';
    }

    final dateStr = DateFormat('MMM d').format(groupDate);
    final actions = events.map((e) {
      if (e.eventType == HrtRegimenEventType.doseIncreased) {
        return '${e.medicationName} dose ↑';
      }
      if (e.eventType == HrtRegimenEventType.doseDecreased) {
        return '${e.medicationName} dose ↓';
      }
      return '${e.medicationName} ${e.eventType.shortLabel}';
    }).join(', ');

    return 'Regimen changed on $dateStr: $actions';
  }

  List<HrtSymptomChangeResult> _computeSymptomResults({
    required DateTime groupDate,
    required Map<DateTime, DailyLog> logsByDate,
    required List<DailyLog> beforeLogs,
    required List<DailyLog> afterLogs,
  }) {
    final int beforeLoggedCount = beforeLogs.length;
    final int afterLoggedCount = afterLogs.length;

    // Collect unique symptom IDs across both windows
    final Set<String> allSymptomIds = {};
    for (final log in [...beforeLogs, ...afterLogs]) {
      for (final s in log.symptoms) {
        final id = s.symptom.id.isNotEmpty ? s.symptom.id : s.symptom.name;
        allSymptomIds.add(id);
      }
    }

    final List<HrtSymptomChangeResult> results = [];

    for (final symptomId in allSymptomIds) {
      // Days present before & after
      int daysPresentBefore = 0;
      double sumScoresBefore = 0.0;
      int presentWithSeverityBefore = 0;
      double presentSeverityScoreSumBefore = 0.0;
      final List<int> durationsBefore = [];

      for (final log in beforeLogs) {
        final s = _findSymptom(log, symptomId);
        if (s != null) {
          final score = _normalizeScore(s);
          if (score != null && score > 0.0) {
            daysPresentBefore++;
            sumScoresBefore += score;
            presentSeverityScoreSumBefore += score;
            presentWithSeverityBefore++;
          } else if (score == null) {
            // Present without severity
            daysPresentBefore++;
          }
          if (s.durationMinutes != null) durationsBefore.add(s.durationMinutes!);
        }
      }

      int daysPresentAfter = 0;
      double sumScoresAfter = 0.0;
      int presentWithSeverityAfter = 0;
      double presentSeverityScoreSumAfter = 0.0;
      final List<int> durationsAfter = [];

      for (final log in afterLogs) {
        final s = _findSymptom(log, symptomId);
        if (s != null) {
          final score = _normalizeScore(s);
          if (score != null && score > 0.0) {
            daysPresentAfter++;
            sumScoresAfter += score;
            presentSeverityScoreSumAfter += score;
            presentWithSeverityAfter++;
          } else if (score == null) {
            daysPresentAfter++;
          }
          if (s.durationMinutes != null) durationsAfter.add(s.durationMinutes!);
        }
      }

      // Gate: must be present on at least 3 days in either window
      if (daysPresentBefore < 3 && daysPresentAfter < 3) {
        continue;
      }

      final frequencyBefore =
          beforeLoggedCount > 0 ? (daysPresentBefore / beforeLoggedCount) : 0.0;
      final frequencyAfter =
          afterLoggedCount > 0 ? (daysPresentAfter / afterLoggedCount) : 0.0;

      final burdenBefore =
          beforeLoggedCount > 0 ? (sumScoresBefore / beforeLoggedCount) : 0.0;
      final burdenAfter =
          afterLoggedCount > 0 ? (sumScoresAfter / afterLoggedCount) : 0.0;

      final averageSeverityBefore = presentWithSeverityBefore > 0
          ? (presentSeverityScoreSumBefore / presentWithSeverityBefore)
          : null;
      final averageSeverityAfter = presentWithSeverityAfter > 0
          ? (presentSeverityScoreSumAfter / presentWithSeverityAfter)
          : null;

      final avgDurationBefore = durationsBefore.isNotEmpty
          ? (durationsBefore.reduce((a, b) => a + b) / durationsBefore.length)
          : null;
      final avgDurationAfter = durationsAfter.isNotEmpty
          ? (durationsAfter.reduce((a, b) => a + b) / durationsAfter.length)
          : null;

      // SD-4 classification on burden (lower is better for symptoms)
      final comparison = MetricComparison.evaluate(
        current: burdenAfter,
        previous: burdenBefore,
        lowerIsBetter: true,
      );

      final String directionWording;
      if (comparison.changeType == MaterialChangeType.improved) {
        directionWording = 'milder';
      } else if (comparison.changeType == MaterialChangeType.worsened) {
        directionWording = 'stronger';
      } else {
        directionWording = 'about the same';
      }

      final displayName = symptomCategorizer.getLabel(symptomId);

      // Populate 29-day daily scores (14 before + changeDate + 14 after)
      final Map<DateTime, double?> dailyScores = {};
      for (int d = 14; d >= 1; d--) {
        final dt = AnalysisEngine.addDays(groupDate, -d);
        final log = logsByDate[dt];
        if (log == null) {
          dailyScores[dt] = null;
        } else {
          final s = _findSymptom(log, symptomId);
          dailyScores[dt] = s != null ? (_normalizeScore(s) ?? 0.0) : 0.0;
        }
      }
      final changeLog = logsByDate[groupDate];
      if (changeLog == null) {
        dailyScores[groupDate] = null;
      } else {
        final s = _findSymptom(changeLog, symptomId);
        dailyScores[groupDate] = s != null ? (_normalizeScore(s) ?? 0.0) : 0.0;
      }
      for (int d = 1; d <= 14; d++) {
        final dt = AnalysisEngine.addDays(groupDate, d);
        final log = logsByDate[dt];
        if (log == null) {
          dailyScores[dt] = null;
        } else {
          final s = _findSymptom(log, symptomId);
          dailyScores[dt] = s != null ? (_normalizeScore(s) ?? 0.0) : 0.0;
        }
      }

      results.add(HrtSymptomChangeResult(
        symptomId: symptomId,
        symptomDisplayName: displayName,
        daysPresentBefore: daysPresentBefore,
        loggedDaysBefore: beforeLoggedCount,
        frequencyBefore: frequencyBefore,
        daysPresentAfter: daysPresentAfter,
        loggedDaysAfter: afterLoggedCount,
        frequencyAfter: frequencyAfter,
        averageSeverityBefore: averageSeverityBefore,
        averageSeverityAfter: averageSeverityAfter,
        burdenBefore: burdenBefore,
        burdenAfter: burdenAfter,
        averageDurationMinutesBefore: avgDurationBefore,
        averageDurationMinutesAfter: avgDurationAfter,
        comparison: comparison,
        directionWording: directionWording,
        dailyScores: dailyScores,
      ));
    }

    return results;
  }

  MetricComparison? _computeOverallDayLevelComparison({
    required List<DailyLog> beforeLogs,
    required List<DailyLog> afterLogs,
  }) {
    if (beforeLogs.isEmpty || afterLogs.isEmpty) return null;

    final beforeLevels = beforeLogs.map(_calcDayLevel).toList();
    final afterLevels = afterLogs.map(_calcDayLevel).toList();

    final beforeMean = beforeLevels.reduce((a, b) => a + b) / beforeLevels.length;
    final afterMean = afterLevels.reduce((a, b) => a + b) / afterLevels.length;

    return MetricComparison.evaluate(
      current: afterMean,
      previous: beforeMean,
      lowerIsBetter: true,
    );
  }

  HrtAdherenceResult? _computeAdherence({
    required DateTime afterStart,
    required DateTime afterEnd,
    required Map<DateTime, DailyLog> logsByDate,
    required List<Medication> medications,
  }) {
    int scheduledDoses = 0;
    int takenDoses = 0;

    DateTime cursor = afterStart;
    while (!cursor.isAfter(afterEnd)) {
      final weekday = cursor.weekday; // 1 = Monday, 7 = Sunday
      final log = logsByDate[cursor];

      for (final med in medications) {
        // Exclude as-needed medications
        final freqLower = med.frequency.toLowerCase();
        if (freqLower.contains('needed')) continue;

        // Check if med was scheduled on this day
        if (med.selectedWeekdays.contains(weekday)) {
          scheduledDoses++;

          // Check if taken in log
          if (log != null) {
            final tookThis = log.hrtIntakes.any((i) =>
                (i.medicationId == med.id ||
                    i.name.toLowerCase() == med.name.toLowerCase()) &&
                i.isTaken);
            if (tookThis) {
              takenDoses++;
            }
          }
        }
      }

      cursor = AnalysisEngine.addDays(cursor, 1);
    }

    if (scheduledDoses == 0) return null;

    final adherencePercent = ((takenDoses / scheduledDoses) * 100).round();
    final adherenceText = 'You took $takenDoses of $scheduledDoses scheduled doses after this change.';
    final needsGentleNote = adherencePercent < 70;
    final gentleNote = needsGentleNote
        ? 'Taking your medication consistently helps provide a clearer picture of its effects.'
        : null;

    return HrtAdherenceResult(
      scheduledDoses: scheduledDoses,
      takenDoses: takenDoses,
      adherencePercent: adherencePercent,
      adherenceText: adherenceText,
      needsGentleNote: needsGentleNote,
      gentleNote: gentleNote,
    );
  }

  String _buildSummaryCounts(List<HrtSymptomChangeResult> symptomResults) {
    final improved = symptomResults
        .where((s) => s.comparison.changeType == MaterialChangeType.improved)
        .length;
    final steady = symptomResults
        .where((s) => s.comparison.changeType == MaterialChangeType.steady)
        .length;
    final worsened = symptomResults
        .where((s) => s.comparison.changeType == MaterialChangeType.worsened)
        .length;

    return '$improved improved · $steady steady · $worsened worsened';
  }

  String _buildHeadlineText({
    required DateTime groupDate,
    required List<HrtRegimenEvent> events,
    required int daysSinceChange,
    required List<HrtSymptomChangeResult> symptomResults,
  }) {
    if (symptomResults.isEmpty) {
      return 'No symptoms occurred frequently enough in both windows to compare.';
    }

    // Headline selection rule:
    // 1) Largest material improvement (delta < 0, largest abs(delta))
    // 2) If none improved, largest material change
    // 3) If none material, "No clear change in symptoms following this regimen adjustment."
    final improvedList = symptomResults
        .where((s) => s.comparison.changeType == MaterialChangeType.improved)
        .toList()
      ..sort((a, b) => a.comparison.delta!.abs().compareTo(b.comparison.delta!.abs()));

    HrtSymptomChangeResult? headlineSymptom;
    if (improvedList.isNotEmpty) {
      headlineSymptom = improvedList.last; // largest improvement
    } else {
      final materialList = symptomResults
          .where((s) =>
              s.comparison.changeType == MaterialChangeType.worsened ||
              s.comparison.changeType == MaterialChangeType.newOccurrence ||
              s.comparison.changeType == MaterialChangeType.cleared)
          .toList()
        ..sort((a, b) => (a.comparison.delta?.abs() ?? 0.0)
            .compareTo(b.comparison.delta?.abs() ?? 0.0));

      if (materialList.isNotEmpty) {
        headlineSymptom = materialList.last;
      }
    }

    if (headlineSymptom == null) {
      return 'No clear change in symptoms following this regimen adjustment.';
    }

    // Build subject and action wording
    final String subject;
    final String action;

    if (events.length == 1) {
      final e = events.first;
      subject = e.medicationName;
      action = e.eventType.shortLabel;
    } else {
      subject = 'regimen';
      action = 'changed';
    }

    final s = headlineSymptom;
    final percentPart = s.comparison.percentChange != null
        ? '${s.comparison.percentChange! >= 0 ? "+" : ""}${s.comparison.percentChange}%'
        : (s.comparison.changeType == MaterialChangeType.cleared ? 'cleared' : 'new');

    return 'Since your $subject $action $daysSinceChange days ago, ${s.symptomDisplayName} was logged on ${s.daysPresentBefore} of ${s.loggedDaysBefore} days before and ${s.daysPresentAfter} of ${s.loggedDaysAfter} days after ($percentPart overall).';
  }

  dynamic _findSymptom(DailyLog log, String symptomId) {
    for (final s in log.symptoms) {
      final id = s.symptom.id.isNotEmpty ? s.symptom.id : s.symptom.name;
      if (id.toLowerCase() == symptomId.toLowerCase()) {
        return s;
      }
    }
    return null;
  }

  double? _normalizeScore(dynamic loggedSymptom) {
    final sev = loggedSymptom.severity?.toString().trim().toLowerCase();
    if (sev == 'mild') return 1.0;
    if (sev == 'moderate') return 3.0;
    if (sev == 'severe') return 5.0;
    final intensity = loggedSymptom.intensity as int?;
    if (intensity != null) return (intensity / 2.0).clamp(0.0, 5.0);
    return null;
  }

  double _calcDayLevel(DailyLog log) {
    if (log.symptoms.isEmpty) return 0.0;
    double sum = 0.0;
    int count = 0;
    for (final s in log.symptoms) {
      final score = _normalizeScore(s);
      if (score != null && score > 0.0) {
        sum += score;
        count++;
      }
    }
    return count > 0 ? (sum / count) : 0.0;
  }
}
