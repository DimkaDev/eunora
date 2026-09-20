import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/utils/animation_system.dart';
import 'package:eunora/features/onboarding/presentation/providers/triggers_provider.dart';
import 'package:eunora/features/home/presentation/widgets/shared_logging/logging_card_wrapper.dart';
import 'package:eunora/features/home/presentation/widgets/shared_logging/gradient_slider_selector.dart';
import 'package:eunora/features/home/presentation/widgets/shared_logging/quantity_counter_selector.dart';

class TriggerDetailsStep extends ConsumerWidget {
  final Set<String> selectedTriggerIds;
  final int caffeineCups;
  final int alcoholGlasses;
  final String stressLevel;
  final bool foodsTriggered;
  final String foodsNotes;
  final Map<String, int> customTriggerCounters;
  final Map<String, String> customTriggerTexts;

  final ValueChanged<int> onCaffeineCupsChanged;
  final ValueChanged<int> onAlcoholGlassesChanged;
  final ValueChanged<String> onStressLevelChanged;
  final ValueChanged<bool> onFoodsTriggeredChanged;
  final ValueChanged<String> onFoodsNotesChanged;
  final Function(String, int) onCustomTriggerCounterChanged;
  final Function(String, String) onCustomTriggerTextChanged;

  const TriggerDetailsStep({
    super.key,
    required this.selectedTriggerIds,
    required this.caffeineCups,
    required this.alcoholGlasses,
    required this.stressLevel,
    required this.foodsTriggered,
    required this.foodsNotes,
    required this.customTriggerCounters,
    required this.customTriggerTexts,
    required this.onCaffeineCupsChanged,
    required this.onAlcoholGlassesChanged,
    required this.onStressLevelChanged,
    required this.onFoodsTriggeredChanged,
    required this.onFoodsNotesChanged,
    required this.onCustomTriggerCounterChanged,
    required this.onCustomTriggerTextChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedTriggerIds.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.playlist_add_check,
                size: 64,
                color: Color(0xFFD0C4BC),
              ),
              const SizedBox(height: 16),
              Text(
                'No influences selected',
                style: GoogleFonts.notoSerif(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Go back and select influences to details.',
                style: GoogleFonts.manrope(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final library = ref.watch(triggerLibraryProvider);
    final triggerMap = {for (var t in library) t.id: t};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Journal Your Influences',
          style: GoogleFonts.notoSerif(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Reflect on today\'s triggers',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        ...selectedTriggerIds.map((trigId) {
          final isBuiltIn = triggerMap.containsKey(trigId);
          if (!isBuiltIn) {
            return _buildCustomTriggerDetailCard(trigId);
          }

          final trigger = triggerMap[trigId]!;
          final name = trigger.name;
          final nameLower = name.toLowerCase();

          if (trigId == 't_caffeine' ||
              trigId == 't_coffee' ||
              nameLower.contains('coffee') ||
              nameLower.contains('caffeine')) {
            return _buildCaffeineDetailCard();
          } else if (trigId == 't_alcohol' || nameLower.contains('alcohol')) {
            return _buildAlcoholDetailCard();
          } else if (trigId == 't_foods' ||
              trigId == 't_spicy_food' ||
              trigId == 't_sugar_processed_food' ||
              trigId == 't_hot_drinks_food' ||
              trigId == 't_skipped_meals' ||
              nameLower.contains('food') ||
              nameLower.contains('spicy') ||
              nameLower.contains('sugar') ||
              nameLower.contains('meal')) {
            return _buildFoodsDetailCard(trigId, name);
          } else if (trigId == 't_smoking' ||
              nameLower.contains('smoking') ||
              nameLower.contains('tobacco')) {
            return _buildSmokingDetailCard(trigId);
          } else if (trigId == 't_stress' ||
              nameLower.contains('stress') ||
              nameLower.contains('anxiety')) {
            return _buildStressDetailCard(context);
          } else if (trigId == 't_exercise' ||
              nameLower.contains('exercise') ||
              nameLower.contains('workout')) {
            return _buildExerciseDetailCard(trigId, name, trigger.getIconData());
          } else {
            final currentVal =
                customTriggerTexts[trigId] ?? _getTriggerValues(name)[1];
            return _buildOtherTriggerDetailCard(
              context,
              trigId,
              name,
              currentVal,
              trigger.getIconData(),
            );
          }
        }),
        const SizedBox(height: 20),
        // Reflection tip
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFEDDDF5).withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline, color: Color(0xFF9B6B9E), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(
                        text: 'Pro Tip: ',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const TextSpan(
                        text:
                            'High sodium can increase water retention and worsen night sweats. Try reducing salt in your evening meals.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCaffeineDetailCard() {
    const trigColor = Color(0xFF9B8B7E);
    final trigBg = trigColor.withValues(alpha: 0.1);
    return LoggingCardWrapper(
      name: 'Caffeine',
      icon: Icons.coffee,
      color: trigColor,
      backgroundColor: trigBg,
      triggerValue: caffeineCups,
      children: [
        QuantityCounterSelector(
          value: caffeineCups,
          label: 'HOW MUCH TODAY?',
          onChanged: onCaffeineCupsChanged,
          displayValueBuilder: (val) => '$val cup${val != 1 ? 's' : ''}',
          minValue: 0,
        ),
      ],
    );
  }

  Widget _buildAlcoholDetailCard() {
    const trigColor = Color(0xFFD4A5A5);
    final trigBg = trigColor.withValues(alpha: 0.1);
    return LoggingCardWrapper(
      name: 'Alcohol',
      icon: Icons.local_bar,
      color: trigColor,
      backgroundColor: trigBg,
      triggerValue: alcoholGlasses,
      children: [
        QuantityCounterSelector(
          value: alcoholGlasses,
          label: 'CONSUMPTION LOG',
          onChanged: onAlcoholGlassesChanged,
          displayValueBuilder: (val) => '$val glass${val != 1 ? 'es' : ''}',
          minValue: 0,
        ),
      ],
    );
  }

  Widget _buildStressDetailCard(BuildContext context) {
    const trigColor = Color(0xFFB8A7C5);
    final trigBg = trigColor.withValues(alpha: 0.1);
    return LoggingCardWrapper(
      name: 'Stress',
      icon: Icons.psychology,
      color: trigColor,
      backgroundColor: trigBg,
      triggerValue: stressLevel,
      children: [
        GradientSliderSelector(
          values: const ['Calm', 'Moderate', 'High'],
          currentValue: stressLevel,
          onChanged: onStressLevelChanged,
          label: 'INTENSITY LEVEL',
          emojiGetter: (val) => _getEmojiForValue('Stress', val),
        ),
      ],
    );
  }

  Widget _buildFoodsDetailCard(String trigId, String name) {
    const trigColor = Color(0xFFE5989B);
    final trigBg = trigColor.withValues(alpha: 0.1);
    
    // We can use the custom notes map for specific food triggers if trigId is not generic t_foods,
    // otherwise fallback to the generic foodsNotes.
    final initialNote = trigId == 't_foods' ? foodsNotes : (customTriggerTexts[trigId] ?? '');
    
    return LoggingCardWrapper(
      name: name,
      icon: Icons.restaurant,
      color: trigColor,
      backgroundColor: trigBg,
      triggerValue: initialNote,
      children: [
        const SizedBox(height: 12),
        TextFormField(
          initialValue: initialNote,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            hintText: trigId == 't_spicy_food'
                ? 'What spicy food did you eat?'
                : trigId == 't_hot_drinks_food'
                    ? 'Hot tea, soup, coffee...'
                    : trigId == 't_skipped_meals'
                        ? 'Which meal did you skip?'
                        : trigId == 't_sugar_processed_food'
                            ? 'Sweets, soda, processed snacks...'
                            : 'Spicy foods, heavy dinner...',
          ),
          style: GoogleFonts.manrope(
            fontSize: 13,
          ),
          maxLines: 2,
          onChanged: (val) {
            if (trigId == 't_foods') {
              onFoodsNotesChanged(val);
            } else {
              onCustomTriggerTextChanged(trigId, val);
            }
          },
        ),
      ],
    );
  }

  Widget _buildSmokingDetailCard(String trigId) {
    final counter = customTriggerCounters[trigId] ?? 0;
    const trigColor = Color(0xFF8B9B90);
    final trigBg = trigColor.withValues(alpha: 0.1);
    return LoggingCardWrapper(
      name: 'Smoking / tobacco',
      icon: Icons.smoke_free,
      color: trigColor,
      backgroundColor: trigBg,
      triggerValue: counter,
      children: [
        QuantityCounterSelector(
          value: counter,
          label: 'HOW MUCH TODAY?',
          onChanged: (val) => onCustomTriggerCounterChanged(trigId, val),
          displayValueBuilder: (val) => '$val time${val != 1 ? 's' : ''}',
          minValue: 0,
        ),
      ],
    );
  }

  Widget _buildCustomTriggerDetailCard(String trigId) {
    final counter = customTriggerCounters[trigId] ?? 1;
    final note = customTriggerTexts[trigId] ?? '';
    const trigColor = Color(0xFF8EB8B5);
    final trigBg = trigColor.withValues(alpha: 0.1);

    return LoggingCardWrapper(
      name: trigId,
      icon: Icons.stars,
      color: trigColor,
      backgroundColor: trigBg,
      triggerValue: counter,
      children: [
        QuantityCounterSelector(
          value: counter,
          label: 'Occurrence Level',
          onChanged: (val) => onCustomTriggerCounterChanged(trigId, val),
          displayValueBuilder: (val) => '$val time${val != 1 ? 's' : ''}',
          minValue: 1,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: note,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            hintText: 'Add any details...',
          ),
          style: GoogleFonts.manrope(fontSize: 13),
          onChanged: (val) => onCustomTriggerTextChanged(trigId, val),
        ),
      ],
    );
  }

  Widget _buildExerciseDetailCard(
    String trigId,
    String name,
    IconData icon,
  ) {
    final trigColor = _getTriggerColor(name);
    final trigBg = trigColor.withValues(alpha: 0.1);
    final values = _getTriggerValues(name);
    final currentIntensity = customTriggerTexts[trigId] ?? values[1];
    final currentDuration = customTriggerCounters[trigId] ??
        customTriggerCounters['t_exercise'] ??
        customTriggerCounters['exercise'] ??
        0;

    return LoggingCardWrapper(
      name: name,
      icon: icon,
      color: trigColor,
      backgroundColor: trigBg,
      triggerValue: '$currentIntensity-$currentDuration',
      children: [
        GradientSliderSelector(
          values: values,
          currentValue: values.contains(currentIntensity)
              ? currentIntensity
              : values[values.length ~/ 2],
          onChanged: (val) => onCustomTriggerTextChanged(trigId, val),
          label: 'INTENSITY',
          emojiGetter: (val) => _getEmojiForValue(name, val),
        ),
        const SizedBox(height: 20),
        const Divider(color: Color(0xFFF7F5F0), height: 1),
        QuantityCounterSelector(
          value: currentDuration,
          label: 'DURATION',
          onChanged: (val) => onCustomTriggerCounterChanged(trigId, val),
          displayValueBuilder: (val) => val > 0 ? '$val min' : 'Not set',
          stepValue: 5,
          minValue: 0,
          maxValue: 240,
        ),
      ],
    );
  }

  Widget _buildOtherTriggerDetailCard(
    BuildContext context,
    String trigId,
    String name,
    String value,
    IconData icon,
  ) {
    final trigColor = _getTriggerColor(name);
    final trigBg = trigColor.withValues(alpha: 0.1);
    final values = _getTriggerValues(name);
    return LoggingCardWrapper(
      name: name,
      icon: icon,
      color: trigColor,
      backgroundColor: trigBg,
      triggerValue: value,
      children: [
        GradientSliderSelector(
          values: values,
          currentValue: values.contains(value)
              ? value
              : values[values.length ~/ 2],
          onChanged: (val) => onCustomTriggerTextChanged(trigId, val),
          label: 'TRIGGER LEVEL / QUANTITY',
          emojiGetter: (val) => _getEmojiForValue(name, val),
        ),
      ],
    );
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
