import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';
import 'package:eunora/features/onboarding/presentation/providers/symptoms_provider.dart';
import 'package:eunora/features/home/presentation/widgets/shared_logging/logging_card_wrapper.dart';
import 'package:eunora/features/home/presentation/widgets/shared_logging/gradient_slider_selector.dart';
import 'package:eunora/features/home/presentation/widgets/shared_logging/quantity_counter_selector.dart';

class EditSymptomsModalSheet extends ConsumerStatefulWidget {
  final List<Map<String, String>> initialSymptoms;
  final Function(List<Map<String, String>>) onSave;

  const EditSymptomsModalSheet({
    super.key,
    required this.initialSymptoms,
    required this.onSave,
  });

  @override
  ConsumerState<EditSymptomsModalSheet> createState() => _EditSymptomsModalSheetState();
}

class _EditSymptomsModalSheetState extends ConsumerState<EditSymptomsModalSheet> {
  late List<Map<String, String>> _draftSymptoms;

  @override
  void initState() {
    super.initState();
    // Create a deep copy of the initial symptoms list
    _draftSymptoms = widget.initialSymptoms
        .map((symptom) => Map<String, String>.from(symptom))
        .toList();
  }

  void _updateSeverity(int index, String severity) {
    setState(() {
      _draftSymptoms[index]['severity'] = severity;
    });
  }

  void _updateDuration(int index, int duration) {
    setState(() {
      _draftSymptoms[index]['duration'] = duration > 0 ? duration.toString() : '';
    });
  }

  void _deleteSymptom(int index) {
    setState(() {
      _draftSymptoms.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = _draftSymptoms.isEmpty;
    final library = ref.watch(symptomLibraryProvider);

    // Find symptom details by name
    Symptom findSymptomByName(String name) {
      final nameLower = name.toLowerCase();
      return library.firstWhere(
        (s) => s.name.toLowerCase() == nameLower,
        orElse: () => Symptom(
          id: 's_${nameLower.replaceAll(' ', '_')}',
          name: name,
          iconName: 'medical_services',
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.70,
      ),
      padding: const EdgeInsets.only(bottom: 24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFD0C4BC).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40), // Balance close button
                Text(
                  'Edit Symptoms',
                  style: GoogleFonts.notoSerif(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF2EDEA),
                    foregroundColor: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adjust symptom levels or remove them',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Scrollable list of symptoms
          if (isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: AppTheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No symptoms logged for today.',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: List.generate(_draftSymptoms.length, (index) {
                    final symptomMapEntry = _draftSymptoms[index];
                    final String name = symptomMapEntry['name'] ?? '';
                    final String severity = symptomMapEntry['severity'] ?? 'Mild';
                    final int duration = int.tryParse(symptomMapEntry['duration'] ?? '0') ?? 0;

                    final symptom = findSymptomByName(name);
                    final symIcon = symptom.getIconData();
                    final symColor = symptom.getIconColor();
                    final symBg = symColor.withValues(alpha: 0.1);
                    final nameLower = name.toLowerCase();
                    final symId = symptom.id.toLowerCase();
                    final hasDuration = symId == 'hot_flash' ||
                        symId == 'night_sweats' ||
                        symId == 's_hot_flashes' ||
                        symId == 's_night_sweats' ||
                        symId == 's_hot_flash' ||
                        nameLower == 'hot flashes' ||
                        nameLower == 'night sweats';

                    return LoggingCardWrapper(
                      name: name,
                      icon: symIcon,
                      color: symColor,
                      backgroundColor: symBg,
                      triggerValue: severity,
                      trailingAction: IconButton(
                        onPressed: () => _deleteSymptom(index),
                        icon: const Icon(Icons.delete_outline),
                        color: AppTheme.error,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      children: [
                        GradientSliderSelector(
                          values: const ['Mild', 'Moderate', 'Severe'],
                          currentValue: severity,
                          onChanged: (val) => _updateSeverity(index, val),
                          label: 'INTENSITY',
                          emojiGetter: (val) => _getEmojiForValue(name, val),
                        ),
                        if (hasDuration) ...[
                          const SizedBox(height: 20),
                          const Divider(color: Color(0xFFF7F5F0), height: 1),
                          QuantityCounterSelector(
                            value: duration,
                            label: 'DURATION',
                            onChanged: (val) => _updateDuration(index, val),
                            displayValueBuilder: (val) => val > 0 ? '$val min' : 'Not set',
                            stepValue: 5,
                            minValue: 0,
                            maxValue: 240,
                          ),
                        ],
                      ],
                    );
                  }),
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Footer Done button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSave(_draftSymptoms);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
