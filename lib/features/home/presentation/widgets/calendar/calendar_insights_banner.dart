import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';

class CalendarInsightsBanner extends StatelessWidget {
  final bool isInsufficientData;

  const CalendarInsightsBanner({
    super.key,
    this.isInsufficientData = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: isInsufficientData
          ? _buildInProgressInsights()
          : ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
              Container(
                width: 4,
                color: AppTheme.tertiaryFixed,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.psychology_alt,
                            color: Color(0xFF814F45),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Personalized Insights',
                            style: GoogleFonts.notoSerif(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your hot flashes correlate with caffeine intake recorded 4 hours prior. Consider switching to herbal tea after 12 PM.',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: AppTheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFE7E1DF)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Actionable takeaway',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.outline,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {},
                            icon: const Text('LEARN MORE'),
                            label: const Icon(Icons.open_in_new, size: 14),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF814F45),
                              padding: EdgeInsets.zero,
                              textStyle: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInProgressInsights() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology_alt,
                color: Color(0xFF814F45),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Personalized Insights',
                style: GoogleFonts.notoSerif(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'We are currently collecting data to find personalized correlations. Please log your symptoms, triggers, and medications for at least 3 days to build correlations.',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppTheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
