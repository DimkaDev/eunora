import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';
import 'package:eunora/features/onboarding/presentation/providers/symptoms_provider.dart';
import 'package:eunora/features/home/presentation/widgets/shared_logging/logging_card_wrapper.dart';
import 'package:eunora/features/home/presentation/widgets/shared_logging/gradient_slider_selector.dart';
import 'package:eunora/features/home/presentation/widgets/shared_logging/quantity_counter_selector.dart';

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
          final idLower = id.toLowerCase();
          final symNameLower = symName.toLowerCase();
          final hasDuration = idLower == 's_hot_flashes' ||
              idLower == 's_night_sweats' ||
              idLower == 'hot_flash' ||
              idLower == 'night_sweats' ||
              symNameLower == 'hot flashes' ||
              symNameLower == 'night sweats';
          final duration = symptomDurations[id] ?? 0;

          return LoggingCardWrapper(
            name: symName,
            icon: symIcon,
            color: symColor,
            backgroundColor: symBg,
            triggerValue: currentSeverity,
            children: [
              GradientSliderSelector(
                values: const ['Mild', 'Moderate', 'Severe'],
                currentValue: currentSeverity,
                onChanged: (val) => onSeverityChanged(MapEntry(id, val)),
                label: 'INTENSITY',
                emojiGetter: (val) => _getEmojiForValue(symName, val),
              ),
              if (hasDuration) ...[
                const SizedBox(height: 20),
                const Divider(color: Color(0xFFF7F5F0), height: 1),
                QuantityCounterSelector(
                  value: duration,
                  label: 'DURATION',
                  onChanged: (val) => onDurationChanged(MapEntry(id, val)),
                  displayValueBuilder: (val) => val > 0 ? '$val min' : 'Not set',
                  stepValue: 5,
                  minValue: 0,
                  maxValue: 240,
                ),
              ],
            ],
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

  String _getEmojiForValue(String name, String value) {
    final nameLower = name.toLowerCase();
    final valLower = value.toLowerCase();

    if (nameLower == 'hot flashes' || nameLower == 'night sweats') {
      if (valLower == 'mild') return '🌡️';
      if (valLower == 'moderate') return '🔥';
      if (valLower == 'severe') return '🥵';
    }

    switch (valLower) {
      case 'mild':
      case 'low':
        return '😊';
      case 'moderate':
      case 'medium':
        return '😐';
      case 'severe':
      case 'high':
      case 'intense':
        return '😟';
      default:
        return '✨';
    }
  }
}
