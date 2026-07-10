import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eunora/core/services/firestore_service.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/home/domain/entities/hrt_dose_change.dart';
import 'package:eunora/features/onboarding/presentation/providers/triggers_provider.dart';
import 'package:eunora/features/onboarding/presentation/providers/symptoms_provider.dart';
import 'package:eunora/features/insights/models/insight_result.dart';
import 'package:eunora/features/insights/services/correlation_engine.dart';
import 'package:eunora/features/insights/services/dose_change_analyzer.dart';
import 'package:eunora/features/insights/services/progress_estimator.dart';
import 'package:eunora/features/symptom_log/data/symptom_library.dart';

part 'insights_provider.g.dart';

/// Top-level pure function to run inside Isolate.run.
/// Does not access any Firestore or BuildContext objects.
List<Map<String, dynamic>> performInsightsCalculation(Map<String, dynamic> input) {
  final List<Map<String, dynamic>> rawLogs = (input['dailyLogs'] as List).cast<Map<String, dynamic>>();
  final List<Map<String, dynamic>> rawChanges = (input['hrtDoseChanges'] as List).cast<Map<String, dynamic>>();
  final List<Map<String, dynamic>> triggerOptions = (input['triggerOptions'] as List).cast<Map<String, dynamic>>();
  final List<String> symptomIds = (input['symptomIds'] as List).cast<String>();
  final List<String> filteredSymptomIds = symptomIds.where((id) {
    final cleanId = id.replaceAll('s_', '');
    final def = kSymptomLibrary.where((d) => d.id == cleanId).firstOrNull;
    if (def != null && def.category == SymptomCategory.cycle) {
      return false;
    }
    return true;
  }).toList();
  final DateTime currentDate = DateTime.parse(input['currentDate'] as String);
  final int hrtHistoryDaysBefore = input['hrtHistoryDaysBefore'] as int;

  final List<Map<String, dynamic>> results = [];

  // --- Helper to parse dates from logs ---
  DateTime parseLogDate(dynamic dateVal) {
    if (dateVal is String) return DateTime.parse(dateVal);
    if (dateVal is DateTime) return dateVal;
    return DateTime.now();
  }

  // --- Helper to check trigger presence ---
  bool isTriggerPresent(Map<String, dynamic> log, String triggerId) {
    final List<String> triggers = List<String>.from(log['triggers'] ?? const []);
    final String query = triggerId.replaceAll('t_', '').toLowerCase();
    for (final t in triggers) {
      final lowerT = t.toLowerCase();
      if (lowerT.startsWith(query) || lowerT.contains(query)) {
        return true;
      }
    }
    return false;
  }

  // --- Helper to get symptom intensity ---
  double getSymptomIntensity(Map<String, dynamic> log, String symptomId) {
    final List symptoms = log['symptoms'] as List? ?? [];
    for (final s in symptoms) {
      final Map<String, dynamic> sym = Map<String, dynamic>.from(s as Map);
      if (sym['id'] == symptomId) {
        final double? intensity = (sym['intensity'] as num?)?.toDouble();
        if (intensity != null) return intensity;
        final String? severity = sym['severity'] as String?;
        if (severity == 'Mild') return 1.0;
        if (severity == 'Moderate') return 3.0;
        if (severity == 'Severe') return 5.0;
        return 1.0;
      }
    }
    return 0.0;
  }

  // Helper to find log for a specific date (normalized to midnight)
  Map<String, dynamic>? getLogForDate(DateTime targetDate) {
    final targetMidnight = DateTime(targetDate.year, targetDate.month, targetDate.day);
    for (final log in rawLogs) {
      final logMidnight = DateTime(log['date'].year, log['date'].month, log['date'].day);
      if (logMidnight.isAtSameMomentAs(targetMidnight)) {
        return log;
      }
    }
    return null;
  }

  // ==========================================
  // TYPE 1: Trigger -> Symptom Correlation
  // ==========================================
  final List<Map<String, dynamic>> candidateCorrelations = [];

  for (final trigger in triggerOptions) {
    final String triggerId = trigger['id'] as String;
    final String triggerLabel = trigger['name'] as String;

    for (final symptomId in filteredSymptomIds) {
      final String symptomLabel = symptomId.replaceAll('s_', '').replaceAll('_', ' ');

      for (final int lag in [0, 1]) {
        final List<double> xSeries = [];
        final List<double> ySeries = [];

        // Build series for rolling 30 days
        for (int offset = -30; offset <= 0; offset++) {
          final DateTime dateD = currentDate.add(Duration(days: offset));
          final DateTime dateDLag = dateD.add(Duration(days: lag));

          final Map<String, dynamic>? logD = getLogForDate(dateD);
          final Map<String, dynamic>? logDLag = getLogForDate(dateDLag);

          if (logD != null && logDLag != null) {
            xSeries.add(isTriggerPresent(logD, triggerId) ? 1.0 : 0.0);
            ySeries.add(getSymptomIntensity(logDLag, symptomId));
          }
        }

        if (xSeries.isNotEmpty) {
          final CorrelationResult correlation = CorrelationEngine.calculate(
            xSeries: xSeries,
            ySeries: ySeries,
          );

          final bool displayable = correlation.eventCount >= 7;
          final int correlationPercent = (correlation.r.abs() * 100).round();
          final String direction = correlation.effectSize > 0 ? 'positive' : 'negative';

          // Estimate progress / ETA
          int trailing14DayEvents = 0;
          for (int offset = -14; offset <= 0; offset++) {
            final DateTime dateD = currentDate.add(Duration(days: offset));
            final DateTime dateDLag = dateD.add(Duration(days: lag));
            final Map<String, dynamic>? logD = getLogForDate(dateD);
            final Map<String, dynamic>? logDLag = getLogForDate(dateDLag);
            if (logD != null && logDLag != null) {
              if (isTriggerPresent(logD, triggerId) && getSymptomIntensity(logDLag, symptomId) > 0) {
                trailing14DayEvents++;
              }
            }
          }

          final ProgressEstimation progress = ProgressEstimator.estimate(
            currentEvents: correlation.eventCount,
            targetEvents: 7,
            trailing14DayEvents: trailing14DayEvents,
            triggerLabel: triggerLabel,
          );

          candidateCorrelations.add({
            'type': displayable ? 'trigger' : 'progress',
            'triggerId': triggerId,
            'symptomId': symptomId,
            'effectSize': correlation.effectSize,
            'correlationPercent': correlationPercent,
            'eventCount': correlation.eventCount,
            'direction': direction,
            'displayable': displayable,
            'lag': lag,
            'progressCurrent': progress.progressCount,
            'progressTarget': progress.progressTarget,
            'estimatedDaysRemaining': progress.estimatedDaysRemaining,
            'label': displayable
                ? "$triggerLabel → ${correlation.effectSize >= 0 ? '+' : ''}${correlation.effectSize.toStringAsFixed(1)} $symptomLabel ${lag == 0 ? 'same day' : 'the next day'} ($correlationPercent% correlation, based on ${correlation.eventCount} events)"
                : progress.label,
          });
        }
      }
    }
  }

  // Sort candidates by abs(correlationPercent) descending
  candidateCorrelations.sort((a, b) {
    final int valA = a['correlationPercent'] as int? ?? 0;
    final int valB = b['correlationPercent'] as int? ?? 0;
    return valB.compareTo(valA);
  });

  // Separate displayable trigger cards (Limit to Top 5) and progress cards
  final List<Map<String, dynamic>> displayableTriggers = candidateCorrelations.where((c) => c['displayable'] == true).take(5).toList();
  final List<Map<String, dynamic>> progressCards = candidateCorrelations.where((c) => c['displayable'] == false).toList();

  for (final t in displayableTriggers) {
    results.add({
      'id': 'trigger_${t['triggerId']}_${t['symptomId']}_lag_${t['lag']}',
      'type': 'trigger',
      'label': t['label'],
      'disclaimer': 'This pattern is based on your personal tracking data and is for informational purposes only. Correlation does not mean causation. This is not medical advice — please discuss any lifestyle or treatment changes with your healthcare provider.',
      'triggerId': t['triggerId'],
      'symptomId': t['symptomId'],
      'effectSize': t['effectSize'],
      'correlationPercent': t['correlationPercent'],
      'eventCount': t['eventCount'],
      'direction': t['direction'],
      'calculatedAt': currentDate.toIso8601String(),
    });
  }

  for (final p in progressCards) {
    results.add({
      'id': 'progress_${p['triggerId']}_${p['symptomId']}_lag_${p['lag']}',
      'type': 'progress',
      'label': p['label'],
      'disclaimer': null,
      'triggerId': p['triggerId'],
      'symptomId': p['symptomId'],
      'progressCurrent': p['progressCurrent'],
      'progressTarget': p['progressTarget'],
      'estimatedDaysRemaining': p['estimatedDaysRemaining'],
      'calculatedAt': currentDate.toIso8601String(),
    });
  }

  // ==========================================
  // TYPE 2: HRT Dose Change Before/After Analysis
  // ==========================================
  for (final change in rawChanges) {
    final String medicationName = change['medicationName'] as String;
    final String changeId = change['id'] as String;
    final DateTime changeDate = change['changeDate'] as DateTime;
    final double oldDose = change['oldDose'] as double;
    final double newDose = change['newDose'] as double;

    final DoseChangeAnalysisResult analysis = DoseChangeAnalyzer.analyze(
      changeDate: changeDate,
      currentDate: currentDate,
      dailyLogs: rawLogs,
      hrtHistoryDaysBefore: hrtHistoryDaysBefore,
    );

    if (analysis.isGatingMet) {
      for (final sc in analysis.symptomChanges) {
        final String symptomLabel = sc.symptomLabel;
        final String changeType = newDose > oldDose ? 'increased' : 'decreased';
        final int daysSinceChange = currentDate.difference(changeDate).inDays;
        final String action = sc.percentDelta < 0 ? 'improved' : 'risen';
        final String sign = sc.percentDelta >= 0 ? '+' : '';

        results.add({
          'id': 'doseChange_${changeId}_${sc.symptomId}',
          'type': 'doseChange',
          'label': "Since your $medicationName dose $changeType $daysSinceChange days ago, $symptomLabel has $action from ${sc.avgBefore.toStringAsFixed(1)} to ${sc.avgAfter.toStringAsFixed(1)} per day ($sign${sc.percentDelta.toStringAsFixed(0)}%)",
          'disclaimer': 'This comparison is based on your self-reported data. Changes in symptoms after a dose adjustment may be due to many factors. This analysis is not a substitute for clinical assessment by your menopause specialist.',
          'symptomId': sc.symptomId,
          'effectSize': sc.percentDelta,
          'calculatedAt': currentDate.toIso8601String(),
        });
      }
    } else {
      results.add({
        'id': 'doseChange_progress_$changeId',
        'type': 'progress',
        'label': "Keep logging — your before/after comparison will appear in ${analysis.daysRemaining} days.",
        'disclaimer': null,
        'progressCurrent': 14 - analysis.daysRemaining,
        'progressTarget': 14,
        'estimatedDaysRemaining': analysis.daysRemaining,
        'calculatedAt': currentDate.toIso8601String(),
      });
    }
  }

  return results;
}

@riverpod
class Insights extends _$Insights {
  Timer? _debounceTimer;

  @override
  FutureOr<List<InsightResult>> build() async {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    return _fetchAndCompute();
  }

  /// Triggers a debounced recomputation.
  void scheduleRecomputation() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () async {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() async {
        return await _fetchAndCompute(forceRecompute: true);
      });
    });
  }

  Future<List<InsightResult>> _fetchAndCompute({bool forceRecompute = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const [];

    final firestore = ref.read(firestoreServiceProvider);

    // Fetch existing correlations/insights
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('correlations');

    final snapshot = await docRef.get();
    DateTime lastCalculatedAt = DateTime.fromMillisecondsSinceEpoch(0);

    if (snapshot.docs.isNotEmpty) {
      final lastDoc = snapshot.docs.first;
      final calcAtStr = lastDoc.data()['calculatedAt'] as String?;
      if (calcAtStr != null) {
        lastCalculatedAt = DateTime.parse(calcAtStr);
      }
    }

    final daysSinceLastCalculation = DateTime.now().difference(lastCalculatedAt).inDays;

    // Type 4: Recompute on app open if calculatedAt is > 7 days old, or if forced
    if (daysSinceLastCalculation < 7 && !forceRecompute && snapshot.docs.isNotEmpty) {
      return snapshot.docs.map((doc) => InsightResult.fromJson(doc.data())).toList();
    }

    // Fetch daily logs and dose changes from Firestore
    final DateTime startLimit = DateTime.now().subtract(const Duration(days: 45));
    final List<DailyLog> logs = await firestore.getDailyLogsHistory(user.uid, startLimit, DateTime.now());
    final List<HrtDoseChange> changes = await firestore.getHrtDoseChanges(user.uid);

    // Get trigger and symptom options
    final triggers = ref.read(triggerLibraryProvider);
    final symptoms = ref.read(symptomsProvider).frequentSymptomIds;

    // Serialize data for the isolate
    final List<Map<String, dynamic>> serializedLogs = logs.map((log) => {
      'date': log.date,
      'triggers': log.triggers,
      'symptoms': log.symptoms.map((s) => {
        'id': s.symptom.id,
        'name': s.symptom.name,
        'intensity': s.intensity?.toDouble() ?? (s.severity == 'Mild' ? 1.0 : s.severity == 'Moderate' ? 3.0 : 5.0),
      }).toList(),
    }).toList();

    final List<Map<String, dynamic>> serializedChanges = changes.map((c) => {
      'id': c.id,
      'medicationName': c.medicationName,
      'changeDate': c.changeDate,
      'oldDose': c.oldDose,
      'newDose': c.newDose,
    }).toList();

    // Calculate HRT history days before the first change
    int hrtHistoryDaysBefore = 14;
    if (logs.isNotEmpty) {
      final earliestLogDate = logs.map((l) => l.date).reduce((a, b) => a.isBefore(b) ? a : b);
      if (changes.isNotEmpty) {
        final earliestChangeDate = changes.map((c) => c.changeDate).reduce((a, b) => a.isBefore(b) ? a : b);
        hrtHistoryDaysBefore = earliestChangeDate.difference(earliestLogDate).inDays;
      }
    }

    final Map<String, dynamic> isolateInput = {
      'dailyLogs': serializedLogs,
      'hrtDoseChanges': serializedChanges,
      'triggerOptions': triggers.map((t) => t.toMap()).toList(),
      'symptomIds': symptoms.isEmpty ? ['s_hot_flashes', 's_mood', 's_sleep', 's_dryness', 's_joint_pain'] : symptoms,
      'currentDate': DateTime.now().toIso8601String(),
      'hrtHistoryDaysBefore': hrtHistoryDaysBefore,
    };

    // Run the computation inside a Dart Isolate to protect the main UI thread
    final List<Map<String, dynamic>> rawResults = await compute(performInsightsCalculation, isolateInput);

    final List<InsightResult> insightResults = rawResults.map((r) => InsightResult.fromJson(r)).toList();

    // Persist every computed pair to correlations collection in Firestore
    final batch = FirebaseFirestore.instance.batch();
    
    // Clear old correlations first
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    for (final result in insightResults) {
      final newDocRef = docRef.doc(result.id);
      batch.set(newDocRef, result.toJson());
    }

    await batch.commit();

    return insightResults;
  }
}
