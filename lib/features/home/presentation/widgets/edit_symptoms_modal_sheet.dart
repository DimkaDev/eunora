import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';

class EditSymptomsModalSheet extends StatefulWidget {
  final List<Map<String, String>> initialSymptoms;
  final Function(List<Map<String, String>>) onSave;

  const EditSymptomsModalSheet({
    super.key,
    required this.initialSymptoms,
    required this.onSave,
  });

  @override
  State<EditSymptomsModalSheet> createState() => _EditSymptomsModalSheetState();
}

class _EditSymptomsModalSheetState extends State<EditSymptomsModalSheet> {
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
                    final symptom = _draftSymptoms[index];
                    final String name = symptom['name'] ?? '';
                    final String severity = symptom['severity'] ?? 'Mild';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Name & Delete button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.manrope(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.onSurface,
                                ),
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
                          const SizedBox(height: 12),

                          // Severity segment selectors
                          Row(
                            children: ['Mild', 'Moderate', 'Severe'].map((level) {
                              final isSelected = severity == level;
                              Color selectedColor = AppTheme.primary;
                              if (level == 'Moderate') selectedColor = const Color(0xFF817266);
                              if (level == 'Severe') selectedColor = const Color(0xFF814F45);

                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: InkWell(
                                    onTap: () => _updateSeverity(index, level),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected ? selectedColor : const Color(0xFFF8F2F0),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? selectedColor : Colors.transparent,
                                        ),
                                      ),
                                      child: Text(
                                        level,
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
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
