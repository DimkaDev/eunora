import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/symptoms_provider.dart';
import '../../domain/models/symptom.dart';
import '../widgets/onboarding_header.dart';

class FrequentSymptomsPage extends ConsumerWidget {
  const FrequentSymptomsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(symptomsProvider);
    final notifier = ref.read(symptomsProvider.notifier);
    final library = ref.watch(symptomLibraryProvider);

    // Get symptoms currently marked as "Frequent" (even if deselected)
    final frequentSymptoms = state.frequentSymptomIds.map((id) {
      return library.firstWhere((s) => s.id == id);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(
        0xFFFAF9F6,
      ), // brand-cream from symptom_logging_23
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const OnboardingHeader(currentStep: 4),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        const Text(
                          'Your Most Frequent Symptoms',
                          style: TextStyle(
                            fontFamily: 'Noto Serif',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D1B1A),
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Select your most frequent ones. We\'ll emphasize tracking them in your daily log.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9B8B7E), // brand-taupe
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 48),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1.1,
                              ),
                          itemCount:
                              frequentSymptoms.length + 1, // +1 for Other card
                          itemBuilder: (context, index) {
                            if (index == frequentSymptoms.length) {
                              return _buildOtherCard(context);
                            }
                            final symptom = frequentSymptoms[index];
                            final isSelected = notifier.isLogged(symptom.id);
                            return _buildSymptomCard(
                              context,
                              symptom: symptom,
                              isSelected: isSelected,
                              onTap: () => notifier.toggleLogged(symptom),
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9B8B7E).withOpacity(0.05),
                            border: Border.all(
                              color: const Color(0xFF9B8B7E).withOpacity(0.1),
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.forum,
                                color: const Color(0xFF9B8B7E).withOpacity(0.4),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text(
                                  "It's common to experience multiple symptoms. Logging them helps us spot patterns in your journey.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF9B8B7E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 160),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildSymptomCard(
    BuildContext context, {
    required Symptom symptom,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    Color iconColor;
    Color iconBgColor;

    // Icon color mapping logic
    switch (symptom.name.toLowerCase()) {
      case 'hot flashes':
        iconColor = const Color(0xFFD4A5A5);
        break;
      case 'mood':
        iconColor = const Color(0xFFA7C5D8);
        break;
      case 'sleep':
        iconColor = const Color(0xFFB8A7C5);
        break;
      case 'dryness':
        iconColor = const Color(0xFF8EB8B5);
        break;
      case 'joint pain':
        iconColor = const Color(0xFFA9B388);
        break;
      default:
        if (symptom.category == 'Emotional & Cognitive') {
          iconColor = const Color(0xFFA7C5D8);
        } else if (symptom.category == 'Physical Wellbeing') {
          iconColor = const Color(0xFFA9B388);
        } else if (symptom.category == 'Vasomotor Symptoms') {
          iconColor = const Color(0xFFD4A5A5);
        } else if (symptom.category == 'Sleep & Energy') {
          iconColor = const Color(0xFFB8A7C5);
        } else {
          iconColor = const Color(0xFF9B8B7E);
        }
    }

    iconBgColor = iconColor.withOpacity(0.1);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: isSelected ? const Color(0xFF9B8B7E) : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.08 : 0.03),
              blurRadius: isSelected ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isSelected ? iconColor.withOpacity(0.2) : iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconData(symptom.iconName),
                color: iconColor,
                size: 36,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                symptom.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? const Color(0xFF1D1B1A)
                      : const Color(0xFF9B8B7E),
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/symptom-library'),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F6),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: const Color(0xFF9B8B7E).withOpacity(0.2),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF9B8B7E).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                color: const Color(0xFF9B8B7E).withOpacity(0.4),
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Other',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF9B8B7E).withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F6).withOpacity(0.95),
          border: Border(
            top: BorderSide(color: const Color(0xFF9B8B7E).withOpacity(0.05)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PRIVATE & SECURE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFA8A29E),
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Next: Daily Goal Setting",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF78716C),
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () => context.push('/other-medications'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B8B7E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: const Row(
                children: [
                  Text(
                    'Next',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'thermostat':
        return Icons.thermostat;
      case 'mood':
        return Icons.mood;
      case 'dark_mode':
        return Icons.dark_mode;
      case 'opacity':
        return Icons.opacity;
      case 'accessibility_new':
        return Icons.accessibility_new;
      case 'bedtime':
        return Icons.bedtime;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'psychology':
        return Icons.psychology;
      case 'sentiment_dissatisfied':
        return Icons.sentiment_dissatisfied;
      case 'reorder':
        return Icons.reorder;
      case 'cloud':
        return Icons.cloud;
      case 'settings_backup_restore':
        return Icons.settings_backup_restore;
      case 'battery_low':
        return Icons.battery_0_bar;
      case 'favorite':
        return Icons.favorite;
      case 'dry_cleaning':
        return Icons.dry_cleaning;
      case 'bed':
        return Icons.bed;
      case 'alarm_on':
        return Icons.alarm_on;
      case 'bolt':
        return Icons.bolt;
      default:
        return Icons.medical_services;
    }
  }
}
