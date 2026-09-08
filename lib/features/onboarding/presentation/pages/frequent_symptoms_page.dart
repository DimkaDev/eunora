import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/utils/animation_system.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/symptoms_provider.dart';
import '../../domain/models/symptom.dart';
import '../widgets/onboarding_header.dart';
import 'package:eunora/features/onboarding/presentation/providers/menopause_stage_provider.dart';
import 'package:eunora/features/onboarding/presentation/providers/onboarding_profile_provider.dart';

import 'package:eunora/core/utils/logging_helpers.dart';
import 'package:eunora/features/onboarding/presentation/providers/symptom_quick_access_provider.dart';

class FrequentSymptomsPage extends ConsumerStatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  const FrequentSymptomsPage({super.key, this.onNext, this.onBack});

  @override
  ConsumerState<FrequentSymptomsPage> createState() => _FrequentSymptomsPageState();
}

class _FrequentSymptomsPageState extends ConsumerState<FrequentSymptomsPage> {
  bool _isLibraryExpanded = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(symptomsProvider);
    final notifier = ref.read(symptomsProvider.notifier);
    final library = ref.watch(symptomLibraryProvider);

    final stage = ref.watch(menopauseStageProvider).selectedStage ?? 
        ref.watch(onboardingProfileProvider)?.menopauseStage;
    final isPerimenopause = stage == MenopauseStage.irregular;

    final List<Symptom> frequentSymptoms;
    if (isPerimenopause) {
      final List<String> periIds = [
        'hot_flash',
        'night_sweats',
        'mood_swings',
        'difficulty_falling_asleep',
        'brain_fog',
        'irregular_spotting',
      ];
      final List<Symptom> list = [];
      for (final id in periIds) {
        final base = library.firstWhere(
          (s) => s.id == id,
          orElse: () => Symptom(id: id, name: id, iconName: 'medical_services'),
        );
        String name = base.name;
        if (id == 'mood_swings') name = 'Mood changes';
        if (id == 'difficulty_falling_asleep') name = 'Sleep problems';
        if (id == 'irregular_spotting') name = 'Irregular bleeding';
        list.add(base.copyWith(name: name));
      }
      for (final s in library) {
        if ((notifier.isLogged(s.id) || state.frequentSymptomIds.contains(s.id)) && !periIds.contains(s.id)) {
          list.add(s);
        }
      }
      frequentSymptoms = list;
    } else {
      final List<Symptom> list = [];
      for (final id in state.frequentSymptomIds) {
        final base = library.firstWhere(
          (s) => s.id == id,
          orElse: () => Symptom(id: id, name: id, iconName: 'medical_services'),
        );
        list.add(base);
      }
      for (final s in library) {
        if ((notifier.isLogged(s.id) || state.frequentSymptomIds.contains(s.id)) && !state.frequentSymptomIds.contains(s.id)) {
          list.add(s);
        }
      }
      frequentSymptoms = list;
    }

    // Append remaining library items if user tapped "Other"
    final List<Symptom> displaySymptoms = List.from(frequentSymptoms);
    if (_isLibraryExpanded) {
      final Set<String> existingIds = displaySymptoms.map((s) => s.id).toSet();
      for (final s in library) {
        if (!existingIds.contains(s.id)) {
          displaySymptoms.add(s);
          existingIds.add(s.id);
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(
        0xFFFEF8F6,
      ), // brand-cream from symptom_logging_23
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                OnboardingHeader(
                  currentStep: 3,
                  subtitle: 'SYMPTOMS',
                  onBack: widget.onBack,
                  onSkip: () => _showInfoDialog(context),
                ),
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
                        Text(
                          'Your Most Frequent Symptoms',
                          style: GoogleFonts.notoSerif(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1D1B1A),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select your most frequent ones. We\'ll emphasize tracking them in your daily log.',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            color: const Color(0xFF1D1B1A).withOpacity(0.6),
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
                              displaySymptoms.length + (_isLibraryExpanded ? 0 : 1), // +1 for Other card when collapsed
                          itemBuilder: (context, index) {
                            if (!_isLibraryExpanded && index == displaySymptoms.length) {
                              return _buildOtherCard(context);
                            }
                            final symptom = displaySymptoms[index];
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

  Widget _buildTierBadge(String symId) {
    final cleanId = sanitizeSymptomId(symId);
    final isCore = kCoreFixedPins.contains(cleanId);
    final qaState = ref.watch(symptomQuickAccessProvider);
    final isQuick = !isCore && (qaState.prefs[cleanId] == kPrefOnboarding || qaState.prefs[cleanId] == kPrefPromoted);

    if (!isCore && !isQuick) {
      return const SizedBox.shrink();
    }

    final Color badgeBg = isCore
        ? const Color(0xFF9B8B7E).withOpacity(0.18)
        : const Color(0xFF6B8E23).withOpacity(0.18);
    final Color textColor = isCore
        ? const Color(0xFF63564B)
        : const Color(0xFF3F5A10);
    final String label = isCore ? 'CORE' : 'QUICK';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSymptomCard(
    BuildContext context, {
    required Symptom symptom,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Color iconColor = symptom.getIconColor();
    final Color iconBgColor = iconColor.withOpacity(0.15);

    return Bounceable(
      scaleFactor: 0.94,
      duration: const Duration(milliseconds: 140),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        decoration: BoxDecoration(
          color: isSelected ? iconColor.withOpacity(0.12) : iconColor.withOpacity(0.04),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: isSelected ? iconColor : iconColor.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? iconColor.withOpacity(0.2)
                  : Colors.black.withOpacity(0.03),
              blurRadius: isSelected ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isSelected ? iconColor.withOpacity(0.25) : iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: AnimatedScale(
                      scale: isSelected ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        symptom.getIconData(),
                        color: iconColor,
                        size: 36,
                      ),
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
            Positioned(
              top: 10,
              right: 12,
              child: _buildTierBadge(symptom.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherCard(BuildContext context) {
    return Bounceable(
      scaleFactor: 0.94,
      duration: const Duration(milliseconds: 140),
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _isLibraryExpanded = true;
        });
      },
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 10,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFFEF8F6).withOpacity(0),
                  const Color(0xFFFEF8F6),
                ],
              ),
            ),
          ),
          Container(
            color: const Color(0xFFFEF8F6),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 ElevatedButton(
                  onPressed: () {
                    if (widget.onNext != null) {
                      widget.onNext!();
                    } else {
                      context.push('/other-medications');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF67594E),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    if (widget.onNext != null) {
                      widget.onNext!();
                    } else {
                      context.push('/other-medications');
                    }
                  },
                  child: Text(
                    'SKIP THIS STEP',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4D453F).withOpacity(0.6),
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFEF8F6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Menopause Symptoms Info',
                  style: GoogleFonts.notoSerif(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1D1B1A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF9B8B7E)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Hormonal changes can trigger a wide range of physical and emotional symptoms. Recognizing them is the first step toward relief.',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF4D453F),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoRow(
              icon: Icons.thermostat,
              title: 'Vasomotor Symptoms',
              desc: 'Hot flashes, night sweats, and temperature fluctuations are the most common signs of menopause.',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.psychology,
              title: 'Cognitive & Mood Changes',
              desc: 'Brain fog, mood swings, anxiety, and fatigue are directly linked to estrogen fluctuations.',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.favorite_border,
              title: 'Physical Changes',
              desc: 'Joint pain, heart palpitations, sleep disturbances, and changes in skin or hair are also very frequent.',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Got it',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFF1D1B1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: const Color(0xFF4D453F),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
