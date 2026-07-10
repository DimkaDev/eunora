import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:eunora/core/services/firestore_service.dart';
import 'package:eunora/features/onboarding/presentation/providers/onboarding_profile_provider.dart';
import 'package:eunora/features/passport/models/passport_data.dart';
import 'package:eunora/features/passport/services/passport_data_repository.dart';
import 'package:eunora/features/passport/services/passport_pdf_builder.dart';

part 'passport_provider.g.dart';

enum PassportStatus {
  idle,
  generating,
  success,
  failure,
}

class PassportState {
  final PassportStatus status;
  final String? errorMessage;

  const PassportState({
    required this.status,
    this.errorMessage,
  });
}

@riverpod
class Passport extends _$Passport {
  @override
  PassportState build() {
    return const PassportState(status: PassportStatus.idle);
  }

  /// Generates the Menopause Passport PDF as a File and returns it.
  Future<File?> generatePassportFile({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    state = const PassportState(status: PassportStatus.generating);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User is not authenticated");
      }

      final profile = ref.read(onboardingProfileProvider);
      if (profile == null) {
        throw Exception("User profile not found");
      }
      final firestore = ref.read(firestoreServiceProvider);
      final repository = PassportDataRepository(firestore);

      // 1. Assembles DTO
      final PassportData passportData = await repository.fetchPassportData(
        uid: user.uid,
        startDate: startDate,
        endDate: endDate,
        userProfile: profile,
      );

      // 2. Renders PDF Document
      final pdfDocument = PassportPdfBuilder.build(passportData);
      final Uint8List pdfBytes = await pdfDocument.save();

      // 3. Format Filename
      final String rawFirstName = profile.email.isNotEmpty ? profile.email.split('@').first : "Sarah";
      final String sanitizedFirstName = rawFirstName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      final String dateString = DateFormat('yyyyMMdd').format(DateTime.now());
      final String filename = "MenoSync_Passport_${sanitizedFirstName}_$dateString.pdf";

      // 4. Save to temp file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(pdfBytes);

      state = const PassportState(status: PassportStatus.success);
      return file;
    } catch (e, stackTrace) {
      debugPrint("Error generating passport PDF: $e\n$stackTrace");
      state = const PassportState(
        status: PassportStatus.failure,
        errorMessage: "Report could not be generated — please try again.",
      );
      return null;
    }
  }

  /// Generates the Menopause Passport PDF and opens the native system share sheet.
  /// Gracefully catches any generation exceptions and reports a user-friendly error.
  Future<void> generateAndSharePassport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    state = const PassportState(status: PassportStatus.generating);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User is not authenticated");
      }

      final profile = ref.read(onboardingProfileProvider);
      if (profile == null) {
        throw Exception("User profile not found");
      }
      final firestore = ref.read(firestoreServiceProvider);
      final repository = PassportDataRepository(firestore);

      // 1. Assembles DTO
      final PassportData passportData = await repository.fetchPassportData(
        uid: user.uid,
        startDate: startDate,
        endDate: endDate,
        userProfile: profile,
      );

      // 2. Renders PDF Document
      final pdfDocument = PassportPdfBuilder.build(passportData);
      final Uint8List pdfBytes = await pdfDocument.save();

      // 3. Format Filename: MenoSync_Passport_[FirstName]_[YYYYMMDD].pdf
      final String rawFirstName = profile.email.isNotEmpty ? profile.email.split('@').first : "Sarah";
      final String sanitizedFirstName = rawFirstName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      final String dateString = DateFormat('yyyyMMdd').format(DateTime.now());
      final String filename = "MenoSync_Passport_${sanitizedFirstName}_$dateString.pdf";

      // 4. Trigger system native sharing immediately
      final bool shareSuccess = await Printing.sharePdf(
        bytes: pdfBytes,
        filename: filename,
        subject: "My MenoSync Passport",
      );

      if (shareSuccess) {
        state = const PassportState(status: PassportStatus.success);
      } else {
        throw Exception("Share action cancelled or failed");
      }
    } catch (e, stackTrace) {
      debugPrint("Error generating passport PDF: $e\n$stackTrace");
      state = const PassportState(
        status: PassportStatus.failure,
        errorMessage: "Report could not be generated — please try again.",
      );
    }
  }
}
