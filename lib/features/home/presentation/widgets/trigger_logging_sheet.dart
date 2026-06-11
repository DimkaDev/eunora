import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/utils/animation_system.dart';
import 'package:eunora/features/onboarding/domain/models/trigger.dart';
import 'package:eunora/features/onboarding/presentation/providers/triggers_provider.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: trigColor.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: isCaffeine
              ? _buildCaffeineSelector(name, icon, trigColor, trigBg)
              : isAlcohol
                  ? _buildAlcoholSelector(name, icon, trigColor, trigBg)
                  : isStress
                      ? _buildStressSelector(name, icon, trigColor, trigBg)
                      : _buildOtherSelector(name, icon, trigColor, trigBg),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCaffeineSelector(String name, IconData icon, Color trigColor, Color trigBg) {
    int cups = int.tryParse((_selectedValue ?? '1').replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: trigBg, shape: BoxShape.circle),
              child: Icon(icon, color: trigColor, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              name,
              style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'HOW MUCH TODAY?',
          style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF8A817C), letterSpacing: 1.5),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F5F0).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  if (cups > 1) {
                    setState(() {
                      _selectedValue = '${cups - 1} cup${cups - 1 != 1 ? 's' : ''}';
                    });
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.remove, color: AppTheme.primary),
                ),
              ),
              Text(
                '$cups cup${cups != 1 ? 's' : ''}',
                style: GoogleFonts.notoSerif(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedValue = '${cups + 1} cup${cups + 1 != 1 ? 's' : ''}';
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: AppTheme.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlcoholSelector(String name, IconData icon, Color trigColor, Color trigBg) {
    int glasses = int.tryParse((_selectedValue ?? '1').replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: trigBg, shape: BoxShape.circle),
              child: Icon(icon, color: trigColor, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              name,
              style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'CONSUMPTION LOG',
          style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF8A817C), letterSpacing: 1.5),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F5F0).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  if (glasses > 1) {
                    setState(() {
                      _selectedValue = '${glasses - 1} glass${glasses - 1 != 1 ? 'es' : ''}';
                    });
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.remove, color: AppTheme.primary),
                ),
              ),
              Text(
                '$glasses glass${glasses != 1 ? 'es' : ''}',
                style: GoogleFonts.notoSerif(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedValue = '${glasses + 1} glass${glasses + 1 != 1 ? 'es' : ''}';
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: AppTheme.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStressSelector(String name, IconData icon, Color trigColor, Color trigBg) {
    final stressLevel = _selectedValue ?? 'Moderate';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: trigBg, shape: BoxShape.circle),
              child: Icon(icon, color: trigColor, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              name,
              style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'INTENSITY LEVEL',
          style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF8A817C), letterSpacing: 1.5),
        ),
        const SizedBox(height: 16),
        Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFE2F5E2),
                Color(0xFFFFF1D0),
                Color(0xFFFFE0E0),
              ],
            ),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: stressLevel == 'Calm'
                    ? Alignment.centerLeft
                    : stressLevel == 'Moderate'
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
                      onTap: () {
                        setState(() {
                          _selectedValue = 'Calm';
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('😊', style: TextStyle(fontSize: 18)),
                            const SizedBox(height: 2),
                            Text(
                              'Calm',
                              style: GoogleFonts.manrope(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: stressLevel == 'Calm' ? AppTheme.primary : const Color(0xFF8A817C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedValue = 'Moderate';
                        });
                      },
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
                                color: stressLevel == 'Moderate' ? AppTheme.primary : const Color(0xFF8A817C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedValue = 'High';
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('😟', style: TextStyle(fontSize: 18)),
                            const SizedBox(height: 2),
                            Text(
                              'High',
                              style: GoogleFonts.manrope(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: stressLevel == 'High' ? AppTheme.primary : const Color(0xFF8A817C),
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
    );
  }

  Widget _buildOtherSelector(String name, IconData icon, Color trigColor, Color trigBg) {
    final values = _getTriggerValues(name);
    final isSelectedValue = values.contains(_selectedValue) ? _selectedValue : values[values.length ~/ 2];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: trigBg, shape: BoxShape.circle),
              child: Icon(icon, color: trigColor, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              name,
              style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'TRIGGER LEVEL / QUANTITY',
          style: GoogleFonts.manrope(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: const Color(0xFF8A817C),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFE2F5E2),
                Color(0xFFFFF1D0),
                Color(0xFFFFE0E0),
              ],
            ),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Stack(
            children: [
              // White sliding thumb selector
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: isSelectedValue == values[0]
                    ? Alignment.centerLeft
                    : isSelectedValue == values[1]
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
                children: values.map((val) {
                  final isSelected = isSelectedValue == val;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedValue = val;
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_getEmojiForValue(name, val), style: const TextStyle(fontSize: 18)),
                            const SizedBox(height: 2),
                            Text(
                              val,
                              style: GoogleFonts.manrope(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppTheme.primary : const Color(0xFF8A817C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
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
