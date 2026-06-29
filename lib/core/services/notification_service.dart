import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:eunora/core/services/notification_ids.dart';
import 'package:eunora/features/onboarding/domain/models/notification_settings.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

/// Central notification service for the Eunora app.
///
/// Wraps [FlutterLocalNotificationsPlugin] to provide typed, named methods
/// for every notification type in the app. Call [initialize] once at startup
/// (before [runApp]), then use [applySettings] to sync all scheduled alarms
/// whenever [NotificationSettings] changes.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Optional callback to log generated notifications into the history.
  Future<void> Function({
    required String title,
    required String body,
    required String type,
  })? onNotificationGenerated;

  // ── Android channel definitions ─────────────────────────────────────────

  static const _channelReminders = AndroidNotificationChannel(
    'eunora_reminders',
    'Reminders',
    description: 'Daily HRT and logging reminders',
    importance: Importance.high,
  );

  static const _channelInsights = AndroidNotificationChannel(
    'eunora_insights',
    'Insights & Reports',
    description: 'New AI insights and doctor report alerts',
    importance: Importance.defaultImportance,
  );

  static const _channelAccount = AndroidNotificationChannel(
    'eunora_account',
    'Account & Billing',
    description: 'Subscription and account notifications',
    importance: Importance.defaultImportance,
  );

  // ── Notification details builders ────────────────────────────────────────

  static NotificationDetails _reminderDetails() => NotificationDetails(
        android: AndroidNotificationDetails(
          _channelReminders.id,
          _channelReminders.name,
          channelDescription: _channelReminders.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  static NotificationDetails _insightDetails() => NotificationDetails(
        android: AndroidNotificationDetails(
          _channelInsights.id,
          _channelInsights.name,
          channelDescription: _channelInsights.description,
          importance: Importance.defaultImportance,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      );

  static NotificationDetails _accountDetails() => NotificationDetails(
        android: AndroidNotificationDetails(
          _channelAccount.id,
          _channelAccount.name,
          channelDescription: _channelAccount.description,
          importance: Importance.defaultImportance,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: false,
        ),
      );

  // ── Public API ──────────────────────────────────────────────────────────

  /// Call once in [main] before [runApp].
  Future<void> initialize() async {
    if (_initialized) return;

    // Load timezone data.
    tz_data.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint("Error initializing local location: $e");
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings: initSettings);

    // Create Android notification channels.
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channelReminders);
    await androidPlugin?.createNotificationChannel(_channelInsights);
    await androidPlugin?.createNotificationChannel(_channelAccount);

    _initialized = true;
  }

  /// Request OS-level notification permission (iOS 10+ / Android 13+).
  /// Returns true if permission is granted.
  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Check if notification permission is granted.
  Future<bool> isPermissionGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // ── Scheduling helpers ───────────────────────────────────────────────────

  /// Cancel all scheduled and displayed notifications.
  Future<void> cancelAll() => _plugin.cancelAll();

  /// Cancel a specific notification by its [id].
  Future<void> cancelById(int id) => _plugin.cancel(id: id);

  // ── HRT Reminder ────────────────────────────────────────────────────────

  /// Schedule (or reschedule) a daily HRT reminder at [time].
  /// [medicationName] is injected into the notification body; falls back to
  /// a generic message if null.
  Future<void> scheduleHrtReminder({
    required TimeOfDay time,
    String? medicationName,
  }) async {
    await _plugin.cancel(id: NotificationIds.hrtReminder);

    final body = (medicationName != null && medicationName.isNotEmpty)
        ? 'Time to take your $medicationName. Stay consistent for best results.'
        : 'Time to take your HRT medication. Consistency matters!';
    
    final title = '💊 Time for your HRT';

    await _plugin.zonedSchedule(
      id: NotificationIds.hrtReminder,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOf(time),
      notificationDetails: _reminderDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    if (onNotificationGenerated != null) {
      await onNotificationGenerated!(
        title: title,
        body: body,
        type: 'hrt',
      );
    }
  }

  // ── Daily Log Reminder ───────────────────────────────────────────────────

  /// Schedule (or reschedule) a daily symptom-logging reminder at [time].
  Future<void> scheduleDailyLogReminder({required TimeOfDay time}) async {
    await _plugin.cancel(id: NotificationIds.dailyLog);

    const title = '📓 How are you feeling today?';
    const body = 'Log your symptoms to track patterns and get better AI-powered insights.';

    await _plugin.zonedSchedule(
      id: NotificationIds.dailyLog,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOf(time),
      notificationDetails: _reminderDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    if (onNotificationGenerated != null) {
      await onNotificationGenerated!(
        title: title,
        body: body,
        type: 'log',
      );
    }
  }

  // ── Custom Reminder ──────────────────────────────────────────────────────

  /// Schedule a custom daily reminder with a custom [id], [title], and [time].
  Future<void> scheduleCustomReminder({
    required int id,
    required String title,
    required TimeOfDay time,
    String? body,
  }) async {
    await _plugin.cancel(id: id);

    final resolvedBody = body ?? 'Reminder for $title';

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: resolvedBody,
      scheduledDate: _nextInstanceOf(time),
      notificationDetails: _reminderDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    if (onNotificationGenerated != null) {
      await onNotificationGenerated!(
        title: title,
        body: resolvedBody,
        type: 'hrt',
      );
    }
  }

  // ── Immediate / event-based notifications ───────────────────────────────

  /// Fire an "AI Insight available" notification immediately.
  Future<void> showInsightNotification([
    String title = 'New insight available',
  ]) async {
    const body = 'Eunora has spotted a pattern in your recent data. Tap to view.';
    final fullTitle = '✨ $title';
    await _plugin.show(
      id: NotificationIds.aiInsight,
      title: fullTitle,
      body: body,
      notificationDetails: _insightDetails(),
    );
    if (onNotificationGenerated != null) {
      await onNotificationGenerated!(
        title: fullTitle,
        body: body,
        type: 'insight',
      );
    }
  }

  /// Fire a "Doctor Report Ready" notification immediately.
  Future<void> showReportReadyNotification() async {
    const title = '📄 Your report is ready';
    const body = 'Your doctor report has been generated and is ready to review or share.';
    await _plugin.show(
      id: NotificationIds.doctorReport,
      title: title,
      body: body,
      notificationDetails: _insightDetails(),
    );
    if (onNotificationGenerated != null) {
      await onNotificationGenerated!(
        title: title,
        body: body,
        type: 'report',
      );
    }
  }

  /// Fire a subscription reminder immediately.
  /// Pass [daysLeft] (e.g. 3) to personalise the body text.
  Future<void> showSubscriptionReminderNotification({
    int daysLeft = 3,
  }) async {
    const title = '🔔 Subscription renews soon';
    final body = 'Your Eunora Premium subscription renews in $daysLeft day${daysLeft == 1 ? '' : 's'}. No action needed.';
    await _plugin.show(
      id: NotificationIds.subscriptionReminder,
      title: title,
      body: body,
      notificationDetails: _accountDetails(),
    );
    if (onNotificationGenerated != null) {
      await onNotificationGenerated!(
        title: title,
        body: body,
        type: 'subscription',
      );
    }
  }

  // ── Weekly Digest ────────────────────────────────────────────────────────

  /// Schedule a weekly digest notification every Sunday at 9:00 am.
  Future<void> scheduleWeeklyDigest() async {
    await _plugin.cancel(id: NotificationIds.weeklyDigest);

    await _plugin.zonedSchedule(
      id: NotificationIds.weeklyDigest,
      title: '📊 Your weekly summary',
      body: 'See how your symptoms trended this week and what has changed.',
      scheduledDate: _nextSundayAt9am(),
      notificationDetails: _insightDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // ── Master sync ──────────────────────────────────────────────────────────

  /// Apply [settings] to the notification scheduler:
  /// - Schedules or cancels each notification type based on toggle flags.
  /// - [medicationName] is forwarded to the HRT reminder body text.
  Future<void> applySettings(
    NotificationSettings settings, {
    String? medicationName,
  }) async {
    // HRT reminder
    if (settings.hrtReminder) {
      await scheduleHrtReminder(
        time: TimeOfDay(
          hour: settings.hrtTimeHour,
          minute: settings.hrtTimeMinute,
        ),
        medicationName: medicationName,
      );
    } else {
      await cancelById(NotificationIds.hrtReminder);
    }

    // Daily log reminder
    if (settings.eveningLogReminder) {
      await scheduleDailyLogReminder(
        time: TimeOfDay(
          hour: settings.eveningLogTimeHour,
          minute: settings.eveningLogTimeMinute,
        ),
      );
    } else {
      await cancelById(NotificationIds.dailyLog);
    }

    // Weekly digest
    if (settings.weeklyDigest) {
      await scheduleWeeklyDigest();
    } else {
      await cancelById(NotificationIds.weeklyDigest);
    }
  }

  // ── Time helpers ─────────────────────────────────────────────────────────

  /// Returns the next [TZDateTime] that is at [time] (today if still in the
  /// future, otherwise tomorrow).
  tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Returns the next Sunday at 09:00 in the local timezone.
  tz.TZDateTime _nextSundayAt9am() {
    final now = tz.TZDateTime.now(tz.local);
    // DateTime.sunday == 7
    final daysUntilSunday = (DateTime.sunday - now.weekday + 7) % 7;
    var nextSunday = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + daysUntilSunday,
      9,
      0,
    );
    if (nextSunday.isBefore(now)) {
      nextSunday = nextSunday.add(const Duration(days: 7));
    }
    return nextSunday;
  }
}
