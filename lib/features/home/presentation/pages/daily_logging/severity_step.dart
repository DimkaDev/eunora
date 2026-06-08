import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';
import 'package:eunora/features/onboarding/presentation/providers/symptoms_provider.dart';

class SeverityStep extends ConsumerWidget {
  final Set<String> selectedSymptomIds;
  final Map<String, String> symptomSeverities;
  final Map<String, int> symptomDurations;
  final ValueChanged<MapEntry<String, String>> onSeverityChanged;
  final ValueChanged<MapEntry<String, int>> onDurationChanged;
  final VoidCallback onAddAnotherSymptom;

  const SeverityStep({
    super.key,
    required this.selectedSymptomIds,
    required this.symptomSeverities,
    required this.symptomDurations,
    required this.onSeverityChanged,
    required this.onDurationChanged,
    required this.onAddAnotherSymptom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedSymptomIds.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.playlist_add_check, size: 64, color: Color(0xFFD0C4BC)),
              const SizedBox(height: 16),
              Text(
                'No symptoms selected',
                style: GoogleFonts.notoSerif(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              const SizedBox(height: 8),
              Text(
                'Go back and select symptoms to rate.',
                style: GoogleFonts.manrope(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final library = ref.read(symptomLibraryProvider);
    final symptomMap = {for (var s in library) s.id: s};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Rate your symptoms',
          style: GoogleFonts.notoSerif(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A gentle check-in on how you\'re feeling.',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: const Color(0xFF8A817C),
          ),
        ),
        const SizedBox(height: 32),
        ...selectedSymptomIds.map((id) {
          final symptom = symptomMap[id] ?? Symptom(
            id: id,
            name: id.replaceAll('s_', '').replaceAll('_', ' '),
            iconName: 'medical_services',
          );
          final symName = symptom.name;
          final symIcon = symptom.getIconData();
          final symColor = symptom.getIconColor();
          final symBg = symColor.withOpacity(0.1);
          final currentSeverity = symptomSeverities[id] ?? 'Mild';
          final hasDuration = id == 's_hot_flashes' || id == 's_night_sweats';
          final duration = symptomDurations[id] ?? 15;

          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: symColor.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: symBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(symIcon, color: symColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      symName,
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'INTENSITY',
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: const Color(0xFF8A817C),
                  ),
                ),
                const SizedBox(height: 12),
                // custom premium fluid severity bar
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFE2F5E2), // Soft Green (Mild)
                        Color(0xFFFFF1D0), // Soft Yellow/Orange (Moderate)
                        Color(0xFFFFE0E0), // Soft Red (Severe)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Stack(
                    children: [
                      // White sliding thumb selector
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        alignment: currentSeverity == 'Mild'
                            ? Alignment.centerLeft
                            : currentSeverity == 'Moderate'
                                ? Alignment.center
                                : Alignment.centerRight,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.26,
                          height: 48,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                        ),
                      ),
                      // Three Buttons
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => onSeverityChanged(MapEntry(id, 'Mild')),
                              behavior: HitTestBehavior.opaque,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('😊', style: TextStyle(fontSize: 18)),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Mild',
                                      style: GoogleFonts.manrope(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: currentSeverity == 'Mild' ? AppTheme.primary : const Color(0xFF8A817C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => onSeverityChanged(MapEntry(id, 'Moderate')),
                              behavior: HitTestBehavior.opaque,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('😐', style: TextStyle(fontSize: 18)),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Moderate',
                                      style: GoogleFonts.manrope(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: currentSeverity == 'Moderate' ? AppTheme.primary : const Color(0xFF8A817C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => onSeverityChanged(MapEntry(id, 'Severe')),
                              behavior: HitTestBehavior.opaque,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('😟', style: TextStyle(fontSize: 18)),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Severe',
                                      style: GoogleFonts.manrope(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: currentSeverity == 'Severe' ? AppTheme.primary : const Color(0xFF8A817C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (hasDuration) ...[
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFF7F5F0), height: 1),
                  const SizedBox(height: 20),
                  Text(
                    'DURATION',
                    style: GoogleFonts.manrope(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: const Color(0xFF8A817C),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // duration increments
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F5F0).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (duration > 5) {
                              onDurationChanged(MapEntry(id, duration - 5));
                            }
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 4,
                                )
                              ],
                            ),
                            child: const Icon(Icons.remove, color: AppTheme.primary),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$duration',
                              style: GoogleFonts.notoSerif(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'min',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF8A817C),
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            onDurationChanged(MapEntry(id, duration + 5));
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 4,
                                )
                              ],
                            ),
                            child: const Icon(Icons.add, color: AppTheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        // Add another symptom button
        SizedBox(
          width: double.infinity,
          height: 72,
          child: OutlinedButton(
            onPressed: onAddAnotherSymptom,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.primary.withOpacity(0.2), width: 2, style: BorderStyle.solid),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Add another symptom',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
