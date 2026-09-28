import 'package:intl/intl.dart';
import 'period_comparison.dart';

enum HrtChangeStatus {
  notEnoughBaseline, // < 7 logged days in Before window
  pending, // < 14 calendar days elapsed since change
  notEnoughFollowUp, // >= 14 elapsed, but < 7 logged days in After window
  ready; // >= 14 elapsed, >= 7 logged days Before, >= 7 logged days After

  String get label {
    switch (this) {
      case HrtChangeStatus.notEnoughBaseline:
        return 'Not enough baseline';
      case HrtChangeStatus.pending:
        return 'Pending';
      case HrtChangeStatus.notEnoughFollowUp:
        return 'Not enough follow-up';
      case HrtChangeStatus.ready:
        return 'Ready';
    }
  }
}

enum HrtRegimenEventType {
  startedHrt,
  medicationStarted,
  medicationStopped,
  doseIncreased,
  doseDecreased,
  frequencyChanged;

  String get shortLabel {
    switch (this) {
      case HrtRegimenEventType.startedHrt:
        return 'started HRT';
      case HrtRegimenEventType.medicationStarted:
        return 'started';
      case HrtRegimenEventType.medicationStopped:
        return 'stopped';
      case HrtRegimenEventType.doseIncreased:
        return 'dose increased';
      case HrtRegimenEventType.doseDecreased:
        return 'dose decreased';
      case HrtRegimenEventType.frequencyChanged:
        return 'frequency changed';
    }
  }
}

class HrtRegimenEvent {
  final String id;
  final String medicationId;
  final String medicationName;
  final HrtRegimenEventType eventType;
  final DateTime changeDate;
  final String previousValue;
  final String newValue;
  final bool? isDoctorPrescribed;

  const HrtRegimenEvent({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.eventType,
    required this.changeDate,
    required this.previousValue,
    required this.newValue,
    this.isDoctorPrescribed,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'medicationId': medicationId,
        'medicationName': medicationName,
        'eventType': eventType.name,
        'changeDate': changeDate.toIso8601String(),
        'previousValue': previousValue,
        'newValue': newValue,
        'isDoctorPrescribed': isDoctorPrescribed,
      };
}

class HrtSymptomChangeResult {
  final String symptomId;
  final String symptomDisplayName;
  final int daysPresentBefore;
  final int loggedDaysBefore;
  final double frequencyBefore; // daysPresent ÷ loggedDays
  final int daysPresentAfter;
  final int loggedDaysAfter;
  final double frequencyAfter;
  final double? averageSeverityBefore; // when present
  final double? averageSeverityAfter; // when present
  final double burdenBefore; // including zeros
  final double burdenAfter; // including zeros
  final double? averageDurationMinutesBefore; // For hot flashes / night sweats
  final double? averageDurationMinutesAfter;
  final MetricComparison comparison; // SD-4 comparison on burden
  final String directionWording; // "milder", "stronger", "about the same"
  final Map<DateTime, double?> dailyScores;

  const HrtSymptomChangeResult({
    required this.symptomId,
    required this.symptomDisplayName,
    required this.daysPresentBefore,
    required this.loggedDaysBefore,
    required this.frequencyBefore,
    required this.daysPresentAfter,
    required this.loggedDaysAfter,
    required this.frequencyAfter,
    this.averageSeverityBefore,
    this.averageSeverityAfter,
    required this.burdenBefore,
    required this.burdenAfter,
    this.averageDurationMinutesBefore,
    this.averageDurationMinutesAfter,
    required this.comparison,
    required this.directionWording,
    this.dailyScores = const {},
  });

  Map<String, dynamic> toMap() => {
        'symptomId': symptomId,
        'symptomDisplayName': symptomDisplayName,
        'daysPresentBefore': daysPresentBefore,
        'loggedDaysBefore': loggedDaysBefore,
        'frequencyBefore': frequencyBefore,
        'daysPresentAfter': daysPresentAfter,
        'loggedDaysAfter': loggedDaysAfter,
        'frequencyAfter': frequencyAfter,
        'averageSeverityBefore': averageSeverityBefore,
        'averageSeverityAfter': averageSeverityAfter,
        'burdenBefore': burdenBefore,
        'burdenAfter': burdenAfter,
        'averageDurationMinutesBefore': averageDurationMinutesBefore,
        'averageDurationMinutesAfter': averageDurationMinutesAfter,
        'comparison': comparison.toMap(),
        'directionWording': directionWording,
        'dailyScores': dailyScores.map((k, v) => MapEntry(k.toIso8601String(), v)),
      };
}

class HrtAdherenceResult {
  final int scheduledDoses;
  final int takenDoses;
  final int adherencePercent; // (taken / scheduled * 100).round()
  final String adherenceText;
  final bool needsGentleNote; // adherence < 70%
  final String? gentleNote;

  const HrtAdherenceResult({
    required this.scheduledDoses,
    required this.takenDoses,
    required this.adherencePercent,
    required this.adherenceText,
    required this.needsGentleNote,
    this.gentleNote,
  });

  Map<String, dynamic> toMap() => {
        'scheduledDoses': scheduledDoses,
        'takenDoses': takenDoses,
        'adherencePercent': adherencePercent,
        'adherenceText': adherenceText,
        'needsGentleNote': needsGentleNote,
        'gentleNote': gentleNote,
      };
}

const String kApprovedHrtDisclaimer =
    'This comparison is based on your self-reported data. Changes in symptoms after a dose '
    'adjustment may be due to many factors. This analysis is not a substitute for clinical '
    'assessment by your menopause specialist.';

class HrtRegimenGroup {
  final DateTime changeDate;
  final List<HrtRegimenEvent> events;
  final String summaryTitle;
  final HrtChangeStatus status;
  final String statusMessage;
  final int? daysToGo; // 14 - elapsedDays when pending
  final int daysSinceChange;
  final List<String> overlappingNotes;
  final int beforeWindowLoggedDays;
  final int afterWindowLoggedDays;
  final List<HrtSymptomChangeResult> symptomResults;
  final MetricComparison? overallDayLevelChange;
  final HrtAdherenceResult? adherence;
  final String? headlineText;
  final String? summaryCountsText;
  final String disclaimer;

  const HrtRegimenGroup({
    required this.changeDate,
    required this.events,
    required this.summaryTitle,
    required this.status,
    required this.statusMessage,
    this.daysToGo,
    required this.daysSinceChange,
    this.overlappingNotes = const [],
    required this.beforeWindowLoggedDays,
    required this.afterWindowLoggedDays,
    this.symptomResults = const [],
    this.overallDayLevelChange,
    this.adherence,
    this.headlineText,
    this.summaryCountsText,
    this.disclaimer = kApprovedHrtDisclaimer,
  });

  bool get isReady => status == HrtChangeStatus.ready;
  bool get isPending => status == HrtChangeStatus.pending;
  bool get hasNotEnoughBaseline => status == HrtChangeStatus.notEnoughBaseline;
  bool get hasNotEnoughFollowUp => status == HrtChangeStatus.notEnoughFollowUp;

  Map<String, dynamic> toMap() => {
        'changeDate': changeDate.toIso8601String(),
        'events': events.map((e) => e.toMap()).toList(),
        'summaryTitle': summaryTitle,
        'status': status.name,
        'statusMessage': statusMessage,
        'daysToGo': daysToGo,
        'daysSinceChange': daysSinceChange,
        'overlappingNotes': overlappingNotes,
        'beforeWindowLoggedDays': beforeWindowLoggedDays,
        'afterWindowLoggedDays': afterWindowLoggedDays,
        'symptomResults': symptomResults.map((s) => s.toMap()).toList(),
        'overallDayLevelChange': overallDayLevelChange?.toMap(),
        'adherence': adherence?.toMap(),
        'headlineText': headlineText,
        'summaryCountsText': summaryCountsText,
        'disclaimer': disclaimer,
      };
}

class HrtAnalysisResult {
  final List<HrtRegimenGroup> groups; // Most recent first, max 5

  const HrtAnalysisResult({
    required this.groups,
  });

  bool get hasHistory => groups.isNotEmpty;

  Map<String, dynamic> toMap() => {
        'groups': groups.map((g) => g.toMap()).toList(),
        'hasHistory': hasHistory,
      };
}
