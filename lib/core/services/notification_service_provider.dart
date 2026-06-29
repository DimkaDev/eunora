import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eunora/core/services/notification_service.dart';
import 'package:eunora/core/services/notification_history_provider.dart';

/// Provides the singleton [NotificationService] instance throughout the app.
///
/// Use this provider whenever you need to schedule, cancel, or fire
/// a notification. The service itself is already initialized in [main].
final notificationServiceProvider = Provider<NotificationService>(
  (ref) {
    final service = NotificationService.instance;
    service.onNotificationGenerated = ({
      required String title,
      required String body,
      required String type,
    }) async {
      await ref.read(notificationHistoryProvider.notifier).addNotification(
        title: title,
        body: body,
        type: type,
      );
    };
    return service;
  },
);
