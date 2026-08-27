import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/home/presentation/widgets/shared_logging/logging_card_wrapper.dart';
import 'package:eunora/features/home/presentation/widgets/shared_logging/gradient_slider_selector.dart';
import 'package:eunora/features/home/presentation/widgets/shared_logging/quantity_counter_selector.dart';

// ---------------------------------------------------------------------------
// EditTriggersModalSheet
// Lets the user edit quantities/values of already-logged triggers.
// UI matches the detail step of daily logging exactly.
// ---------------------------------------------------------------------------

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
  // Each entry in _draftTriggers mirrors the structure of initialTriggers.
  // We also keep parallel state maps for counter values and text notes so that
  // QuantityCounterSelector and TextField widgets are properly stateful.
  late List<Map<String, dynamic>> _draftTriggers;
  final Map<int, int> _counterState = {};    // index → int (for counter triggers)
  final Map<int, String> _textState = {};    // index → string (for food notes)

  // ─── init ─────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _draftTriggers = widget.initialTriggers
        .map((t) => Map<String, dynamic>.from(t))
        .toList();

    // Pre-populate state maps from existing saved values
    for (int i = 0; i < _draftTriggers.length; i++) {
      final name = (_draftTriggers[i]['name'] as String? ?? '').toLowerCase();
      final value = _draftTriggers[i]['value'] as String? ?? '';

      if (_isCaffeineName(name) || _isAlcoholName(name) || _isSmokingName(name)) {
        _counterState[i] = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
      } else if (_isExerciseName(name)) {
        int? mins;
        if (value.contains('min')) {
          mins = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
        }
        _counterState[i] = mins ?? 0;
        final parts = value.replaceAll(RegExp(r'\d+\s*min'), '').replaceAll('·', '').trim();
        _draftTriggers[i]['intensity'] = parts.isNotEmpty && parts != 'Logged' ? parts : 'Moderate';
      } else if (_isFoodName(name)) {
        // Foods: value may be the note text, or 'Noted' placeholder
        _textState[i] = (value == 'Noted') ? '' : value;
      } else {
        // Slider-based — value is already the readable level string
      }
    }
  }

  // ─── name-based helpers (same logic as trigger_details_step) ──────────────

  bool _isCaffeineName(String n) =>
      n == 'caffeine' || n == 'coffee';

  bool _isAlcoholName(String n) =>
      n == 'alcohol';

  bool _isSmokingName(String n) =>
      n.contains('smoking') || n.contains('tobacco');

  bool _isExerciseName(String n) =>
      n == 'exercise';

  bool _isFoodName(String n) =>
      n == 'foods' ||
      n == 'food' ||
      n == 'spicy food' ||
      n == 'sugar & processed food' ||
      n == 'hot drinks & food' ||
      n == 'skipped meals' ||
      n == 'sugar' ||
      n == 'sugar & sweets';

  bool _isStressName(String n) => n == 'stress';

  String _foodHint(String name) {
    switch (name.toLowerCase()) {
      case 'spicy food':            return 'What spicy food did you eat?';
      case 'hot drinks & food':     return 'Hot tea, soup, coffee...';
      case 'skipped meals':         return 'Which meal did you skip?';
      case 'sugar & processed food':return 'Sweets, soda, processed snacks...';
      default:                      return 'Spicy foods, heavy dinner...';
    }
  }

  // ─── mutations ────────────────────────────────────────────────────────────

  void _deleteTrigger(int index) {
    setState(() {
      _draftTriggers.removeAt(index);
      // Remap counter/text state with shifted keys
      final newCounter = <int, int>{};
      final newText    = <int, String>{};
      _counterState.forEach((k, v) {
        if (k < index) { newCounter[k] = v; }
        else if (k > index) { newCounter[k - 1] = v; }
      });
      _textState.forEach((k, v) {
        if (k < index) { newText[k] = v; }
        else if (k > index) { newText[k - 1] = v; }
      });
      _counterState
        ..clear()
        ..addAll(newCounter);
      _textState
        ..clear()
        ..addAll(newText);
    });
  }

  void _setCounter(int index, int val, String unit) {
    setState(() {
      _counterState[index] = val;
      _draftTriggers[index]['value'] = '$val $unit';
    });
  }

  void _setExerciseDuration(int index, int minutes) {
    setState(() {
      _counterState[index] = minutes;
      _updateExerciseValue(index);
    });
  }

  void _setExerciseIntensity(int index, String intensity) {
    setState(() {
      _draftTriggers[index]['intensity'] = intensity;
      _updateExerciseValue(index);
    });
  }

  void _updateExerciseValue(int index) {
    final mins = _counterState[index] ?? 0;
    if (mins > 0) {
      _draftTriggers[index]['value'] = '$mins min';
    } else {
      _draftTriggers[index]['value'] = 'Logged';
    }
  }

  void _setText(int index, String text) {
    setState(() {
      _textState[index] = text;
      _draftTriggers[index]['value'] = text.isEmpty ? 'Noted' : text;
    });
  }

  void _setSliderValue(int index, String val) {
    setState(() {
      _draftTriggers[index]['value'] = val;
    });
  }

  // ─── colors / values ──────────────────────────────────────────────────────

  Color _getTriggerColor(String name) {
    switch (name.toLowerCase()) {
      case 'stress':            return const Color(0xFFB8A7C5);
      case 'caffeine':
      case 'coffee':            return const Color(0xFF9B8B7E);
      case 'alcohol':           return const Color(0xFFD4A5A5);
      case 'sugar':
      case 'sugar & sweets':    return const Color(0xFFA9B388);
      case 'lack of sleep':
      case 'poor sleep':        return const Color(0xFFA7C5D8);
      case 'spicy food':
      case 'foods':
      case 'food':              return const Color(0xFFE5989B);
      default:                  return const Color(0xFF8EB8B5);
    }
  }

  List<String> _getSliderValues(String name) {
    switch (name.toLowerCase()) {
      case 'stress':            return ['Calm', 'Moderate', 'High'];
      case 'poor sleep':
      case 'lack of sleep':
      case 'dehydration':       return ['Mild', 'Moderate', 'Severe'];
      case 'exercise':          return ['Light', 'Moderate', 'Intense'];
      case 'weather':           return ['Sunny', 'Humid', 'Cold/Change'];
      case 'travel':            return ['Short', 'Medium', 'Long'];
      case 'work':
      case 'overworking':       return ['1-2 hours', '3-4 hours', '5+ hours'];
      default:                  return ['Low', 'Moderate', 'High'];
    }
  }

  String _getEmojiForValue(String name, String value) {
    final n = name.toLowerCase();
    final v = value.toLowerCase();

    if (n == 'stress') {
      if (v == 'calm') return '😊';
      if (v == 'moderate') return '😐';
      if (v == 'high') return '😟';
    }
    if (n == 'poor sleep' || n == 'lack of sleep' || n == 'dehydration') {
      if (v == 'mild') return '😊';
      if (v == 'moderate') return '😐';
      if (v == 'severe') return '😟';
    }
    if (n == 'exercise') {
      if (v == 'light') return '🚶';
      if (v == 'moderate') return '🏃';
      if (v == 'intense') return '🏋️';
    }
    if (n == 'weather') {
      if (v == 'sunny') return '☀️';
      if (v == 'humid') return '☁️';
      if (v.contains('cold')) return '❄️';
    }
    if (n == 'travel') {
      if (v == 'short') return '🚗';
      if (v == 'medium') return '✈️';
      if (v == 'long') return '🌍';
    }
    if (n == 'work' || n == 'overworking') {
      if (v == '1-2 hours') return '⌚';
      if (v == '3-4 hours') return '⏰';
      if (v == '5+ hours') return '⏳';
    }
    switch (v) {
      case 'calm':
      case 'mild':
      case 'low':       return '😊';
      case 'moderate':  return '😐';
      case 'high':
      case 'severe':
      case 'intense':   return '😟';
      case 'light':     return '🚶';
      case 'sunny':     return '☀️';
      case 'humid':     return '☁️';
      case 'cold/change': return '❄️';
      case 'short':     return '🚗';
      case 'medium':    return '✈️';
      case 'long':      return '🌍';
      case '1-2 hours': return '⌚';
      case '3-4 hours': return '⏰';
      case '5+ hours':  return '⏳';
      default:          return '✨';
    }
  }

  // ─── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.80),
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

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_draftTriggers.isEmpty)
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
                    ...List.generate(
                      _draftTriggers.length,
                      (index) => _buildTriggerCard(index),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Save button
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

  // ─── individual trigger card ───────────────────────────────────────────────

  Widget _buildTriggerCard(int index) {
    final trigger  = _draftTriggers[index];
    final String name  = trigger['name'] as String? ?? '';
    final IconData icon = trigger['icon'] as IconData? ?? Icons.bolt;
    final nameLower = name.toLowerCase();

    final trigColor = _getTriggerColor(name);
    final trigBg    = trigColor.withValues(alpha: 0.1);

    // Delete button shared by all cards
    final deleteBtn = IconButton(
      onPressed: () => _deleteTrigger(index),
      icon: const Icon(Icons.delete_outline),
      color: AppTheme.error,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );

    // ── Caffeine ──
    if (_isCaffeineName(nameLower)) {
      final count = _counterState[index] ?? 1;
      return LoggingCardWrapper(
        name: name,
        icon: icon,
        color: trigColor,
        backgroundColor: trigBg,
        trailingAction: deleteBtn,
        children: [
          QuantityCounterSelector(
            value: count,
            label: 'HOW MUCH TODAY?',
            onChanged: (val) => _setCounter(
              index, val, 'cup${val != 1 ? 's' : ''}'),
            displayValueBuilder: (val) => '$val cup${val != 1 ? 's' : ''}',
            minValue: 0,
          ),
        ],
      );
    }

    // ── Alcohol ──
    if (_isAlcoholName(nameLower)) {
      final count = _counterState[index] ?? 1;
      return LoggingCardWrapper(
        name: name,
        icon: icon,
        color: trigColor,
        backgroundColor: trigBg,
        trailingAction: deleteBtn,
        children: [
          QuantityCounterSelector(
            value: count,
            label: 'CONSUMPTION LOG',
            onChanged: (val) => _setCounter(
              index, val, 'glass${val != 1 ? 'es' : ''}'),
            displayValueBuilder: (val) =>
                '$val glass${val != 1 ? 'es' : ''}',
            minValue: 0,
          ),
        ],
      );
    }

    // ── Smoking / Tobacco ──
    if (_isSmokingName(nameLower)) {
      final count = _counterState[index] ?? 1;
      return LoggingCardWrapper(
        name: name,
        icon: icon,
        color: const Color(0xFF8B9B90),
        backgroundColor: const Color(0xFF8B9B90).withValues(alpha: 0.1),
        trailingAction: deleteBtn,
        children: [
          QuantityCounterSelector(
            value: count,
            label: 'HOW MUCH TODAY?',
            onChanged: (val) => _setCounter(
              index, val, 'time${val != 1 ? 's' : ''}'),
            displayValueBuilder: (val) =>
                '$val time${val != 1 ? 's' : ''}',
            minValue: 0,
          ),
        ],
      );
    }

    // ── Foods / food variants ──
    if (_isFoodName(nameLower)) {
      final note = _textState[index] ?? '';
      return LoggingCardWrapper(
        name: name,
        icon: icon,
        color: const Color(0xFFE5989B),
        backgroundColor: const Color(0xFFE5989B).withValues(alpha: 0.1),
        trailingAction: deleteBtn,
        children: [
          const SizedBox(height: 12),
          TextFormField(
            initialValue: note,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              hintText: _foodHint(name),
            ),
            style: GoogleFonts.manrope(fontSize: 13),
            maxLines: 2,
            onChanged: (val) => _setText(index, val),
          ),
        ],
      );
    }

    // ── Stress ──
    if (_isStressName(nameLower)) {
      final currentLevel = (trigger['value'] as String? ?? 'Moderate')
          .replaceAll('Level: ', '')
          .trim();
      final List<String> stressVals = ['Calm', 'Moderate', 'High'];
      final safeVal = stressVals.contains(currentLevel) ? currentLevel : 'Moderate';
      return LoggingCardWrapper(
        name: name,
        icon: icon,
        color: trigColor,
        backgroundColor: trigBg,
        trailingAction: deleteBtn,
        children: [
          GradientSliderSelector(
            values: stressVals,
            currentValue: safeVal,
            onChanged: (val) => _setSliderValue(index, val),
            label: 'INTENSITY LEVEL',
            emojiGetter: (val) => _getEmojiForValue(name, val),
          ),
        ],
      );
    }

    // ── Exercise ──
    if (_isExerciseName(nameLower)) {
      final mins = _counterState[index] ?? 0;
      final intensity = (_draftTriggers[index]['intensity'] as String?) ?? 'Moderate';
      final List<String> exerciseVals = ['Light', 'Moderate', 'Intense'];
      final safeIntensity = exerciseVals.contains(intensity) ? intensity : 'Moderate';

      return LoggingCardWrapper(
        name: name,
        icon: icon,
        color: trigColor,
        backgroundColor: trigBg,
        trailingAction: deleteBtn,
        children: [
          GradientSliderSelector(
            values: exerciseVals,
            currentValue: safeIntensity,
            onChanged: (val) => _setExerciseIntensity(index, val),
            label: 'INTENSITY',
            emojiGetter: (val) => _getEmojiForValue(name, val),
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF7F5F0), height: 1),
          QuantityCounterSelector(
            value: mins,
            label: 'DURATION',
            onChanged: (val) => _setExerciseDuration(index, val),
            displayValueBuilder: (val) => val > 0 ? '$val min' : 'Not set',
            stepValue: 5,
            minValue: 0,
            maxValue: 240,
          ),
        ],
      );
    }

    // ── All other triggers (slider) ──
    final sliderVals = _getSliderValues(name);
    final currentVal = trigger['value'] as String? ?? '';
    final safeVal =
        sliderVals.contains(currentVal) ? currentVal : sliderVals[sliderVals.length ~/ 2];

    return LoggingCardWrapper(
      name: name,
      icon: icon,
      color: trigColor,
      backgroundColor: trigBg,
      trailingAction: deleteBtn,
      children: [
        GradientSliderSelector(
          values: sliderVals,
          currentValue: safeVal,
          onChanged: (val) => _setSliderValue(index, val),
          label: 'TRIGGER LEVEL / QUANTITY',
          emojiGetter: (val) => _getEmojiForValue(name, val),
        ),
      ],
    );
  }
}
