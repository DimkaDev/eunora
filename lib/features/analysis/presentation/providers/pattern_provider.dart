import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firestore_service.dart';
import '../../domain/models/analysis_period.dart';
import '../../domain/models/pattern_result.dart';
import '../../services/pattern_engine.dart';
import 'analysis_provider.dart';

/// Provider for the singleton [PatternEngine].
final patternEngineProvider = Provider<PatternEngine>((ref) {
  return const PatternEngine();
});

/// Computes patterns for a given [AnalysisPeriod].
/// The analysis window is the longer of the selected period and 30 days (30 for 1/7/30; 90 for 90).
final patternResultProvider =
    FutureProvider.family<PatternEngineResult, AnalysisPeriod>((ref, period) async {
  final engine = ref.watch(patternEngineProvider);
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return engine.analyze(
      logs: const [],
      period: period,
    );
  }

  final firestore = ref.watch(firestoreServiceProvider);
  final now = DateTime.now();
  final effectiveDays = math.max(period.days, 30);
  // Fetch sufficient history for effective window + buffer
  final fetchDaysBack = effectiveDays + 10;
  final fetchStart = DateTime(now.year, now.month, now.day - fetchDaysBack);
  final logs = await firestore.getDailyLogsHistory(user.uid, fetchStart, now);

  return engine.analyze(
    logs: logs,
    period: period,
    today: now,
  );
});

/// Computes patterns with explicit [AnalysisQueryParameters].
final customPatternProvider =
    FutureProvider.family<PatternEngineResult, AnalysisQueryParameters>((ref, params) async {
  final engine = ref.watch(patternEngineProvider);

  if (params.customLogs != null) {
    return engine.analyze(
      logs: params.customLogs!,
      period: params.period,
      today: params.referenceDate,
    );
  }

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return engine.analyze(
      logs: const [],
      period: params.period,
      today: params.referenceDate,
    );
  }

  final firestore = ref.watch(firestoreServiceProvider);
  final refDate = params.referenceDate ?? DateTime.now();
  final effectiveDays = math.max(params.period.days, 30);
  final fetchDaysBack = effectiveDays + 10;
  final fetchStart = DateTime(refDate.year, refDate.month, refDate.day - fetchDaysBack);
  final logs = await firestore.getDailyLogsHistory(user.uid, fetchStart, refDate);

  return engine.analyze(
    logs: logs,
    period: params.period,
    today: refDate,
  );
});
