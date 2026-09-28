import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eunora/core/services/firestore_service.dart';
import 'package:eunora/features/home/presentation/pages/calendar_page.dart';

class DebugExportResult {
  final String jsonString;
  final File file;
  final int totalDailyLogs;
  final int totalMedications;
  final bool hasProfile;

  DebugExportResult({
    required this.jsonString,
    required this.file,
    required this.totalDailyLogs,
    required this.totalMedications,
    required this.hasProfile,
  });
}

class DebugExportService {
  final FirestoreService _firestoreService;

  DebugExportService(this._firestoreService);

  /// Gathers all app data (Firestore, SharedPreferences, In-Memory Caches)
  /// and outputs a formatted JSON file ready for download or sharing.
  Future<DebugExportResult> exportAllData({
    Map<int, MockDailyLog>? aprilLogs,
    Map<String, Map<int, MockDailyLog>>? monthLogsCache,
  }) async {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {
      // Firebase not initialized in test or offline environment
    }
    final uid = user?.uid;

    final Map<String, dynamic> exportMap = {};

    // 1. Export Metadata
    exportMap['export_meta'] = {
      'exported_at': DateTime.now().toIso8601String(),
      'uid': uid ?? 'anonymous',
      'email': user?.email ?? 'none',
      'platform': Platform.operatingSystem,
      'app_version': '1.0.0+1',
    };

    // 2. User Profile
    int totalMeds = 0;
    bool hasProfile = false;
    if (uid != null) {
      try {
        final profile = await _firestoreService.getUserProfile(uid);
        if (profile != null) {
          hasProfile = true;
          totalMeds = profile.medications.length;
          exportMap['user_profile'] = profile.toMap();
        }
      } catch (e) {
        exportMap['user_profile_error'] = e.toString();
      }
    }

    // 3. Firestore Daily Logs
    int totalLogs = 0;
    if (uid != null) {
      try {
        final logs = await _firestoreService.getAllDailyLogs(uid);
        totalLogs = logs.length;
        exportMap['daily_logs'] = logs.map((l) => l.toMap()).toList();
      } catch (e) {
        exportMap['daily_logs_error'] = e.toString();
      }
    }

    // 4. Firestore HRT Dose Changes
    if (uid != null) {
      try {
        final doseChanges = await _firestoreService.getHrtDoseChanges(uid);
        exportMap['hrt_dose_changes'] = doseChanges.map((c) => c.toMap()).toList();
      } catch (e) {
        exportMap['hrt_dose_changes_error'] = e.toString();
      }
    }

    // 5. Firestore AI Insights
    if (uid != null) {
      try {
        final insights = await _firestoreService.getAiInsights(uid);
        exportMap['ai_insights'] = insights.map((i) => i.toMap()).toList();
      } catch (e) {
        exportMap['ai_insights_error'] = e.toString();
      }
    }

    // 6. Firestore Doctor Reports
    if (uid != null) {
      try {
        final reports = await _firestoreService.getDoctorReports(uid);
        exportMap['doctor_reports'] = reports.map((r) => r.toMap()).toList();
      } catch (e) {
        exportMap['doctor_reports_error'] = e.toString();
      }
    }

    // 7. In-Memory Calendar Caches & April Demo Logs
    if (aprilLogs != null && aprilLogs.isNotEmpty) {
      final aprilMap = <String, dynamic>{};
      aprilLogs.forEach((day, log) {
        aprilMap[day.toString()] = {
          'symptoms': log.symptoms,
          'sleepInfo': log.sleepInfo,
          'moodInfo': log.moodInfo,
          'hrt': log.hrt,
          'triggers': log.triggers,
          'itemsCount': log.itemsCount,
        };
      });
      exportMap['cached_april_mock_logs'] = aprilMap;
    }

    if (monthLogsCache != null && monthLogsCache.isNotEmpty) {
      final cacheExport = <String, dynamic>{};
      monthLogsCache.forEach((monthKey, daysMap) {
        final daysExport = <String, dynamic>{};
        daysMap.forEach((day, log) {
          daysExport[day.toString()] = {
            'symptoms': log.symptoms,
            'sleepInfo': log.sleepInfo,
            'moodInfo': log.moodInfo,
            'hrt': log.hrt,
            'triggers': log.triggers,
            'itemsCount': log.itemsCount,
          };
        });
        cacheExport[monthKey] = daysExport;
      });
      exportMap['cached_month_logs'] = cacheExport;
    }

    // 8. SharedPreferences Dump
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(milliseconds: 300));
      final prefsMap = <String, dynamic>{};
      for (final key in prefs.getKeys()) {
        prefsMap[key] = prefs.get(key);
      }
      exportMap['shared_preferences'] = prefsMap;
    } catch (e) {
      exportMap['shared_preferences_error'] = e.toString();
    }

    // Format JSON with 2-space indentation
    const encoder = JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(exportMap);

    // Write to a temporary file
    Directory tempDir;
    try {
      tempDir = await getTemporaryDirectory().timeout(const Duration(milliseconds: 300));
    } catch (_) {
      tempDir = Directory.systemTemp;
    }
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final file = File('${tempDir.path}/eunora_debug_data_$timestamp.json');
    file.writeAsStringSync(jsonString);

    return DebugExportResult(
      jsonString: jsonString,
      file: file,
      totalDailyLogs: totalLogs,
      totalMedications: totalMeds,
      hasProfile: hasProfile,
    );
  }

  /// Triggers the native platform share dialog.
  /// Automatically enables "Save to Files" / "Downloads" on iOS and Android.
  Future<ShareResult> shareDebugJson(File file, {Rect? sharePositionOrigin}) async {
    return SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Eunora Debug Data Export',
        text: 'Eunora Debug Data JSON (${file.path.split('/').last})',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  /// Copies the complete JSON text directly to the user's clipboard.
  Future<void> copyJsonToClipboard(String jsonString) async {
    await Clipboard.setData(ClipboardData(text: jsonString));
  }
}

final debugExportServiceProvider = Provider<DebugExportService>((ref) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return DebugExportService(firestoreService);
});
