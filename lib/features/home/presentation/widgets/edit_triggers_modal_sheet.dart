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
                  'Log Your Triggers',
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
            'Adjust quantity or remove triggers',
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.notoSerif(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'HOW MUCH TODAY?',
                    style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.coffee, color: Color(0xFF9D675C)),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _deleteTrigger(name),
                    icon: const Icon(Icons.delete_outline),
                    color: AppTheme.error,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                    if (caffeineCups > 0) {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.notoSerif(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'CONSUMPTION LOG',
                    style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.local_bar, color: Color(0xFF9D675C)),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _deleteTrigger(name),
                    icon: const Icon(Icons.delete_outline),
                    color: AppTheme.error,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                    if (alcoholGlasses > 0) {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.notoSerif(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'INTENSITY LEVEL',
                    style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.psychology, color: Color(0xFF9D675C)),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _deleteTrigger(name),
                    icon: const Icon(Icons.delete_outline),
                    color: AppTheme.error,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
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
              Text(
                name,
                style: GoogleFonts.notoSerif(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
              ),
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF9D675C)),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _deleteTrigger(name),
                    icon: const Icon(Icons.delete_outline),
                    color: AppTheme.error,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: value,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFFAF9F6),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              hintText: 'Add any details (e.g. Sunny, 30 mins, spicy lunch)...',
            ),
            style: GoogleFonts.manrope(fontSize: 13),
            onChanged: (val) => _updateOtherValue(index, val),
          ),
        ],
      ),
    );
  }
}
