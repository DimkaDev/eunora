import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eunora/core/services/firestore_service.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/insights/models/insight_result.dart';

part 'correlation_detail_provider.g.dart';

class CorrelationEvent {
  final DateTime date;
  final String triggerValue;
  final String symptomIntensity;

  const CorrelationEvent({
    required this.date,
    required this.triggerValue,
    required this.symptomIntensity,
  });
}

class CorrelationDetail {
  final InsightResult correlation;
  final List<CorrelationEvent> events;

  const CorrelationDetail({
    required this.correlation,
    required this.events,
  });
}

@riverpod
Future<CorrelationDetail> correlationDetail(Ref ref, String correlationId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception("User is not authenticated");
  }

  // 1. Fetch single correlation doc from Firestore
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('correlations')
      .doc(correlationId)
      .get();

  if (!doc.exists || doc.data() == null) {
    throw Exception("Correlation detail not found for ID: $correlationId");
  }

  final correlation = InsightResult.fromJson(doc.data()!);

  // 2. Fetch daily logs history to reconstruct event log
  final firestore = ref.read(firestoreServiceProvider);
  final DateTime startLimit = DateTime.now().subtract(const Duration(days: 45));
  final List<DailyLog> logs = await firestore.getDailyLogsHistory(user.uid, startLimit, DateTime.now());

  // Sort oldest first
  logs.sort((a, b) => a.date.compareTo(b.date));

  final List<CorrelationEvent> events = [];
  final triggerId = correlation.triggerId;
  final symptomId = correlation.symptomId;

  // Re-detect lag from id (e.g. trigger_t_caffeine_s_hot_flashes_lag_1)
  int lag = 0;
  if (correlationId.contains('lag_1')) {
    lag = 1;
  }

  if (triggerId != null && symptomId != null) {
    final String query = triggerId.replaceAll('t_', '').toLowerCase();

    for (final logD in logs) {
      // Check if trigger is present
      bool triggerPresent = false;
      String triggerValue = "Absent";
      for (final t in logD.triggers) {
        final lowerT = t.toLowerCase();
        if (lowerT.startsWith(query) || lowerT.contains(query)) {
          triggerPresent = true;
          triggerValue = t;
          break;
        }
      }

      if (triggerPresent) {
        // Find corresponding symptom log (at day D + lag)
        final targetDate = logD.date.add(Duration(days: lag));
        final targetMidnight = DateTime(targetDate.year, targetDate.month, targetDate.day);

        final logDLag = logs.firstWhere(
          (l) {
            final m = DateTime(l.date.year, l.date.month, l.date.day);
            return m.isAtSameMomentAs(targetMidnight);
          },
          orElse: () => DailyLog(id: '', userId: '', date: targetDate, createdAt: targetDate),
        );

        if (logDLag.id.isNotEmpty) {
          // Check if symptom is logged
          String intensityStr = "0/5";
          for (final s in logDLag.symptoms) {
            if (s.symptom.id == symptomId) {
              final double intensity = s.intensity?.toDouble() ?? (s.severity == 'Mild' ? 1.0 : s.severity == 'Moderate' ? 3.0 : 5.0);
              intensityStr = "${intensity.toStringAsFixed(0)}/5";
              break;
            }
          }

          events.add(CorrelationEvent(
            date: logD.date,
            triggerValue: triggerValue,
            symptomIntensity: intensityStr,
          ));
        }
      }
    }
  }

  return CorrelationDetail(
    correlation: correlation,
    events: events,
  );
}
