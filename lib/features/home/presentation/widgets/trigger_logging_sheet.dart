import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  int _currentStep = 0; // 0: Select Trigger, 1: Configure details
  TriggerOption? _selectedTrigger;
  String? _tappingTriggerId;

  // State for the detail step (mirrors daily logging)
  String? _selectedValue;   // For slider-based triggers
  int _counterValue = 1;    // For quantity-counter triggers (caffeine, alcohol, smoking)
  String _textNote = '';    // For food/text triggers

  String _searchQuery = '';
  bool _showAllTriggers = false;

  // ─── helpers (mirrors trigger_details_step.dart) ─────────────────────────

  bool get _isCaffeine =>
      _selectedTrigger?.id == 't_caffeine' ||
      _selectedTrigger?.id == 't_coffee' ||
      _selectedTrigger?.name.toLowerCase() == 'caffeine';

  bool get _isAlcohol =>
      _selectedTrigger?.id == 't_alcohol' ||
      _selectedTrigger?.name.toLowerCase() == 'alcohol';

  bool get _isSmoking =>
      _selectedTrigger?.id == 't_smoking' ||
      _selectedTrigger?.name.toLowerCase().contains('smoking') == true ||
      _selectedTrigger?.name.toLowerCase().contains('tobacco') == true;

  bool get _isFood =>
      _selectedTrigger?.id == 't_foods' ||
      _selectedTrigger?.id == 't_spicy_food' ||
      _selectedTrigger?.id == 't_sugar_processed_food' ||
      _selectedTrigger?.id == 't_hot_drinks_food' ||
      _selectedTrigger?.id == 't_skipped_meals';

  bool get _isStress =>
      _selectedTrigger?.id == 't_stress' ||
      _selectedTrigger?.name.toLowerCase() == 'stress';

  bool get _isExercise =>
      _selectedTrigger?.id == 't_exercise' ||
      _selectedTrigger?.name.toLowerCase() == 'exercise';

  String get _foodHint {
    switch (_selectedTrigger?.id) {
      case 't_spicy_food':      return 'What spicy food did you eat?';
      case 't_hot_drinks_food': return 'Hot tea, soup, coffee...';
      case 't_skipped_meals':   return 'Which meal did you skip?';
      case 't_sugar_processed_food': return 'Sweets, soda, processed snacks...';
      default:                  return 'Spicy foods, heavy dinner...';
    }
  }

  /// Build the current saved value string from state, for the onSave callback.
  String get _resolvedValue {
    if (_isCaffeine) return '$_counterValue cup${_counterValue != 1 ? 's' : ''}';
    if (_isAlcohol)  return '$_counterValue glass${_counterValue != 1 ? 'es' : ''}';
    if (_isSmoking)  return '$_counterValue time${_counterValue != 1 ? 's' : ''}';
    if (_isFood)     return _textNote.isNotEmpty ? _textNote : 'Noted';
    if (_isExercise) return _counterValue > 0 ? '$_counterValue min' : 'Logged';
    return _selectedValue ?? 'Moderate';
  }

  bool get _canSave {
    // Food requires something in the note or we allow empty
    return _selectedTrigger != null;
  }

  List<String> _getTriggerValues(String name) {
    switch (name.toLowerCase()) {
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
      case 'travel':
        return ['Short', 'Medium', 'Long'];
      case 'work':
      case 'overworking':
        return ['1-2 hours', '3-4 hours', '5+ hours'];
      default:
        return ['Low', 'Moderate', 'High'];
    }
  }

  void _selectTrigger(TriggerOption trigger) async {
    HapticFeedback.lightImpact();
    final vals = _getTriggerValues(trigger.name);
    final isEx = trigger.id == 't_exercise' || trigger.name.toLowerCase() == 'exercise';
    setState(() {
      _tappingTriggerId = trigger.id;
      _selectedTrigger = trigger;
      _counterValue = isEx ? 0 : 1;
      _textNote = '';
      _selectedValue = vals.isNotEmpty ? vals[vals.length ~/ 2] : 'Moderate';
    });

    // Short micro-delay to let the card scale, fill, and checkmark animate
    await Future.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;

    setState(() {
      _tappingTriggerId = null;
      _currentStep = 1;
    });
  }

  // ─── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(triggerLibraryProvider);
    final loggedNames = widget.loggedTriggers
        .map((t) => t['name']?.toString().toLowerCase())
        .toSet();

    final displayTriggers = library.where((trigger) {
      final matchesLogged = !loggedNames.contains(trigger.name.toLowerCase());
      final matchesSearch = _searchQuery.isEmpty ||
          trigger.name.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;
      if (_searchQuery.isNotEmpty) return matchesLogged;

      final def =
          kTriggerLibrary.where((d) => 't_${d.id}' == trigger.id).firstOrNull;
      if (def == null) return matchesLogged;

      return _showAllTriggers
          ? matchesLogged
          : matchesLogged && def.tier == TriggerTier.core;
    }).toList();

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
                if (_currentStep == 1)
                  IconButton(
                    onPressed: () => setState(() {
                      _currentStep = 0;
                      _selectedTrigger = null;
                    }),
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF2EDEA),
                      foregroundColor: AppTheme.onSurfaceVariant,
                    ),
                  )
                else
                  const SizedBox(width: 40),
                Text(
                  _currentStep == 0 ? 'Add Daily Trigger' : 'Configure Trigger',
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

          // Body
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                final isForward = _currentStep == 1;
                final inOffset = isForward ? const Offset(0.08, 0.0) : const Offset(-0.08, 0.0);
                return FadeTransition(
                  opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: inOffset,
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _currentStep == 0
                  ? KeyedSubtree(
                      key: const ValueKey<int>(0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 8),
                            child: TextField(
                              onChanged: (val) =>
                                  setState(() => _searchQuery = val),
                              decoration: InputDecoration(
                                hintText: 'Search triggers...',
                                prefixIcon: const Icon(Icons.search,
                                    color: Color(0xFF9B8B7E)),
                                filled: true,
                                fillColor: const Color(0xFFF2EDEA)
                                    .withValues(alpha: 0.5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              style: GoogleFonts.manrope(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: _buildTriggerSelection(displayTriggers),
                            ),
                          ),
                        ],
                      ),
                    )
                  : KeyedSubtree(
                      key: const ValueKey<int>(1),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildDetailStep(),
                      ),
                    ),
            ),
          ),

          // Save button (step 1 only)
          if (_currentStep == 1)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _canSave
                      ? () {
                          widget.onSave(
                            _selectedTrigger!.name,
                            _resolvedValue,
                            _selectedTrigger!.getIconData(),
                          );
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppTheme.primary.withValues(alpha: 0.4),
                    disabledForegroundColor:
                        Colors.white.withValues(alpha: 0.6),
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

  // ─── Step 0: trigger grid ─────────────────────────────────────────────────

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
              final icon = trigger.getIconData();
              final trigColor = trigger.getIconColor();
              final trigBg = trigColor.withValues(alpha: 0.1);
              final isSelected = (_selectedTrigger?.id == trigger.id) || (_tappingTriggerId == trigger.id);

              return Bounceable(
                scaleFactor: 0.92,
                duration: const Duration(milliseconds: 140),
                onTap: () => _selectTrigger(trigger),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      decoration: BoxDecoration(
                        color: isSelected ? trigColor.withValues(alpha: 0.12) : Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: isSelected ? trigColor : Colors.transparent,
                          width: isSelected ? 2.5 : 0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? trigColor.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.03),
                            blurRadius: isSelected ? 16 : 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: isSelected ? trigColor.withValues(alpha: 0.28) : trigBg,
                              shape: BoxShape.circle,
                            ),
                            child: AnimatedScale(
                              scale: isSelected ? 1.15 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutBack,
                              child: Icon(icon, color: trigColor, size: 32),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text(
                              trigger.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? const Color(0xFF1D1B1A) : const Color(0xFF9B8B7E),
                                height: 1.15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 10,
                        right: 12,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.elasticOut,
                          builder: (context, val, child) => Transform.scale(
                            scale: val,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: trigColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        if (_searchQuery.isEmpty) ...[
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () =>
                  setState(() => _showAllTriggers = !_showAllTriggers),
              icon: Icon(
                _showAllTriggers
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
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

  // ─── Step 1: trigger detail (matches daily logging UI exactly) ────────────

  Widget _buildDetailStep() {
    if (_selectedTrigger == null) return const SizedBox.shrink();

    final name = _selectedTrigger!.name;
    final icon = _selectedTrigger!.getIconData();
    final trigColor = _selectedTrigger!.getIconColor();
    final trigBg = trigColor.withValues(alpha: 0.1);

    return LoggingCardWrapper(
      name: name,
      icon: icon,
      color: trigColor,
      backgroundColor: trigBg,
      children: [
        if (_isCaffeine)
          QuantityCounterSelector(
            value: _counterValue,
            label: 'HOW MUCH TODAY?',
            onChanged: (val) => setState(() => _counterValue = val),
            displayValueBuilder: (val) => '$val cup${val != 1 ? 's' : ''}',
            minValue: 0,
          )
        else if (_isAlcohol)
          QuantityCounterSelector(
            value: _counterValue,
            label: 'CONSUMPTION LOG',
            onChanged: (val) => setState(() => _counterValue = val),
            displayValueBuilder: (val) =>
                '$val glass${val != 1 ? 'es' : ''}',
            minValue: 0,
          )
        else if (_isSmoking)
          QuantityCounterSelector(
            value: _counterValue,
            label: 'HOW MUCH TODAY?',
            onChanged: (val) => setState(() => _counterValue = val),
            displayValueBuilder: (val) =>
                '$val time${val != 1 ? 's' : ''}',
            minValue: 0,
          )
        else if (_isFood) ...[
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _textNote,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              hintText: _foodHint,
            ),
            style: GoogleFonts.manrope(fontSize: 13),
            maxLines: 2,
            onChanged: (val) => setState(() => _textNote = val),
          ),
        ] else if (_isStress)
          GradientSliderSelector(
            values: const ['Calm', 'Moderate', 'High'],
            currentValue: _selectedValue ?? 'Moderate',
            onChanged: (val) => setState(() => _selectedValue = val),
            label: 'INTENSITY LEVEL',
            emojiGetter: (val) => _getEmojiForValue(name, val),
          )
        else if (_isExercise) ...[
          GradientSliderSelector(
            values: const ['Light', 'Moderate', 'Intense'],
            currentValue: _selectedValue ?? 'Moderate',
            onChanged: (val) => setState(() => _selectedValue = val),
            label: 'INTENSITY',
            emojiGetter: (val) => _getEmojiForValue(name, val),
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF7F5F0), height: 1),
          QuantityCounterSelector(
            value: _counterValue,
            label: 'DURATION',
            onChanged: (val) => setState(() => _counterValue = val),
            displayValueBuilder: (val) => val > 0 ? '$val min' : 'Not set',
            stepValue: 5,
            minValue: 0,
            maxValue: 240,
          ),
        ] else
          GradientSliderSelector(
            values: _getTriggerValues(name),
            currentValue: _selectedValue ??
                (_getTriggerValues(name).isNotEmpty
                    ? _getTriggerValues(name)[
                        _getTriggerValues(name).length ~/ 2]
                    : 'Moderate'),
            onChanged: (val) => setState(() => _selectedValue = val),
            label: 'TRIGGER LEVEL / QUANTITY',
            emojiGetter: (val) => _getEmojiForValue(name, val),
          ),
      ],
    );
  }

  // ─── emoji helper ─────────────────────────────────────────────────────────

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
      case 'low':
        return '😊';
      case 'moderate': return '😐';
      case 'high':
      case 'severe':
      case 'intense': return '😟';
      case 'light':   return '🚶';
      case 'sunny':   return '☀️';
      case 'humid':   return '☁️';
      case 'cold/change': return '❄️';
      case 'short':   return '🚗';
      case 'medium':  return '✈️';
      case 'long':    return '🌍';
      case '1-2 hours': return '⌚';
      case '3-4 hours': return '⏰';
      case '5+ hours':  return '⏳';
      default:        return '✨';
    }
  }
}
