import 'analysis_period.dart';

enum HomeInsightTag {
  pattern,
  positiveTrend,
  worthNoting,
  insight;

  String get label {
    switch (this) {
      case HomeInsightTag.pattern:
        return 'PATTERN';
      case HomeInsightTag.positiveTrend:
        return 'POSITIVE TREND';
      case HomeInsightTag.worthNoting:
        return 'WORTH NOTING';
      case HomeInsightTag.insight:
        return 'INSIGHT';
    }
  }
}

class HomeInsightCardData {
  final String title; // "Daily Insight", "Yesterday's Insight", "Weekly Data Insight", etc.
  final HomeInsightTag tag;
  final String headline;
  final String? evidence;
  final String averageSeverityDisplay; // "Moderate · 3.1 / 5" or "—"
  final int consistencyPercent; // 0–100 over trailing 7 days
  final String targetMetric; // 'overall_severity', symptom ID, or 'sleep'
  final AnalysisPeriod targetPeriod; // days30 for daily card, days7 for weekly card
  final String evidenceSummary; // passed to Trend Detail page
  final String candidateType; // 'D-1'..'D-8', 'W-1'..'W-7'
  final String subjectKey; // for anti-repetition (e.g. "d4_alcohol", "w2_hot_flash")
  final double? keyNumber; // for anti-repetition material change evaluation
  final bool isYesterday;
  final bool isPromptToLog;
  final String? icon;

  const HomeInsightCardData({
    required this.title,
    required this.tag,
    required this.headline,
    this.evidence,
    required this.averageSeverityDisplay,
    required this.consistencyPercent,
    required this.targetMetric,
    required this.targetPeriod,
    required this.evidenceSummary,
    required this.candidateType,
    required this.subjectKey,
    this.keyNumber,
    this.isYesterday = false,
    this.isPromptToLog = false,
    this.icon,
  });

  String? get actionLabel => isPromptToLog ? null : 'View Detailed Trend Analysis';

  Map<String, dynamic> toMap() => {
        'title': title,
        'tag': tag.name,
        'headline': headline,
        'evidence': evidence,
        'averageSeverityDisplay': averageSeverityDisplay,
        'consistencyPercent': consistencyPercent,
        'targetMetric': targetMetric,
        'targetPeriod': targetPeriod.name,
        'evidenceSummary': evidenceSummary,
        'candidateType': candidateType,
        'subjectKey': subjectKey,
        'keyNumber': keyNumber,
        'isYesterday': isYesterday,
        'isPromptToLog': isPromptToLog,
      };
}

const String kApprovedHighSeverityMessage =
    "You've logged severe hot flashes for 3 consecutive days. "
    "We recommend consulting your healthcare provider to discuss your current management plan.";

class HighSeverityAlertData {
  final bool isActive;
  final int consecutiveSevereDays;
  final String title;
  final String message;
  final bool showProactiveTips;

  const HighSeverityAlertData({
    required this.isActive,
    this.consecutiveSevereDays = 3,
    this.title = 'High Symptom Severity Alert',
    String? message,
    String? alertMessage,
    this.showProactiveTips = false,
  }) : message = message ?? alertMessage ?? kApprovedHighSeverityMessage;

  String get alertMessage => message;

  Map<String, dynamic> toMap() => {
        'isActive': isActive,
        'consecutiveSevereDays': consecutiveSevereDays,
        'title': title,
        'message': message,
        'showProactiveTips': showProactiveTips,
      };
}

class HomeInsightsBundle {
  final HomeInsightCardData dailyInsight;
  final HomeInsightCardData weeklyInsight;
  final HighSeverityAlertData? highSeverityAlert;

  const HomeInsightsBundle({
    required this.dailyInsight,
    required this.weeklyInsight,
    this.highSeverityAlert,
  });

  Map<String, dynamic> toMap() => {
        'dailyInsight': dailyInsight.toMap(),
        'weeklyInsight': weeklyInsight.toMap(),
        'highSeverityAlert': highSeverityAlert?.toMap(),
      };
}
