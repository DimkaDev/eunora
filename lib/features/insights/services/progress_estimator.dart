import 'dart:math';

class ProgressEstimation {
  final int progressCount;
  final int progressTarget;
  final int estimatedDaysRemaining;
  final String label;

  const ProgressEstimation({
    required this.progressCount,
    required this.progressTarget,
    required this.estimatedDaysRemaining,
    required this.label,
  });
}

class ProgressEstimator {
  /// Estimates progress and days remaining until a trigger-symptom pair reaches the threshold.
  /// [currentEvents] is the number of events logged so far (up to [targetEvents]).
  /// [trailing14DayEvents] is the count of co-occurring events in the last 14 days.
  /// [triggerLabel] is the name of the trigger.
  static ProgressEstimation estimate({
    required int currentEvents,
    required int targetEvents,
    required int trailing14DayEvents,
    required String triggerLabel,
  }) {
    final int target = targetEvents;
    final int current = currentEvents.clamp(0, target);
    final int needed = target - current;

    int estimatedDays = 999; // Default fallback indicating unknown/long duration
    String timeEstText = "a few more days";

    if (needed <= 0) {
      estimatedDays = 0;
      timeEstText = "0 more days";
    } else {
      // Calculate rate: events per day over the last 14 days
      final double ratePerDay = trailing14DayEvents / 14.0;
      if (ratePerDay > 0) {
        estimatedDays = (needed / ratePerDay).ceil();
        if (estimatedDays <= 0) {
          estimatedDays = 1;
        }
        timeEstText = "about $estimatedDays more day${estimatedDays == 1 ? '' : 's'}";
      } else {
        // Fallback when rate is 0
        timeEstText = "some more time";
      }
    }

    final String label = "$current of $target data points needed for $triggerLabel — $timeEstText of logging at your current pace.";

    return ProgressEstimation(
      progressCount: current,
      progressTarget: target,
      estimatedDaysRemaining: ratePerDayZeroSafety(trailing14DayEvents, needed),
      label: label,
    );
  }

  static int ratePerDayZeroSafety(int trailing14DayEvents, int needed) {
    if (trailing14DayEvents <= 0) {
      return 999; // Safe sentinel indicating no rate
    }
    final double ratePerDay = trailing14DayEvents / 14.0;
    return (needed / ratePerDay).ceil();
  }
}
