import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';

class NotificationPermissionDialog extends StatelessWidget {
  const NotificationPermissionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.onSurface.withOpacity(0.12),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ambient Glow & Bell Icon
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary.withOpacity(0.06),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.04),
                          blurRadius: 16,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.notifications_active_outlined,
                    size: 48,
                    color: AppTheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                "Don't Miss Your Reminders",
                style: GoogleFonts.notoSerif(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3A3A3A),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                "Enable notifications so you never miss your daily HRT reminder and symptom log prompts.",
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  height: 1.5,
                  color: const Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Bullet list of benefits
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  children: [
                    _buildBenefitRow("Medication reminders"),
                    const SizedBox(height: 8),
                    _buildBenefitRow("Symptom tracking prompts"),
                    const SizedBox(height: 8),
                    _buildBenefitRow("Important health alerts"),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      "Enable Notifications",
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3A3A3A),
                      side: const BorderSide(color: Color(0xFFCCCCCC), width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      "Not Now",
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.check,
          color: AppTheme.primary,
          size: 16,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF3A3A3A),
            ),
          ),
        ),
      ],
    );
  }
}
