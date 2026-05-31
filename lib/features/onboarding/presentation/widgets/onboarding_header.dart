import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class OnboardingHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String? title;
  final String? subtitle;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final bool showStepPill;

  const OnboardingHeader({
    super.key,
    required this.currentStep,
    this.totalSteps = 10,
    this.title,
    this.subtitle,
    this.onBack,
    this.onSkip,
    this.showStepPill = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Bar with segmented progress
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF9B8B7E), size: 24),
                    onPressed: onBack ?? () => context.pop(),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          title == null || title == 'Eunora' || title == 'Health Profile'
                              ? 'Step ${currentStep + 1} of $totalSteps'
                              : title!,
                          style: GoogleFonts.notoSerif(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF3A3A3A),
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: const Color(0xFF9B8B7E),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: Color(0xFF9B8B7E), size: 24),
                    onPressed: onSkip ?? () => context.go('/home'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Segmented Progress Bar
              Row(
                children: List.generate(totalSteps, (index) {
                  final isActive = index <= currentStep;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(
                        left: index == 0 ? 0 : 4,
                        right: index == totalSteps - 1 ? 0 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive 
                            ? const Color(0xFF9B8B7E) 
                            : const Color(0xFF9B8B7E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        
        // Step Pill
        if (showStepPill)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFB8A7C5).withOpacity(0.2),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'STEP ${currentStep + 1} OF $totalSteps',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: const Color(0xFFB8A7C5),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
