import '../../../home/domain/entities/daily_log.dart';
import 'analysis_period.dart';
import 'home_insight.dart';

/// Arguments for navigating to the shared [TrendDetailPage].
class TrendDetailArgs {
  /// Target metric to inspect:
  /// - 'overall_severity'
  /// - 'sleep'
  /// - symptom ID (e.g. 'hot_flash', 'fatigue', etc.)
  final String metric;

  /// Selected analysis period (days7, days30, days90).
  final AnalysisPeriod period;

  /// Optional insight card data that triggered this navigation ("Why you see this").
  final HomeInsightCardData? insightToExplain;

  /// Optional human-friendly display name for the metric if it is a symptom.
  final String? metricDisplayName;

  /// Optional custom logs for testing or offline calculation.
  final List<DailyLog>? customLogs;

  const TrendDetailArgs({
    this.metric = 'overall_severity',
    this.period = AnalysisPeriod.days30,
    this.insightToExplain,
    this.metricDisplayName,
    this.customLogs,
  });

  TrendDetailArgs copyWith({
    String? metric,
    AnalysisPeriod? period,
    HomeInsightCardData? insightToExplain,
    String? metricDisplayName,
    List<DailyLog>? customLogs,
  }) {
    return TrendDetailArgs(
      metric: metric ?? this.metric,
      period: period ?? this.period,
      insightToExplain: insightToExplain ?? this.insightToExplain,
      metricDisplayName: metricDisplayName ?? this.metricDisplayName,
      customLogs: customLogs ?? this.customLogs,
    );
  }
}
