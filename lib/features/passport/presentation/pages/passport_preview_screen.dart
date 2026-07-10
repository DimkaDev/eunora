import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/onboarding/presentation/providers/onboarding_profile_provider.dart';

class PassportPreviewScreen extends ConsumerWidget {
  final File file;

  const PassportPreviewScreen({
    super.key,
    required this.file,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF8F6),
      appBar: AppBar(
        title: Text(
          'Passport Preview',
          style: GoogleFonts.notoSerif(
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primary),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _handleShare(ref),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PdfPreview(
                build: (format) => file.readAsBytes(),
                useActions: false, // Hide default action buttons to present ours instead
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _handleShare(ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.share_outlined),
                      const SizedBox(width: 8),
                      Text(
                        'Share Report',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleShare(WidgetRef ref) async {
    final profile = ref.read(onboardingProfileProvider);
    final String rawFirstName = (profile != null && profile.email.isNotEmpty)
        ? profile.email.split('@').first
        : "Sarah";
    final String sanitizedFirstName = rawFirstName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final String dateString = DateFormat('yyyyMMdd').format(DateTime.now());
    final String filename = "MenoSync_Passport_${sanitizedFirstName}_$dateString.pdf";

    await Printing.sharePdf(
      bytes: await file.readAsBytes(),
      filename: filename,
      subject: "My MenoSync Passport",
    );
  }
}
