import 'analysis_period.dart';

enum PatternLag {
  lag0, // Same day
  lag1; // Next day

  String get displayText {
    switch (this) {
      case PatternLag.lag0:
        return 'on days you log it';
      case PatternLag.lag1:
        return 'the day after';
    }
  }
}

enum PatternType {
  worsening,
  protective;

  String get label {
    switch (this) {
      case PatternType.worsening:
        return 'worsening';
      case PatternType.protective:
        return 'protective';
    }
  }
}

enum PatternConfidence {
  high,
  standard;

  bool get isHigh => this == PatternConfidence.high;
}

enum SD10EmptyType {
  none,
  notEnoughData, // < 14 logged days or building towards threshold
  notEnoughVariety, // Trigger present on all logged days or never
  nothingNotable; // 14+ logged days but no pattern >= 30% strength
}

/// Approved AI Trigger Correlation disclaimer verbatim.
const String kApprovedTriggerDisclaimer =
    'This pattern is based on your personal tracking data and is for informational purposes only. '
    'Correlation does not mean causation. This is not medical advice — please discuss any lifestyle '
    'or treatment changes with your healthcare provider.';

class PatternEventDay {
  final DateTime date;
  final double outcomeScore;
  final bool isLagged;
  final DateTime? outcomeDate;

  const PatternEventDay({
    required this.date,
    required this.outcomeScore,
    this.isLagged = false,
    this.outcomeDate,
  });

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'outcomeScore': outcomeScore,
        'isLagged': isLagged,
        'outcomeDate': outcomeDate?.toIso8601String(),
      };
}

class PatternInsight {
  final String triggerId;
  final String triggerDisplayName;
  final String outcomeId;
  final String outcomeDisplayName;
  final bool isOverallDayLevel;
  final PatternLag lag;
  final PatternType type;
  final PatternConfidence confidence;
  final double rawCorrelation; // Pearson r (-1.0 to 1.0)
  final double strength; // |r| (0.0 to 1.0)
  final int correlationPercent; // (strength * 100).round()
  final double effect; // mean(Y | X=1) - mean(Y | X=0)
  final double exposedAverage;
  final double unexposedAverage;
  final int eventCount; // Number of paired exposed days
  final int comparisonDaysCount; // Number of paired unexposed days
  final int hitRateCount; // Events where outcome was higher (or lower for protective)
  final String headlineText;
  final String evidenceText;
  final String hitRateText;
  final String disclaimer;
  final List<PatternInsight> secondaryOutcomes;
  final List<PatternEventDay> eventDays;

  const PatternInsight({
    required this.triggerId,
    required this.triggerDisplayName,
    required this.outcomeId,
    required this.outcomeDisplayName,
    required this.isOverallDayLevel,
    required this.lag,
    required this.type,
    required this.confidence,
    required this.rawCorrelation,
    required this.strength,
    required this.correlationPercent,
    required this.effect,
    required this.exposedAverage,
    required this.unexposedAverage,
    required this.eventCount,
    required this.comparisonDaysCount,
    required this.hitRateCount,
    required this.headlineText,
    required this.evidenceText,
    required this.hitRateText,
    this.disclaimer = kApprovedTriggerDisclaimer,
    this.secondaryOutcomes = const [],
    this.eventDays = const [],
  });

  PatternInsight copyWith({
    List<PatternInsight>? secondaryOutcomes,
    List<PatternEventDay>? eventDays,
  }) {
    return PatternInsight(
      triggerId: triggerId,
      triggerDisplayName: triggerDisplayName,
      outcomeId: outcomeId,
      outcomeDisplayName: outcomeDisplayName,
      isOverallDayLevel: isOverallDayLevel,
      lag: lag,
      type: type,
      confidence: confidence,
      rawCorrelation: rawCorrelation,
      strength: strength,
      correlationPercent: correlationPercent,
      effect: effect,
      exposedAverage: exposedAverage,
      unexposedAverage: unexposedAverage,
      eventCount: eventCount,
      comparisonDaysCount: comparisonDaysCount,
      hitRateCount: hitRateCount,
      headlineText: headlineText,
      evidenceText: evidenceText,
      hitRateText: hitRateText,
      disclaimer: disclaimer,
      secondaryOutcomes: secondaryOutcomes ?? this.secondaryOutcomes,
      eventDays: eventDays ?? this.eventDays,
    );
  }

  Map<String, dynamic> toMap() => {
        'triggerId': triggerId,
        'triggerDisplayName': triggerDisplayName,
        'outcomeId': outcomeId,
        'outcomeDisplayName': outcomeDisplayName,
        'isOverallDayLevel': isOverallDayLevel,
        'lag': lag.name,
        'type': type.name,
        'confidence': confidence.name,
        'rawCorrelation': rawCorrelation,
        'strength': strength,
        'correlationPercent': correlationPercent,
        'effect': effect,
        'exposedAverage': exposedAverage,
        'unexposedAverage': unexposedAverage,
        'eventCount': eventCount,
        'comparisonDaysCount': comparisonDaysCount,
        'hitRateCount': hitRateCount,
        'headlineText': headlineText,
        'evidenceText': evidenceText,
        'hitRateText': hitRateText,
        'disclaimer': disclaimer,
        'secondaryOutcomes': secondaryOutcomes.map((s) => s.toMap()).toList(),
        'eventDays': eventDays.map((e) => e.toMap()).toList(),
      };
}

class BuildingPatternItem {
  final String triggerId;
  final String triggerDisplayName;
  final int eventsCount;
  final int targetCount; // 7 per specification
  final String displayText;

  const BuildingPatternItem({
    required this.triggerId,
    required this.triggerDisplayName,
    required this.eventsCount,
    this.targetCount = 7,
    required this.displayText,
  });

  Map<String, dynamic> toMap() => {
        'triggerId': triggerId,
        'triggerDisplayName': triggerDisplayName,
        'eventsCount': eventsCount,
        'targetCount': targetCount,
        'displayText': displayText,
      };
}

class PatternEngineResult {
  final AnalysisPeriod requestedPeriod;
  final int effectiveDaysInWindow;
  final String? windowNotice; // "Based on last 30 days" or "Based on X days of data"
  final List<PatternInsight> patterns; // Max 5
  final List<BuildingPatternItem> buildingItems; // Max 3, nearest to 7 first
  final SD10EmptyType emptyStateType;
  final String? emptyStateMessage;

  const PatternEngineResult({
    required this.requestedPeriod,
    required this.effectiveDaysInWindow,
    this.windowNotice,
    required this.patterns,
    required this.buildingItems,
    required this.emptyStateType,
    this.emptyStateMessage,
  });

  bool get hasPatterns => patterns.isNotEmpty;
  bool get hasBuildingItems => buildingItems.isNotEmpty;

  List<PatternInsight> get displayablePatterns => patterns;
  String? get progressTriggerName =>
      buildingItems.isNotEmpty ? buildingItems.first.triggerDisplayName : null;
  int get progressCurrentEvents =>
      buildingItems.isNotEmpty ? buildingItems.first.eventsCount : 0;
  int get progressTargetEvents =>
      buildingItems.isNotEmpty ? buildingItems.first.targetCount : 7;

  Map<String, dynamic> toMap() => {
        'requestedPeriod': requestedPeriod.name,
        'effectiveDaysInWindow': effectiveDaysInWindow,
        'windowNotice': windowNotice,
        'patterns': patterns.map((p) => p.toMap()).toList(),
        'buildingItems': buildingItems.map((b) => b.toMap()).toList(),
        'emptyStateType': emptyStateType.name,
        'emptyStateMessage': emptyStateMessage,
      };
}
