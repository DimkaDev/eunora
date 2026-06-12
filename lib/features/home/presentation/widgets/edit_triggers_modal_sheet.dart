import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/home/presentation/widgets/shared_logging/logging_card_wrapper.dart';
import 'package:eunora/features/home/presentation/widgets/shared_logging/gradient_slider_selector.dart';
import 'package:eunora/features/home/presentation/widgets/shared_logging/quantity_counter_selector.dart';

class EditTriggersModalSheet extends StatefulWidget {
  final List<Map<String, dynamic>> initialTriggers;
  final Function(List<Map<String, dynamic>>) onSave;

  const EditTriggersModalSheet({
    super.key,
    required this.initialTriggers,
    required this.onSave,
  });

  @override
  State<EditTriggersModalSheet> createState() => _EditTriggersModalSheetState();
}

class _EditTriggersModalSheetState extends State<EditTriggersModalSheet> {
  late List<Map<String, dynamic>> _draftTriggers;

  @override
  void initState() {
    super.initState();
    // Deep copy of initial triggers list
    _draftTriggers = widget.initialTriggers
        .map((trigger) => Map<String, dynamic>.from(trigger))
        .toList();
  }

  void _deleteTrigger(String name) {
    setState(() {
      _draftTriggers.removeWhere((t) => t['name'] == name);
    });
  }

  void _updateCaffeineCups(int index, int cups) {
    setState(() {
      _draftTriggers[index]['value'] = '$cups cup${cups > 1 ? 's' : ''}';
    });
  }

  void _updateAlcoholGlasses(int index, int glasses) {
    setState(() {
      _draftTriggers[index]['value'] = '$glasses glass${glasses > 1 ? 'es' : ''}';
    });
  }

  void _updateStressLevel(int index, String level) {
    setState(() {
      _draftTriggers[index]['value'] = 'Level: $level';
    });
  }

  void _updateOtherValue(int index, String newValue) {
    setState(() {
      _draftTriggers[index]['value'] = newValue;
    });
  }

  Color _getTriggerColor(String name) {
    switch (name.toLowerCase()) {
      case 'stress':
        return const Color(0xFFB8A7C5); // brand-lavender
      case 'caffeine':
        return const Color(0xFF9B8B7E);
      case 'alcohol':
        return const Color(0xFFD4A5A5); // brand-rose
      case 'sugar':
      case 'sugar & sweets':
        return const Color(0xFFA9B388);
      case 'lack of sleep':
      case 'poor sleep':
        return const Color(0xFFA7C5D8);
      case 'spicy food':
      case 'foods':
        return const Color(0xFFE5989B);
      default:
        return const Color(0xFF8EB8B5); // brand-teal
    }
  }

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
    final bool isEmpty = _draftTriggers.isEmpty;

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
                const SizedBox(width: 40),
                Text(
                  'Update Your Triggers',
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
          const SizedBox(height: 4),
          Text(
            'Adjust quantity or update triggers',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Content Area
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No triggers logged today.',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: List.generate(_draftTriggers.length, (index) {
                        final trigger = _draftTriggers[index];
                        final String name = trigger['name'] ?? '';
                        final String value = trigger['value'] ?? '';
                        final IconData icon = trigger['icon'] ?? Icons.bolt;

                        final bool isCaffeine = name.toLowerCase() == 'caffeine';
                        final bool isAlcohol = name.toLowerCase() == 'alcohol';
                        final bool isStress = name.toLowerCase() == 'stress';

                        final trigColor = _getTriggerColor(name);
                        final trigBg = trigColor.withValues(alpha: 0.1);

                        return LoggingCardWrapper(
                          name: name,
                          icon: icon,
                          color: trigColor,
                          backgroundColor: trigBg,
                          trailingAction: IconButton(
                            onPressed: () => _deleteTrigger(name),
                            icon: const Icon(Icons.delete_outline),
                            color: AppTheme.error,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          children: [
                            if (isCaffeine) ...[
                              QuantityCounterSelector(
                                value: int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1,
                                label: 'HOW MUCH TODAY?',
                                onChanged: (cups) => _updateCaffeineCups(index, cups),
                                displayValueBuilder: (cups) => '$cups cup${cups != 1 ? 's' : ''}',
                                minValue: 1,
                              ),
                            ] else if (isAlcohol) ...[
                              QuantityCounterSelector(
                                value: int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1,
                                label: 'CONSUMPTION LOG',
                                onChanged: (glasses) => _updateAlcoholGlasses(index, glasses),
                                displayValueBuilder: (glasses) => '$glasses glass${glasses != 1 ? 'es' : ''}',
                                minValue: 1,
                              ),
                            ] else if (isStress) ...[
                              GradientSliderSelector(
                                values: const ['Calm', 'Moderate', 'High'],
                                currentValue: value.replaceAll('Level: ', '').trim(),
                                onChanged: (level) => _updateStressLevel(index, level),
                                label: 'INTENSITY LEVEL',
                                emojiGetter: (val) => _getEmojiForValue(name, val),
                              ),
                            ] else ...[
                              GradientSliderSelector(
                                values: _getTriggerValues(name),
                                currentValue: value,
                                onChanged: (newVal) => _updateOtherValue(index, newVal),
                                label: 'TRIGGER LEVEL / QUANTITY',
                                emojiGetter: (val) => _getEmojiForValue(name, val),
                              ),
                            ],
                          ],
                        );
                      }),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Done Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSave(_draftTriggers);
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
