import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';

class CalendarTriggerEntry {
  String name;
  String value;
  IconData icon;

  CalendarTriggerEntry({
    required this.name,
    required this.value,
    required this.icon,
  });

  CalendarTriggerEntry copy() =>
      CalendarTriggerEntry(name: name, value: value, icon: icon);

  String toDisplayString() => name;
}

class CalendarTriggerEditSheet extends StatefulWidget {
  final List<String> initialTriggers;
  final void Function(List<String> updated) onSave;

  const CalendarTriggerEditSheet({
    super.key,
    required this.initialTriggers,
    required this.onSave,
  });

  @override
  State<CalendarTriggerEditSheet> createState() => _CalendarTriggerEditSheetState();
}

class _CalendarTriggerEditSheetState extends State<CalendarTriggerEditSheet> {
  late List<CalendarTriggerEntry> _entries;

  // Master trigger type catalog (used both to populate logged entries and add-more chips)
  final Map<String, Map<String, dynamic>> _triggerCatalog = {
    'Caffeine': {'icon': Icons.local_cafe, 'defaultValue': '1 cup', 'type': 'counter', 'unit': 'cup'},
    'Stress': {'icon': Icons.psychology, 'defaultValue': 'Level: Moderate', 'type': 'stress'},
    'Alcohol': {'icon': Icons.wine_bar, 'defaultValue': '1 glass', 'type': 'counter', 'unit': 'glass'},
    'Red wine': {'icon': Icons.wine_bar, 'defaultValue': '1 glass', 'type': 'counter', 'unit': 'glass'},
    'Exercise': {'icon': Icons.fitness_center, 'defaultValue': 'Logged', 'type': 'simple'},
    'Weather': {'icon': Icons.cloud, 'defaultValue': 'Logged', 'type': 'simple'},
    'Poor sleep': {'icon': Icons.bedtime, 'defaultValue': 'Logged', 'type': 'simple'},
    'Poor Sleep': {'icon': Icons.bedtime, 'defaultValue': 'Logged', 'type': 'simple'},
    'Specific Foods': {'icon': Icons.restaurant, 'defaultValue': 'Logged', 'type': 'simple'},
  };

  final List<Map<String, dynamic>> _quickAddOptions = [
    {'name': 'Exercise', 'icon': Icons.fitness_center},
    {'name': 'Weather', 'icon': Icons.cloud},
    {'name': 'Poor Sleep', 'icon': Icons.bedtime},
    {'name': 'Specific Foods', 'icon': Icons.restaurant},
  ];

  @override
  void initState() {
    super.initState();
    _entries = widget.initialTriggers.map((name) {
      final catalogEntry = _triggerCatalog[name];
      return CalendarTriggerEntry(
        name: name,
        value: catalogEntry?['defaultValue'] as String? ?? 'Logged',
        icon: catalogEntry?['icon'] as IconData? ?? Icons.bolt,
      );
    }).toList();
  }

  String _getType(String name) {
    return _triggerCatalog[name]?['type'] as String? ?? 'simple';
  }

  String _getUnit(String name) {
    return _triggerCatalog[name]?['unit'] as String? ?? 'unit';
  }

  void _deleteTrigger(int index) {
    setState(() => _entries.removeAt(index));
  }

  void _addQuickTrigger(String name, IconData icon) {
    if (_entries.any((e) => e.name.toLowerCase() == name.toLowerCase())) return;
    final catalogEntry = _triggerCatalog[name];
    setState(() {
      _entries.add(CalendarTriggerEntry(
        name: name,
        value: catalogEntry?['defaultValue'] as String? ?? 'Logged',
        icon: icon,
      ));
    });
  }

  void _incrementCount(int index) {
    final entry = _entries[index];
    final unit = _getUnit(entry.name);
    final count = int.tryParse(entry.value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    final newCount = count + 1;
    setState(() {
      entry.value = '$newCount $unit${newCount > 1 ? 's' : ''}';
    });
  }

  void _decrementCount(int index) {
    final entry = _entries[index];
    final unit = _getUnit(entry.name);
    final count = int.tryParse(entry.value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    if (count <= 1) return;
    final newCount = count - 1;
    setState(() {
      entry.value = '$newCount $unit${newCount > 1 ? 's' : ''}';
    });
  }

  void _setStressLevel(int index, String level) {
    setState(() {
      _entries[index].value = 'Level: $level';
    });
  }

  void _showAddCustomDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFEF8F6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Add Custom Trigger',
          style: GoogleFonts.notoSerif(
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.manrope(),
          decoration: InputDecoration(
            hintText: 'e.g. Late night snack, Spicy food',
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL',
                style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold, color: AppTheme.outline)),
          ),
          TextButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                setState(() {
                  _entries.add(CalendarTriggerEntry(
                    name: val,
                    value: 'Logged',
                    icon: Icons.add_circle_outline,
                  ));
                });
              }
              Navigator.pop(ctx);
            },
            child: Text('ADD',
                style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold, color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  void _save() {
    widget.onSave(_entries.map((e) => e.name).toList());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Which quick-add options are not yet in the list
    final available = _quickAddOptions
        .where((o) => !_entries
            .any((e) => e.name.toLowerCase() == (o['name'] as String).toLowerCase()))
        .toList();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFEF8F6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFD0C4BC).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),

          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const SizedBox(width: 40), // spacer
                Expanded(
                  child: Text(
                    'Log Your Triggers',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSerif(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1D1B1A),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[100],
                    ),
                    child: const Icon(Icons.close, color: Color(0xFFB0A89E), size: 20),
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
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LOGGED TODAY section
                  _buildSectionHeader('LOGGED TODAY'),
                  const SizedBox(height: 12),

                  if (_entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'No triggers logged for this day.',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFFB0A89E),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._entries.asMap().entries.map((e) {
                      final idx = e.key;
                      final entry = e.value;
                      final type = _getType(entry.name);

                      if (type == 'counter') {
                        return _buildCounterCard(idx, entry);
                      } else if (type == 'stress') {
                        return _buildStressCard(idx, entry);
                      } else {
                        return _buildSimpleCard(idx, entry);
                      }
                    }),

                  const SizedBox(height: 28),

                  // ADD TRIGGERS section
                  _buildSectionHeader('ADD TRIGGERS'),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...available.map((o) {
                        final name = o['name'] as String;
                        final icon = o['icon'] as IconData;
                        return _buildQuickAddChip(name, icon);
                      }),
                      _buildAddCustomChip(),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Footer Done button
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFFEF8F6).withValues(alpha: 0),
                  const Color(0xFFFEF8F6),
                ],
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 6,
                    shadowColor: AppTheme.primary.withValues(alpha: 0.25),
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider(color: Color(0xFFEAE6E0))),
      ],
    );
  }

  Widget _buildCounterCard(int index, CalendarTriggerEntry entry) {
    final count = int.tryParse(entry.value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE6E0)),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 8)],
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
            child: Icon(entry.icon, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name,
                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                Text(entry.value,
                    style: GoogleFonts.manrope(
                        fontSize: 13, color: AppTheme.onSurfaceVariant)),
              ],
            ),
          ),
          // Counter control
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF2EDEA),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _counterBtn(Icons.remove, () => _decrementCount(index)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '$count',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                  ),
                ),
                _counterBtn(Icons.add, () => _incrementCount(index)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _deleteTrigger(index),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.delete_outline,
                  size: 22, color: const Color(0xFFB0A89E)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: AppTheme.primary),
      ),
    );
  }

  Widget _buildStressCard(int index, CalendarTriggerEntry entry) {
    final currentLevel = entry.value.replaceFirst('Level: ', '').trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE6E0)),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 8)],
      ),
      child: Column(
        children: [
          // Top row: icon + name + delete
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDDDF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(entry.icon, color: const Color(0xFF655A6E)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.name,
                        style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                    Text(entry.value,
                        style: GoogleFonts.manrope(
                            fontSize: 13, color: AppTheme.onSurfaceVariant)),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _deleteTrigger(index),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline,
                      size: 22, color: const Color(0xFFB0A89E)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stress level selector
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F2F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: ['Calm', 'Moderate', 'High'].map((lvl) {
                final isSelected = currentLevel == lvl;
                IconData lvlIcon = Icons.sentiment_satisfied;
                if (lvl == 'Moderate') lvlIcon = Icons.sentiment_neutral;
                if (lvl == 'High') lvlIcon = Icons.sentiment_dissatisfied;

                return Expanded(
                  child: InkWell(
                    onTap: () => _setStressLevel(index, lvl),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFEDDDF5)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: const Color(0xFFD0C1D8))
                            : Border.all(color: Colors.transparent),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            lvlIcon,
                            size: 22,
                            color: isSelected
                                ? const Color(0xFF211828)
                                : AppTheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lvl.toUpperCase(),
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? const Color(0xFF211828)
                                  : AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleCard(int index, CalendarTriggerEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE6E0)),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 8)],
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
            child: Icon(entry.icon, color: AppTheme.outline),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name,
                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                Text(entry.value,
                    style: GoogleFonts.manrope(
                        fontSize: 13, color: AppTheme.onSurfaceVariant)),
              ],
            ),
          ),
          InkWell(
            onTap: () => _deleteTrigger(index),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.delete_outline,
                  size: 22, color: const Color(0xFFB0A89E)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddChip(String name, IconData icon) {
    return InkWell(
      onTap: () => _addQuickTrigger(name, icon),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2EDEA),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(name,
                style: GoogleFonts.manrope(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCustomChip() {
    return InkWell(
      onTap: _showAddCustomDialog,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_circle_outline,
                size: 18, color: AppTheme.primary),
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
    );
  }
}
