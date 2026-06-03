import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eunora/core/services/firestore_service.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/home/domain/repositories/daily_log_repository.dart';

class DailyLogRepositoryImpl implements DailyLogRepository {
  final FirestoreService _firestoreService;

  DailyLogRepositoryImpl(this._firestoreService);

  @override
  Future<DailyLog?> getDailyLog(String uid, String dateStr) {
    return _firestoreService.getDailyLog(uid, dateStr);
  }

  @override
  Future<void> saveDailyLog(String uid, DailyLog log) {
    return _firestoreService.saveDailyLog(uid, log);
  }

  @override
  Future<List<DailyLog>> getLogsHistory(String uid, DateTime start, DateTime end) {
    return _firestoreService.getDailyLogsHistory(uid, start, end);
  }
}

final dailyLogRepositoryProvider = Provider<DailyLogRepository>((ref) {
  return DailyLogRepositoryImpl(ref.read(firestoreServiceProvider));
});
