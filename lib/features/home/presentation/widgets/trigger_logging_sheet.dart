import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/utils/animation_system.dart';
import 'package:eunora/features/onboarding/domain/models/trigger.dart';
import 'package:eunora/features/onboarding/presentation/providers/triggers_provider.dart';
import 'package:eunora/features/home/presentation/widgets/shared_logging/logging_card_wrapper.dart';
import 'package:eunora/features/home/presentation/widgets/shared_logging/gradient_slider_selector.dart';
import 'package:eunora/features/home/presentation/widgets/shared_logging/quantity_counter_selector.dart';
import 'package:eunora/features/symptom_log/data/trigger_library.dart';

class TriggerLoggingSheet extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> loggedTriggers;
  final Function(String name, String value, IconData icon) onSave;

  const TriggerLoggingSheet({
    super.key,
    required this.loggedTriggers,
    required this.onSave,
  });

  @override
  ConsumerState<TriggerLoggingSheet> createState() => _TriggerLoggingSheetState();
}

class _TriggerLoggingSheetState extends ConsumerState<TriggerLoggingSheet> {
  int _currentStep = 0; // 0: Select Trigger, 1: Select Level
  TriggerOption? _selectedTrigger;
  String? _selectedValue;
  String _searchQuery = '';
  bool _showAllTriggers = false;

  List<String> _getTriggerValues(String name) {
    switch (name.toLowerCase()) {
      case 'caffeine':
        return ['1 Cup', '2 Cups', '3 Cups'];
      case 'alcohol':
        return ['1 Glass', '2 Glasses', '3 Glasses'];
      case 'stress':
        return ['Calm', 'Moderate', 'High'];
      case 'poor sleep':
      case 'lack of sleep':
      case 'dehydration':
        return ['Mild', 'Moderate', 'Severe'];
      case 'exercise':
        return ['Light', 'Moderate', 'Intense'];
      case 'weather':
        return ['Sunny', 'Humid', 'Cold/Change'];
      case 'foods':
      case 'spicy food':
        return ['Low', 'Moderate', 'High'];
      case 'smoking':
      case 'smoking/tobacco':
        return ['Low', 'Moderate', 'High'];
      case 'travel':
        return ['Short', 'Medium', 'Long'];
      case 'work':
      case 'overworking':
        return ['1-2 hours', '3-4 hours', '5+ hours'];
      case 'sugar':
      case 'sugar & sweets':
        return ['Low', 'Moderate', 'High'];
      case 'relaxation':
      case 'lack of rest':
        return ['Low', 'Moderate', 'High'];
      default:
        return ['Low', 'Moderate', 'High'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(triggerLibraryProvider);
    final loggedNames = widget.loggedTriggers.map((t) => t['name']?.toString().toLowerCase()).toSet();

    // Filter out already logged triggers, and apply search query
    final displayTriggers = library.where((trigger) {
      final matchesLogged = !loggedNames.contains(trigger.name.toLowerCase());
      final matchesSearch = _searchQuery.isEmpty ||
          trigger.name.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;
      if (_searchQuery.isNotEmpty) return matchesLogged;

      final def = kTriggerLibrary.where((d) => 't_${d.id}' == trigger.id).firstOrNull;
      if (def == null) return matchesLogged;

      if (_showAllTriggers) {
        return matchesLogged;
      } else {
        return matchesLogged && def.tier == TriggerTier.core;
      }
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
                  _currentStep == 0 ? 'Add Daily Trigger' : 'Rate Trigger',
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
                            hintText: 'Search triggers...',
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
                          child: _buildTriggerSelection(displayTriggers),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildLevelSelection(),
                  ),
          ),

          // Action Button (Only in Step 2)
          if (_currentStep == 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _selectedTrigger == null || _selectedValue == null
                      ? null
                      : () {
                          widget.onSave(
                            _selectedTrigger!.name,
                            _selectedValue!,
                            _selectedTrigger!.getIconData(),
                          );
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.4),
                    disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Save Trigger',
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

  Widget _buildTriggerSelection(List<TriggerOption> displayTriggers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (displayTriggers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No triggers found',
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
            itemCount: displayTriggers.length,
            itemBuilder: (context, index) {
              final trigger = displayTriggers[index];
              final name = trigger.name;
              final icon = trigger.getIconData();
              final trigColor = trigger.getIconColor();
              final trigBg = trigColor.withValues(alpha: 0.1);

              return Bounceable(
                onTap: () {
                  setState(() {
                    _selectedTrigger = trigger;
                    final vals = _getTriggerValues(name);
                    _selectedValue = vals.isNotEmpty ? vals[vals.length ~/ 2] : 'Moderate';
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
                          color: trigBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: trigColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF9B8B7E),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showAllTriggers = !_showAllTriggers;
                  });
                },
                icon: Icon(
                  _showAllTriggers ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppTheme.primary,
                ),
                label: Text(
                  _showAllTriggers ? 'Show less' : 'More triggers',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
          ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLevelSelection() {
    if (_selectedTrigger == null) return const SizedBox.shrink();

    final name = _selectedTrigger!.name;
    final icon = _selectedTrigger!.getIconData();
    final trigColor = _selectedTrigger!.getIconColor();
    final trigBg = trigColor.withValues(alpha: 0.1);

    final isCaffeine = name.toLowerCase() == 'caffeine';
    final isAlcohol = name.toLowerCase() == 'alcohol';
    final isStress = name.toLowerCase() == 'stress';

    return LoggingCardWrapper(
      name: name,
      icon: icon,
      color: trigColor,
      backgroundColor: trigBg,
      children: [
        if (isCaffeine) ...[
          QuantityCounterSelector(
            value: int.tryParse((_selectedValue ?? '1').replaceAll(RegExp(r'[^0-9]'), '')) ?? 1,
            label: 'HOW MUCH TODAY?',
            onChanged: (val) {
              setState(() {
                _selectedValue = '$val cup${val != 1 ? 's' : ''}';
              });
            },
            displayValueBuilder: (val) => '$val cup${val != 1 ? 's' : ''}',
            minValue: 1,
          ),
        ] else if (isAlcohol) ...[
          QuantityCounterSelector(
            value: int.tryParse((_selectedValue ?? '1').replaceAll(RegExp(r'[^0-9]'), '')) ?? 1,
            label: 'CONSUMPTION LOG',
            onChanged: (val) {
              setState(() {
                _selectedValue = '$val glass${val != 1 ? 'es' : ''}';
              });
            },
            displayValueBuilder: (val) => '$val glass${val != 1 ? 'es' : ''}',
            minValue: 1,
          ),
        ] else if (isStress) ...[
          GradientSliderSelector(
            values: const ['Calm', 'Moderate', 'High'],
            currentValue: _selectedValue ?? 'Moderate',
            onChanged: (val) {
              setState(() {
                _selectedValue = val;
              });
            },
            label: 'INTENSITY LEVEL',
            emojiGetter: (val) => _getEmojiForValue(name, val),
          ),
        ] else ...[
          GradientSliderSelector(
            values: _getTriggerValues(name),
            currentValue: _selectedValue ?? (_getTriggerValues(name).isNotEmpty ? _getTriggerValues(name)[_getTriggerValues(name).length ~/ 2] : 'Moderate'),
            onChanged: (val) {
              setState(() {
                _selectedValue = val;
              });
            },
            label: 'TRIGGER LEVEL / QUANTITY',
            emojiGetter: (val) => _getEmojiForValue(name, val),
          ),
        ],
      ],
    );
  }

  String _getEmojiForValue(String name, String value) {
    final nameLower = name.toLowerCase();
    final valLower = value.toLowerCase();

    if (nameLower == 'stress') {
      if (valLower == 'calm') return '😊';
      if (valLower == 'moderate') return '😐';
      if (valLower == 'high') return '😟';
    }
    if (nameLower == 'poor sleep' || nameLower == 'lack of sleep') {
      if (valLower == 'mild') return '😊';
      if (valLower == 'moderate') return '😐';
      if (valLower == 'severe') return '😟';
    }
    if (nameLower == 'dehydration') {
      if (valLower == 'mild') return '😊';
      if (valLower == 'moderate') return '😐';
      if (valLower == 'severe') return '😟';
    }
    if (nameLower == 'exercise') {
      if (valLower == 'light') return '🚶';
      if (valLower == 'moderate') return '🏃';
      if (valLower == 'intense') return '🏋️';
    }
    if (nameLower == 'weather') {
      if (valLower == 'sunny') return '☀️';
      if (valLower == 'humid') return '☁️';
      if (valLower == 'cold/change' || valLower.contains('cold')) return '❄️';
    }
    if (nameLower == 'travel') {
      if (valLower == 'short') return '🚗';
      if (valLower == 'medium') return '✈️';
      if (valLower == 'long') return '🌍';
    }
    if (nameLower == 'work' || nameLower == 'overworking') {
      if (valLower == '1-2 hours') return '⌚';
      if (valLower == '3-4 hours') return '⏰';
      if (valLower == '5+ hours') return '⏳';
    }

    switch (valLower) {
      case 'calm':
      case 'mild':
      case 'low':
        return '😊';
      case 'moderate':
        return '😐';
      case 'high':
      case 'severe':
      case 'intense':
        return '😟';
      case 'light':
        return '🚶';
      case 'sunny':
        return '☀️';
      case 'humid':
        return '☁️';
      case 'cold/change':
        return '❄️';
      case 'short':
        return '🚗';
      case 'medium':
        return '✈️';
      case 'long':
        return '🌍';
      case '1-2 hours':
        return '⌚';
      case '3-4 hours':
        return '⏰';
      case '5+ hours':
        return '⏳';
      default:
        return '✨';
    }
  }
}
