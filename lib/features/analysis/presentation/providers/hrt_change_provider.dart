import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firestore_service.dart';
import '../../domain/models/hrt_change_result.dart';
import '../../services/hrt_change_analyzer.dart';

/// Provider for the singleton [HrtChangeAnalyzer].
final hrtChangeAnalyzerProvider = Provider<HrtChangeAnalyzer>((ref) {
  return const HrtChangeAnalyzer();
});

/// Computes HRT regimen before/after comparisons across all recent changes.
/// Fetches dose changes, user medications, and logs.
final hrtAnalysisResultProvider = FutureProvider<HrtAnalysisResult>((ref) async {
  final analyzer = ref.watch(hrtChangeAnalyzerProvider);
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return const HrtAnalysisResult(groups: []);
  }

  final firestore = ref.watch(firestoreServiceProvider);
  final now = DateTime.now();

  // Fetch dose changes and medications
  final doseChanges = await firestore.getHrtDoseChanges(user.uid);
  final userProfile = await firestore.getUserProfile(user.uid);
  final medications = userProfile?.medications ?? const [];

  // Fetch up to 180 days of logs to cover before & after windows of past changes
  final fetchStart = DateTime(now.year, now.month, now.day - 180);
  final logs = await firestore.getDailyLogsHistory(user.uid, fetchStart, now);

  return analyzer.analyze(
    doseChanges: doseChanges,
    medications: medications,
    logs: logs,
    today: now,
  );
});
