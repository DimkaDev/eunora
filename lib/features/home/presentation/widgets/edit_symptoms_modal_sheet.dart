import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';
import 'package:eunora/features/onboarding/presentation/providers/symptoms_provider.dart';

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

                    final symptom = findSymptomByName(name);
                    final symIcon = symptom.getIconData();
                    final symColor = symptom.getIconColor();
                    final symBg = symColor.withValues(alpha: 0.1);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: symColor.withValues(alpha: 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Icon, Name & Delete button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    name,
                                    style: GoogleFonts.manrope(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: () => _deleteSymptom(index),
                                icon: const Icon(Icons.delete_outline),
                                color: AppTheme.error,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
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
                          
                          // Custom fluid severity bar
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
                                // Sliding thumb
                                AnimatedAlign(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  alignment: severity == 'Mild'
                                      ? Alignment.centerLeft
                                      : severity == 'Moderate'
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
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _updateSeverity(index, 'Mild'),
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
                                                  color: severity == 'Mild' ? AppTheme.primary : const Color(0xFF8A817C),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _updateSeverity(index, 'Moderate'),
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
                                                  color: severity == 'Moderate' ? AppTheme.primary : const Color(0xFF8A817C),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _updateSeverity(index, 'Severe'),
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
                                                  color: severity == 'Severe' ? AppTheme.primary : const Color(0xFF8A817C),
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
                        ],
                      ),
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
}
