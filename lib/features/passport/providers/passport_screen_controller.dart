import 'dart:math';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eunora/core/services/firestore_service.dart';

part 'passport_screen_controller.g.dart';

class PassportEligibility {
  final bool hasMinimumData;
  final int daysRemaining;
  final int totalDays;

  const PassportEligibility({
    required this.hasMinimumData,
    required this.daysRemaining,
    required this.totalDays,
  });
}

@riverpod
class PassportScreenController extends _$PassportScreenController {
  @override
  Future<PassportEligibility> build() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const PassportEligibility(hasMinimumData: false, daysRemaining: 30, totalDays: 0);
    }

    final firestore = ref.watch(firestoreServiceProvider);
    final start = DateTime.now().subtract(const Duration(days: 180));
    final logs = await firestore.getDailyLogsHistory(user.uid, start, DateTime.now());

    final completedLogs = logs.where((l) => l.isCompleted).toList();
    final totalDays = completedLogs.length;
    return PassportEligibility(
      hasMinimumData: totalDays >= 30,
      daysRemaining: max(0, 30 - totalDays),
      totalDays: totalDays,
    );
  }
}
