/// Stable integer IDs for each notification channel / alarm slot.
/// Keep these stable — changing IDs orphans existing scheduled notifications.
abstract class NotificationIds {
  /// Daily HRT medication reminder.
  static const int hrtReminder = 1;

  /// Daily symptom / evening log reminder.
  static const int dailyLog = 2;

  /// New AI insight available.
  static const int aiInsight = 3;

  /// Doctor report PDF is ready.
  static const int doctorReport = 4;

  /// Upcoming subscription renewal reminder.
  static const int subscriptionReminder = 5;

  /// Weekly digest / summary notification.
  static const int weeklyDigest = 6;
}
