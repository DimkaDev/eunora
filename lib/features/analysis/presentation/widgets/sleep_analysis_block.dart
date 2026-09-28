import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/window_analysis_result.dart';

/// Sleep Block on Trend Detail page.
/// Gated by the SD-6 sleep trust rule.
/// If >= 70% of logged days share identical sleep values, insights are suppressed
/// and a short calm note is shown.
class SleepAnalysisBlock extends StatelessWidget {
  final WindowAnalysisResult analysis;

  const SleepAnalysisBlock({
    super.key,
    required this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    if (!analysis.isSleepTrusted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F7F3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEBE6DF)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🌙', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sleep Data Insights Paused',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF67594E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sleep data looks unchanged across logs — insights are paused until more variation is recorded.',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      height: 1.5,
                      color: const Color(0xFF8C7D70),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final avgHours = analysis.averageSleepHours;
    if (avgHours == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBE6DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌙', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Sleep Pattern',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D402D),
                ),
              ),
              const Spacer(),
              Text(
                '${avgHours.toStringAsFixed(1)} hrs avg',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D402D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Sleep duration averaged ${avgHours.toStringAsFixed(1)} hours across your logged days in this window.',
            style: GoogleFonts.manrope(
              fontSize: 12,
              height: 1.5,
              color: const Color(0xFF5E5248),
            ),
          ),
        ],
      ),
    );
  }
}
