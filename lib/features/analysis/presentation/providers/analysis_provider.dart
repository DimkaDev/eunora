import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firestore_service.dart';
import '../../../home/domain/entities/daily_log.dart';
import '../../domain/models/analysis_period.dart';
import '../../domain/models/window_analysis_result.dart';
import '../../services/analysis_engine.dart';

/// Provider for the singleton [AnalysisEngine].
final analysisEngineProvider = Provider<AnalysisEngine>((ref) {
  return const AnalysisEngine();
});

/// Parameters for querying window analysis.
class AnalysisQueryParameters {
  final AnalysisPeriod period;
  final DateTime? referenceDate;
  final List<DailyLog>? customLogs;

  const AnalysisQueryParameters({
    required this.period,
    this.referenceDate,
    this.customLogs,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalysisQueryParameters &&
          runtimeType == other.runtimeType &&
          period == other.period &&
          referenceDate == other.referenceDate &&
          customLogs == other.customLogs;

  @override
  int get hashCode => Object.hash(period, referenceDate, customLogs);
}

/// Computes window analysis for a given [AnalysisPeriod].
/// Fetches up to 200 days of history to cover current and previous 90-day windows.
final analysisWindowProvider =
    FutureProvider.family<WindowAnalysisResult, AnalysisPeriod>((ref, period) async {
  final engine = ref.watch(analysisEngineProvider);
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return engine.analyzeWindow(
      logs: const [],
      period: period,
    );
  }

  final firestore = ref.watch(firestoreServiceProvider);
  final now = DateTime.now();
  // Fetch sufficient history for current + previous windows (e.g. 90 + 90 = 180 days)
  final fetchDaysBack = period.days * 2 + 10;
  final fetchStart = DateTime(now.year, now.month, now.day - fetchDaysBack);
  final logs = await firestore.getDailyLogsHistory(user.uid, fetchStart, now);

  return engine.analyzeWindow(
    logs: logs,
    period: period,
    today: now,
    accountCreatedDate: user.metadata.creationTime,
  );
});

/// Computes window analysis with explicit [AnalysisQueryParameters].
final customAnalysisProvider =
    FutureProvider.family<WindowAnalysisResult, AnalysisQueryParameters>((ref, params) async {
  final engine = ref.watch(analysisEngineProvider);

  if (params.customLogs != null) {
    return engine.analyzeWindow(
      logs: params.customLogs!,
      period: params.period,
      today: params.referenceDate,
    );
  }

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return engine.analyzeWindow(
      logs: const [],
      period: params.period,
      today: params.referenceDate,
    );
  }

  final firestore = ref.watch(firestoreServiceProvider);
  final refDate = params.referenceDate ?? DateTime.now();
  final fetchDaysBack = params.period.days * 2 + 10;
  final fetchStart = DateTime(refDate.year, refDate.month, refDate.day - fetchDaysBack);
  final logs = await firestore.getDailyLogsHistory(user.uid, fetchStart, refDate);

  return engine.analyzeWindow(
    logs: logs,
    period: params.period,
    today: refDate,
    accountCreatedDate: user.metadata.creationTime,
  );
});
