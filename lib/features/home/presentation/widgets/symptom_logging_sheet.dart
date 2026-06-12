import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/utils/animation_system.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';
import 'package:eunora/features/onboarding/presentation/providers/symptoms_provider.dart';
import 'package:eunora/features/home/presentation/widgets/shared_logging/logging_card_wrapper.dart';
import 'package:eunora/features/home/presentation/widgets/shared_logging/gradient_slider_selector.dart';
import 'package:eunora/features/home/presentation/widgets/shared_logging/quantity_counter_selector.dart';

class SymptomLoggingSheet extends ConsumerStatefulWidget {
  final List<Map<String, String>> loggedSymptoms;
  final Function(String name, String severity, int duration) onSave;

  const SymptomLoggingSheet({
    super.key,
    required this.loggedSymptoms,
    required this.onSave,
  });

  @override
  ConsumerState<SymptomLoggingSheet> createState() => _SymptomLoggingSheetState();
}

class _SymptomLoggingSheetState extends ConsumerState<SymptomLoggingSheet> {
  int _currentStep = 0; // 0: Select Symptom, 1: Select Severity
  Symptom? _selectedSymptom;
  String _selectedSeverity = 'Mild';
  int _selectedDuration = 15;
  
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(symptomLibraryProvider);
    final loggedNames = widget.loggedSymptoms.map((s) => s['name']?.toLowerCase()).toSet();

    // Filter out already logged symptoms, and apply search query if active
    final displaySymptoms = library.where((symptom) {
      final matchesLogged = !loggedNames.contains(symptom.name.toLowerCase());
      final matchesSearch = _searchQuery.isEmpty ||
          symptom.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesLogged && matchesSearch;
    }).toList();

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
                if (_currentStep == 1)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _currentStep = 0;
                      });
                    },
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF2EDEA),
                      foregroundColor: AppTheme.onSurfaceVariant,
                    ),
                  )
                else
                  const SizedBox(width: 40),
                Text(
                  _currentStep == 0 ? 'Add Symptom' : 'Rate Symptom',
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
          const SizedBox(height: 24),

          // Body without animation, fixed search bar at the top of step 0
          Flexible(
            child: _currentStep == 0
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: TextField(
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search symptoms...',
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF9B8B7E)),
                            filled: true,
                            fillColor: const Color(0xFFF2EDEA).withValues(alpha: 0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          style: GoogleFonts.manrope(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildSymptomSelection(displaySymptoms),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildSeveritySelection(),
                  ),
          ),

          // Action button (Only in Step 2)
          if (_currentStep == 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    if (_selectedSymptom != null) {
                      widget.onSave(_selectedSymptom!.name, _selectedSeverity, _selectedDuration);
                      Navigator.pop(context);
                    }
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
                    'Save Symptom',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSymptomSelection(List<Symptom> displaySymptoms) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (displaySymptoms.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No symptoms found',
                style: GoogleFonts.manrope(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: displaySymptoms.length,
            itemBuilder: (context, index) {
              final symptom = displaySymptoms[index];
              final symColor = symptom.getIconColor();
              final symBg = symColor.withValues(alpha: 0.1);

              return Bounceable(
                onTap: () {
                  setState(() {
                    _selectedSymptom = symptom;
                    _currentStep = 1;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
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
                          color: symBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          symptom.getIconData(),
                          color: symColor,
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
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF9B8B7E),
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 24),
      ],
    );
  }
  Widget _buildSeveritySelection() {
    if (_selectedSymptom == null) return const SizedBox.shrink();

    final symptom = _selectedSymptom!;
    final symName = symptom.name;
    final symIcon = symptom.getIconData();
    final symColor = symptom.getIconColor();
    final symBg = symColor.withValues(alpha: 0.1);
    final hasDuration = symptom.id == 's_hot_flashes' || symptom.id == 's_night_sweats';

    return LoggingCardWrapper(
      name: symName,
      icon: symIcon,
      color: symColor,
      backgroundColor: symBg,
      children: [
        GradientSliderSelector(
          values: const ['Mild', 'Moderate', 'Severe'],
          currentValue: _selectedSeverity,
          onChanged: (val) {
            setState(() {
              _selectedSeverity = val;
            });
          },
          label: 'INTENSITY',
          emojiGetter: (val) => _getEmojiForValue(symName, val),
        ),
        if (hasDuration) ...[
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF7F5F0), height: 1),
          QuantityCounterSelector(
            value: _selectedDuration,
            label: 'DURATION',
            onChanged: (val) {
              setState(() {
                _selectedDuration = val;
              });
            },
            displayValueBuilder: (val) => '$val min',
            stepValue: 5,
            minValue: 5,
          ),
        ],
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
