import 'package:eunora/features/home/domain/entities/doctor_report.dart';

abstract class DoctorReportRepository {
  Future<List<DoctorReport>> getDoctorReports(String uid);
  Future<void> saveDoctorReport(String uid, DoctorReport report);
}
