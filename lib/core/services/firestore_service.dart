import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eunora/features/onboarding/domain/models/user_profile.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/home/domain/entities/ai_insight.dart';
import 'package:eunora/features/home/domain/entities/doctor_report.dart';
import 'package:eunora/features/home/domain/entities/hrt_dose_change.dart';
import 'package:eunora/features/onboarding/domain/models/medication.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- User Profile ---
  Future<void> saveUserProfile(UserProfile profile) async {
    await _db.collection('users').doc(profile.uid).set(profile.toMap());
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromMap(doc.data()!);
  }

  // --- Daily Log ---
  Future<void> saveDailyLog(String uid, DailyLog log) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('daily_logs')
        .doc(log.id)
        .set(log.toMap());
  }

  Future<DailyLog?> getDailyLog(String uid, String dateStr) async {
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('daily_logs')
        .doc(dateStr)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return DailyLog.fromMap(doc.data()!);
  }

  Future<void> deleteDailyLog(String uid, String dateStr) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('daily_logs')
        .doc(dateStr)
        .delete();
  }

  Future<void> finalizePastDayDrafts(String uid) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('daily_logs')
        .where('isCompleted', isEqualTo: false)
        .get();

    for (final doc in snapshot.docs) {
      final log = DailyLog.fromMap(doc.data());
      final logDate = DateTime(log.date.year, log.date.month, log.date.day);
      if (logDate.isBefore(todayStart)) {
        final hasData = log.lastCompletedStep > 0 ||
            log.symptoms.isNotEmpty ||
            log.triggers.isNotEmpty ||
            log.hrtIntakes.any((i) => i.isTaken) ||
            log.estradiolChecked ||
            log.progesteroneChecked;

        if (hasData) {
          final finalizedLog = log.copyWith(isCompleted: true);
          await _db
              .collection('users')
              .doc(uid)
              .collection('daily_logs')
              .doc(log.id)
              .set(finalizedLog.toMap());
        }
      }
    }
  }

  Future<List<DailyLog>> getDailyLogsHistory(
      String uid, DateTime start, DateTime end) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('daily_logs')
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThanOrEqualTo: end.toIso8601String())
        .orderBy('date', descending: true)
        .get();

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return snapshot.docs.map((doc) {
      final log = DailyLog.fromMap(doc.data());
      final logDate = DateTime(log.date.year, log.date.month, log.date.day);
      if (!log.isCompleted && logDate.isBefore(todayStart)) {
        final hasData = log.lastCompletedStep > 0 ||
            log.symptoms.isNotEmpty ||
            log.triggers.isNotEmpty ||
            log.hrtIntakes.any((i) => i.isTaken) ||
            log.estradiolChecked ||
            log.progesteroneChecked;
        if (hasData) {
          return log.copyWith(isCompleted: true);
        }
      }
      return log;
    }).toList();
  }

  // --- AI Insights ---
  Future<void> saveAiInsight(String uid, AiInsight insight) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('ai_insights')
        .doc(insight.id)
        .set(insight.toMap());
  }

  Future<List<AiInsight>> getAiInsights(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('ai_insights')
        .orderBy('generatedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => AiInsight.fromMap(doc.data()))
        .toList();
  }

  // --- Doctor Reports ---
  Future<void> saveDoctorReport(String uid, DoctorReport report) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('doctor_reports')
        .doc(report.id)
        .set(report.toMap());
  }

  Future<List<DoctorReport>> getDoctorReports(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('doctor_reports')
        .orderBy('generatedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => DoctorReport.fromMap(doc.data()))
        .toList();
  }

  // --- HRT Dose Changes ---
  Future<void> saveHrtDoseChange(String uid, HrtDoseChange change) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('hrt_dose_changes')
        .doc(change.id)
        .set(change.toMap());
  }

  Future<List<HrtDoseChange>> getHrtDoseChanges(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('hrt_dose_changes')
        .orderBy('changeDate', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => HrtDoseChange.fromMap(doc.data()))
        .toList();
  }

  Future<void> updateUserMedications(String uid, List<Medication> medications) async {
    await _db.collection('users').doc(uid).update({
      'medications': medications.map((m) => m.toMap()).toList(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Persists only the quick-access preference map — avoids a full profile write.
  Future<void> updateSymptomQuickAccessPrefs(
      String uid, Map<String, String> prefs) async {
    await _db.collection('users').doc(uid).update({
      'symptomQuickAccessPrefs': prefs,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});
