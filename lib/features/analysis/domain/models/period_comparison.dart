enum ComparisonStatus {
  eligible,
  notEnoughData,
}

enum NotEnoughDataReason {
  singleDayPeriod,
  historyShorterThanWindow,
  notEnoughDataCurrent,
  notEnoughDataPrevious,
  notEnoughDataBoth;

  String get description {
    switch (this) {
      case NotEnoughDataReason.singleDayPeriod:
        return 'Comparisons are not available for a 1-day window.';
      case NotEnoughDataReason.historyShorterThanWindow:
        return 'Not enough history for a previous window comparison.';
      case NotEnoughDataReason.notEnoughDataCurrent:
        return 'Not enough logged days in the current period to compare.';
      case NotEnoughDataReason.notEnoughDataPrevious:
        return 'Not enough logged days in the previous period to compare.';
      case NotEnoughDataReason.notEnoughDataBoth:
        return 'Not enough logged days in both periods to compare.';
    }
  }
}

enum MaterialChangeType {
  improved,
  worsened,
  steady,
  newOccurrence,
  cleared;

  String get label {
    switch (this) {
      case MaterialChangeType.improved:
        return 'improved';
      case MaterialChangeType.worsened:
        return 'worsened';
      case MaterialChangeType.steady:
        return 'steady';
      case MaterialChangeType.newOccurrence:
        return 'new';
      case MaterialChangeType.cleared:
        return 'cleared';
    }
  }
}

class MetricComparison {
  final ComparisonStatus status;
  final NotEnoughDataReason? reason;
  final double? currentValue;
  final double? previousValue;
  final double? delta;
  final int? percentChange; // Capped between -100 and +100 per SD-4
  final MaterialChangeType? changeType;

  const MetricComparison({
    required this.status,
    this.reason,
    this.currentValue,
    this.previousValue,
    this.delta,
    this.percentChange,
    this.changeType,
  });

  bool get isEligible => status == ComparisonStatus.eligible;
  bool get hasNotEnoughData => status == ComparisonStatus.notEnoughData;

  factory MetricComparison.notEnoughData(NotEnoughDataReason reason, {double? currentValue}) {
    return MetricComparison(
      status: ComparisonStatus.notEnoughData,
      reason: reason,
      currentValue: currentValue,
    );
  }

  factory MetricComparison.evaluate({
    required double current,
    required double previous,
    bool lowerIsBetter = true,
  }) {
    final rawDelta = current - previous;
    final absDelta = rawDelta.abs();

    // Baseline was 0
    if (previous == 0.0) {
      if (current > 0.0) {
        return MetricComparison(
          status: ComparisonStatus.eligible,
          currentValue: current,
          previousValue: previous,
          delta: rawDelta,
          percentChange: null, // No percentage when baseline is 0 per SD-4
          changeType: MaterialChangeType.newOccurrence,
        );
      } else {
        return MetricComparison(
          status: ComparisonStatus.eligible,
          currentValue: current,
          previousValue: previous,
          delta: 0.0,
          percentChange: 0,
          changeType: MaterialChangeType.steady,
        );
      }
    }

    // Previous was > 0 and current is 0
    if (current == 0.0 && previous > 0.0) {
      return MetricComparison(
        status: ComparisonStatus.eligible,
        currentValue: current,
        previousValue: previous,
        delta: rawDelta,
        percentChange: null, // No percentage for cleared per SD-4
        changeType: MaterialChangeType.cleared,
      );
    }

    // Relative change calculation
    final relativeChange = (rawDelta / previous).abs();
    final rawPercent = ((rawDelta / previous) * 100).round();
    // Cap at ±100% per SD-4
    final clampedPercent = rawPercent.clamp(-100, 100);

    // SD-4 Material change: at least 0.5 points AND at least 15% relative change
    final isMaterial = absDelta >= 0.5 && relativeChange >= 0.15;

    MaterialChangeType changeType;
    if (!isMaterial) {
      changeType = MaterialChangeType.steady;
    } else {
      if (lowerIsBetter) {
        changeType = rawDelta < 0 ? MaterialChangeType.improved : MaterialChangeType.worsened;
      } else {
        changeType = rawDelta > 0 ? MaterialChangeType.improved : MaterialChangeType.worsened;
      }
    }

    return MetricComparison(
      status: ComparisonStatus.eligible,
      currentValue: current,
      previousValue: previous,
      delta: rawDelta,
      percentChange: clampedPercent,
      changeType: changeType,
    );
  }

  Map<String, dynamic> toMap() => {
        'status': status.name,
        'reason': reason?.name,
        'currentValue': currentValue,
        'previousValue': previousValue,
        'delta': delta,
        'percentChange': percentChange,
        'changeType': changeType?.name,
      };
}
