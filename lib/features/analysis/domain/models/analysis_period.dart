enum AnalysisPeriod {
  day1,
  days7,
  days30,
  days90;

  int get dayCount {
    switch (this) {
      case AnalysisPeriod.day1:
        return 1;
      case AnalysisPeriod.days7:
        return 7;
      case AnalysisPeriod.days30:
        return 30;
      case AnalysisPeriod.days90:
        return 90;
    }
  }

  int get days => dayCount;

  /// Minimum logged days required in BOTH current and previous window to perform comparison (SD-2 / SD-4).
  /// 1 day: no comparison possible.
  /// 7 days: at least 3 logged days in both.
  /// 30 days: at least 7 logged days in both.
  /// 90 days: at least 14 logged days in both.
  int? get minLoggedDaysRequiredForComparison {
    switch (this) {
      case AnalysisPeriod.day1:
        return null;
      case AnalysisPeriod.days7:
        return 3;
      case AnalysisPeriod.days30:
        return 7;
      case AnalysisPeriod.days90:
        return 14;
    }
  }

  int get minLoggedDaysRequired => minLoggedDaysRequiredForComparison ?? 0;

  String get label {
    switch (this) {
      case AnalysisPeriod.day1:
        return '1 Day';
      case AnalysisPeriod.days7:
        return '7 Days';
      case AnalysisPeriod.days30:
        return '30 Days';
      case AnalysisPeriod.days90:
        return '90 Days';
    }
  }
}
