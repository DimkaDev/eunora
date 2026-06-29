import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:eunora/firebase_options.dart';
import 'package:eunora/core/routing/app_router.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/services/notification_service.dart';
import 'package:eunora/core/services/notification_service_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize local notification plugin and timezone database.
  await NotificationService.instance.initialize();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Warm up the notification provider so it registers the history logger callback
    ref.watch(notificationServiceProvider);

    return MaterialApp.router(
      title: 'Eunora MVP',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
