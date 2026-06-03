import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eunora/features/onboarding/domain/models/user_profile.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/home/domain/entities/ai_insight.dart';
import 'package:eunora/features/home/domain/entities/doctor_report.dart';

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

    return snapshot.docs
        .map((doc) => DailyLog.fromMap(doc.data()))
        .toList();
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
}

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});
