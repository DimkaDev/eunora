import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eunora/core/services/firestore_service.dart';
import 'package:eunora/features/home/domain/entities/doctor_report.dart';
import 'package:eunora/features/home/domain/repositories/doctor_report_repository.dart';

class DoctorReportRepositoryImpl implements DoctorReportRepository {
  final FirestoreService _firestoreService;

  DoctorReportRepositoryImpl(this._firestoreService);

  @override
  Future<List<DoctorReport>> getDoctorReports(String uid) {
    return _firestoreService.getDoctorReports(uid);
  }

  @override
  Future<void> saveDoctorReport(String uid, DoctorReport report) {
    return _firestoreService.saveDoctorReport(uid, report);
  }
}

final doctorReportRepositoryProvider = Provider<DoctorReportRepository>((ref) {
  return DoctorReportRepositoryImpl(ref.read(firestoreServiceProvider));
});
