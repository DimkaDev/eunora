import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firestore_service.dart';
import '../../../onboarding/presentation/providers/medications_provider.dart';
import '../../domain/models/analysis_period.dart';
import '../../domain/models/home_insight.dart';
import '../../domain/models/hrt_change_result.dart';
import '../../domain/models/pattern_result.dart';
import '../../services/analysis_engine.dart';
import '../../services/home_insight_selector.dart';
import '../../services/pattern_engine.dart';
import 'analysis_provider.dart';
import 'hrt_change_provider.dart';
import 'pattern_provider.dart';

/// Provider for the singleton [HomeInsightSelector].
final homeInsightSelectorProvider = Provider<HomeInsightSelector>((ref) {
  return const HomeInsightSelector();
});

/// Computes the complete [HomeInsightsBundle] (Daily Insight, Weekly Insight, High Severity Alert).
final homeInsightsBundleProvider = FutureProvider<HomeInsightsBundle>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  final selector = ref.watch(homeInsightSelectorProvider);
  final now = DateTime.now();

  if (user == null) {
    return selector.selectInsights(
      logs: const [],
      today: now,
      analysis30: const AnalysisEngine().analyzeWindow(logs: const [], period: AnalysisPeriod.days30, today: now),
      analysis7: const AnalysisEngine().analyzeWindow(logs: const [], period: AnalysisPeriod.days7, today: now),
      patternsResult: const PatternEngine().analyze(logs: const [], period: AnalysisPeriod.days30, today: now),
      hrtResult: const HrtAnalysisResult(groups: []),
      medications: const [],
    );
  }

  final firestore = ref.watch(firestoreServiceProvider);
  // Fetch up to 70 days of logs to cover 30-day baseline + trailing windows
  final fetchStart = DateTime(now.year, now.month, now.day - 70);
  final logs = await firestore.getDailyLogsHistory(user.uid, fetchStart, now);

  final analysis30 = await ref.watch(analysisWindowProvider(AnalysisPeriod.days30).future);
  final analysis7 = await ref.watch(analysisWindowProvider(AnalysisPeriod.days7).future);
  final patternResult = await ref.watch(patternResultProvider(AnalysisPeriod.days30).future);
  final hrtResult = await ref.watch(hrtAnalysisResultProvider.future);

  final medicationsState = ref.watch(medicationsProvider);
  final medications = medicationsState.medications;

  return selector.selectInsights(
    logs: logs,
    today: now,
    analysis30: analysis30,
    analysis7: analysis7,
    patternsResult: patternResult,
    hrtResult: hrtResult,
    medications: medications,
  );
});
