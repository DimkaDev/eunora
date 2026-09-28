class AnalysisChartPoint {
  final DateTime date;
  final double? value; // null = gap, never zero or interpolated per requirements
  final String label;

  const AnalysisChartPoint({
    required this.date,
    required this.value,
    this.label = '',
  });

  bool get isGap => value == null;

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'value': value,
        'label': label,
        'isGap': isGap,
      };
}

class AnalysisChartSeries {
  final dynamic period;
  final List<AnalysisChartPoint> points;
  final bool isWeekly;
  final String? label;

  const AnalysisChartSeries({
    this.period,
    required this.points,
    required this.isWeekly,
    this.label,
  });

  Map<String, dynamic> toMap() => {
        'period': period?.toString(),
        'isWeekly': isWeekly,
        'label': label,
        'points': points.map((p) => p.toMap()).toList(),
      };
}
