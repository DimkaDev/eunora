import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';

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

                        if (isCaffeine) {
                          final cups = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
                          return _buildCaffeineDetailCard(index, name, cups);
                        } else if (isAlcohol) {
                          final glasses = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
                          return _buildAlcoholDetailCard(index, name, glasses);
                        } else if (isStress) {
                          final currentLevel = value.replaceAll('Level: ', '').trim();
                          return _buildStressDetailCard(index, name, currentLevel);
                        } else {
                          return _buildOtherTriggerDetailCard(index, name, value, icon);
                        }
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

  Widget _buildCaffeineDetailCard(int index, String name, int caffeineCups) {
    final trigColor = _getTriggerColor(name);
    final trigBg = trigColor.withValues(alpha: 0.1);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: trigBg, shape: BoxShape.circle),
                    child: const Icon(Icons.coffee, color: Color(0xFF9D675C), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    name,
                    style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _deleteTrigger(name),
                icon: const Icon(Icons.delete_outline),
                color: AppTheme.error,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
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
                    if (caffeineCups > 1) {
                      _updateCaffeineCups(index, caffeineCups - 1);
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
                  '$caffeineCups cup${caffeineCups != 1 ? 's' : ''}',
                  style: GoogleFonts.notoSerif(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
                GestureDetector(
                  onTap: () => _updateCaffeineCups(index, caffeineCups + 1),
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
      ),
    );
  }

  Widget _buildAlcoholDetailCard(int index, String name, int alcoholGlasses) {
    final trigColor = _getTriggerColor(name);
    final trigBg = trigColor.withValues(alpha: 0.1);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: trigBg, shape: BoxShape.circle),
                    child: const Icon(Icons.local_bar, color: Color(0xFF9D675C), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    name,
                    style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _deleteTrigger(name),
                icon: const Icon(Icons.delete_outline),
                color: AppTheme.error,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
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
                    if (alcoholGlasses > 1) {
                      _updateAlcoholGlasses(index, alcoholGlasses - 1);
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
                  '$alcoholGlasses glass${alcoholGlasses != 1 ? 'es' : ''}',
                  style: GoogleFonts.notoSerif(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
                GestureDetector(
                  onTap: () => _updateAlcoholGlasses(index, alcoholGlasses + 1),
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
      ),
    );
  }

  Widget _buildStressDetailCard(int index, String name, String stressLevel) {
    final trigColor = _getTriggerColor(name);
    final trigBg = trigColor.withValues(alpha: 0.1);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: trigBg, shape: BoxShape.circle),
                    child: const Icon(Icons.psychology, color: Color(0xFF9D675C), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    name,
                    style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _deleteTrigger(name),
                icon: const Icon(Icons.delete_outline),
                color: AppTheme.error,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
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
                  Color(0xFFE2F5E2), // Soft Green (Calm)
                  Color(0xFFFFF1D0), // Soft Yellow/Orange (Moderate)
                  Color(0xFFFFE0E0), // Soft Red (High)
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
                // Three Buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _updateStressLevel(index, 'Calm'),
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
                        onTap: () => _updateStressLevel(index, 'Moderate'),
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
                        onTap: () => _updateStressLevel(index, 'High'),
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
      ),
    );
  }

  Widget _buildOtherTriggerDetailCard(int index, String name, String value, IconData icon) {
    final trigColor = _getTriggerColor(name);
    final trigBg = trigColor.withValues(alpha: 0.1);
    final values = _getTriggerValues(name);
    final isSelectedValue = values.contains(value) ? value : values[values.length ~/ 2];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              IconButton(
                onPressed: () => _deleteTrigger(name),
                icon: const Icon(Icons.delete_outline),
                color: AppTheme.error,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
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
                        onTap: () => _updateOtherValue(index, val),
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
