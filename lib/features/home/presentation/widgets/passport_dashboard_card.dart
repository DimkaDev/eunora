import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/widgets/app_card.dart';
import 'package:eunora/features/passport/providers/passport_screen_controller.dart';

class PassportDashboardCard extends ConsumerWidget {
  final VoidCallback? onGeneratePassport;

  const PassportDashboardCard({super.key, this.onGeneratePassport});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eligibilityAsync = ref.watch(passportScreenControllerProvider);

    return eligibilityAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (eligibility) {
        if (!eligibility.hasMinimumData) {
          // Passport progress state
          final double progress = (eligibility.totalDays / 30).clamp(0.0, 1.0);
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAF2ED),
                        borderRadius: BorderRadius.all(Radius.circular(100)),
                      ),
                      child: Text(
                        'PASSPORT PROGRESS',
                        style: GoogleFonts.manrope(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: const Color(0xFF6E5445),
                        ),
                      ),
                    ),
                    Text(
                      '${eligibility.totalDays}/30 Days',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${eligibility.daysRemaining} days to baseline',
                  style: GoogleFonts.notoSerif(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1D1B1A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Log your daily symptoms to compile a clinician-ready passport report.',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(100),
                  backgroundColor: const Color(0xFFF2EDEA),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD8C9E0)),
                ),
              ],
            ),
          );
        }

        // Passport ready state
        return AppCard(
          color: const Color(0xFFF1FDF5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.all(Radius.circular(100)),
                    ),
                    child: Text(
                      'PASSPORT READY',
                      style: GoogleFonts.manrope(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 18),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Clinical Passport Baseline Met',
                style: GoogleFonts.notoSerif(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1D1B1A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'A clinician-ready PDF summary of your health data is ready to be shared.',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: onGeneratePassport ?? () => context.push('/passport'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    'Generate Passport PDF',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

