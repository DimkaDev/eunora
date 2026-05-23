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

  final List<Map<String, dynamic>> _allTriggerTypes = [
    {'name': 'Caffeine', 'icon': Icons.local_cafe, 'defaultValue': '1 cup'},
    {'name': 'Stress', 'icon': Icons.psychology, 'defaultValue': 'Level: Moderate'},
    {'name': 'Alcohol', 'icon': Icons.wine_bar, 'defaultValue': '1 glass'},
    {'name': 'Exercise', 'icon': Icons.fitness_center, 'defaultValue': '30 mins'},
    {'name': 'Weather', 'icon': Icons.cloud, 'defaultValue': 'Sunny'},
    {'name': 'Poor Sleep', 'icon': Icons.bedtime, 'defaultValue': 'Yes'},
    {'name': 'Specific Foods', 'icon': Icons.restaurant, 'defaultValue': 'Spicy food'},
  ];

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

  void _addTrigger(Map<String, dynamic> type) {
    // Check if already logged
    final exists = _draftTriggers.any((t) => t['name'].toLowerCase() == type['name'].toLowerCase());
    if (!exists) {
      setState(() {
        _draftTriggers.add({
          'name': type['name'],
          'value': type['defaultValue'],
          'icon': type['icon'],
        });
      });
    }
  }

  void _incrementCount(int index, String unit) {
    final trigger = _draftTriggers[index];
    final String value = trigger['value'] ?? '1';
    int count = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    setState(() {
      count++;
      _draftTriggers[index]['value'] = '$count $unit${count > 1 ? 's' : ''}';
    });
  }

  void _decrementCount(int index, String unit) {
    final trigger = _draftTriggers[index];
    final String value = trigger['value'] ?? '1';
    int count = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    if (count > 1) {
      setState(() {
        count--;
        _draftTriggers[index]['value'] = '$count $unit${count > 1 ? 's' : ''}';
      });
    }
  }

  void _updateStressLevel(int index, String level) {
    setState(() {
      _draftTriggers[index]['value'] = 'Level: $level';
    });
  }

  void _showAddCustomDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Add Custom Trigger',
          style: GoogleFonts.notoSerif(
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. Spicy lunch, Flight travel',
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primary),
            ),
          ),
          style: GoogleFonts.manrope(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                color: AppTheme.outline,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final val = textController.text.trim();
              if (val.isNotEmpty) {
                setState(() {
                  _draftTriggers.add({
                    'name': val,
                    'value': 'Logged',
                    'icon': Icons.add_circle_outline,
                  });
                });
              }
              Navigator.pop(context);
            },
            child: Text(
              'ADD',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine which trigger types are not yet logged
    final unloggedTypes = _allTriggerTypes.where((type) {
      return !_draftTriggers.any((t) => t['name'].toLowerCase() == type['name'].toLowerCase());
    }).toList();

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
                  // Section 1: Logged Today
                  Row(
                    children: [
                      Text(
                        'LOGGED TODAY',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(child: Divider(color: Color(0xFFE7E1DF))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_draftTriggers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
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

                        if (isCaffeine || isAlcohol) {
                          final unit = isCaffeine ? 'cup' : 'glass';
                          final count = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
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
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2DFD0),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(icon, color: AppTheme.primary),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: GoogleFonts.manrope(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        value,
                                        style: GoogleFonts.manrope(
                                          fontSize: 13,
                                          color: AppTheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Quantity Selector
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2EDEA),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      InkWell(
                                        onTap: () => _decrementCount(index, unit),
                                        child: const CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Colors.white,
                                          child: Icon(Icons.remove, size: 14, color: AppTheme.primary),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: Text(
                                          '$count',
                                          style: GoogleFonts.manrope(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _incrementCount(index, unit),
                                        child: const CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Colors.white,
                                          child: Icon(Icons.add, size: 14, color: AppTheme.primary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _deleteTrigger(name),
                                  icon: const Icon(Icons.delete_outline),
                                  color: AppTheme.outline,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          );
                        } else if (isStress) {
                          final currentLevel = value.replaceAll('Level: ', '').trim();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
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
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEDDDF5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(icon, color: const Color(0xFF655A6E)),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: GoogleFonts.manrope(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            value,
                                            style: GoogleFonts.manrope(
                                              fontSize: 13,
                                              color: AppTheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _deleteTrigger(name),
                                      icon: const Icon(Icons.delete_outline),
                                      color: AppTheme.outline,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Stress Level Selector
                                Row(
                                  children: ['Calm', 'Moderate', 'High'].map((lvl) {
                                    final isLvlSelected = currentLevel == lvl;
                                    IconData lvlIcon = Icons.sentiment_satisfied;
                                    if (lvl == 'Moderate') lvlIcon = Icons.sentiment_neutral;
                                    if (lvl == 'High') lvlIcon = Icons.sentiment_dissatisfied;

                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: InkWell(
                                          onTap: () => _updateStressLevel(index, lvl),
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            decoration: BoxDecoration(
                                              color: isLvlSelected
                                                  ? const Color(0xFFEDDDF5)
                                                  : const Color(0xFFF8F2F0),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isLvlSelected
                                                    ? const Color(0xFFD0C1D8)
                                                    : Colors.transparent,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Icon(
                                                  lvlIcon,
                                                  color: isLvlSelected
                                                      ? const Color(0xFF211828)
                                                      : AppTheme.onSurfaceVariant,
                                                  size: 20,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  lvl.toUpperCase(),
                                                  style: GoogleFonts.manrope(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isLvlSelected
                                                        ? const Color(0xFF211828)
                                                        : AppTheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
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
                        } else {
                          // Default Card (Exercise, weather, poor sleep, specific foods, custom)
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
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
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2EDEA),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(icon, color: AppTheme.outline),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: GoogleFonts.manrope(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        value,
                                        style: GoogleFonts.manrope(
                                          fontSize: 13,
                                          color: AppTheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _deleteTrigger(name),
                                  icon: const Icon(Icons.delete_outline),
                                  color: AppTheme.outline,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          );
                        }
                      }),
                    ),
                  const SizedBox(height: 24),

                  // Section 2: Add Triggers
                  Row(
                    children: [
                      Text(
                        'ADD TRIGGERS',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(child: Divider(color: Color(0xFFE7E1DF))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Chip Layout for unlogged triggers
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...unloggedTypes.map((type) {
                        final String name = type['name'] ?? '';
                        final IconData icon = type['icon'] ?? Icons.bolt;

                        return InkWell(
                          onTap: () => _addTrigger(type),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2EDEA),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 18, color: AppTheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  name,
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      // Add Custom Option
                      InkWell(
                        onTap: _showAddCustomDialog,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.outlineVariant.withValues(alpha: 0.8),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_circle_outline, size: 18, color: AppTheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Add custom',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
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
                  'Done',
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
