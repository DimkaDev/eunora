import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eunora/core/services/notification_service.dart';

/// Provides the singleton [NotificationService] instance throughout the app.
///
/// Use this provider whenever you need to schedule, cancel, or fire
/// a notification. The service itself is already initialized in [main].
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService.instance,
);
