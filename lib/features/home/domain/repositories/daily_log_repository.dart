import 'package:eunora/features/home/domain/entities/daily_log.dart';

abstract class DailyLogRepository {
  Future<DailyLog?> getDailyLog(String uid, String dateStr);
  Future<void> saveDailyLog(String uid, DailyLog log);
  Future<List<DailyLog>> getLogsHistory(String uid, DateTime start, DateTime end);
}
