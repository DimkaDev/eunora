import 'package:eunora/features/analysis/domain/models/period_comparison.dart';

class SymptomAnalysisMetric {
  final String symptomId;
  final String displayName;
  final String category;
  final int daysPresent;
  final double dayRate; // daysPresent ÷ loggedDays
  final double burden; // sum of daily scores ÷ loggedDays (including zeros)
  final double? averageSeverity; // mean over present occurrences with valid severity
  final String? severityLabel; // Mild (<2), Moderate (2 to <4), Severe (>=4)
  final MetricComparison? comparison; // comparison of burden or severity to previous window
  final int? ranking; // 1-based rank (ties broken alphabetically by identifier)

  const SymptomAnalysisMetric({
    required this.symptomId,
    required this.displayName,
    required this.category,
    required this.daysPresent,
    required this.dayRate,
    required this.burden,
    this.averageSeverity,
    this.severityLabel,
    this.comparison,
    this.ranking,
  });

  SymptomAnalysisMetric copyWith({
    String? symptomId,
    String? displayName,
    String? category,
    int? daysPresent,
    double? dayRate,
    double? burden,
    double? averageSeverity,
    String? severityLabel,
    MetricComparison? comparison,
    int? ranking,
  }) {
    return SymptomAnalysisMetric(
      symptomId: symptomId ?? this.symptomId,
      displayName: displayName ?? this.displayName,
      category: category ?? this.category,
      daysPresent: daysPresent ?? this.daysPresent,
      dayRate: dayRate ?? this.dayRate,
      burden: burden ?? this.burden,
      averageSeverity: averageSeverity ?? this.averageSeverity,
      severityLabel: severityLabel ?? this.severityLabel,
      comparison: comparison ?? this.comparison,
      ranking: ranking ?? this.ranking,
    );
  }

  Map<String, dynamic> toMap() => {
        'symptomId': symptomId,
        'displayName': displayName,
        'category': category,
        'daysPresent': daysPresent,
        'dayRate': dayRate,
        'burden': burden,
        'averageSeverity': averageSeverity,
        'severityLabel': severityLabel,
        'comparison': comparison?.toMap(),
        'ranking': ranking,
      };
}
