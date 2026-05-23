import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


/// A symptom model for the calendar edit sheet.
class CalendarSymptomEntry {
  String name;
  String severity; // 'Mild' | 'Moderate' | 'Severe'
  int durationMinutes;

  CalendarSymptomEntry({
    required this.name,
    required this.severity,
    this.durationMinutes = 30,
  });

  CalendarSymptomEntry copy() => CalendarSymptomEntry(
        name: name,
        severity: severity,
        durationMinutes: durationMinutes,
      );

  /// Parse from a string like 'Hot flashes · 4/5'
  static CalendarSymptomEntry fromDisplayString(String s) {
    final parts = s.split(' · ');
    final name = parts.first.trim();
    String severity = 'Moderate';
    if (parts.length > 1) {
      final scoreStr = parts[1].split('/').first.trim();
      final score = int.tryParse(scoreStr) ?? 3;
      if (score <= 2) {
        severity = 'Mild';
      } else if (score <= 3) {
        severity = 'Moderate';
      } else {
        severity = 'Severe';
      }
    }
    return CalendarSymptomEntry(name: name, severity: severity);
  }

  /// Convert back to a display string like 'Hot flashes · 4/5'
  String toDisplayString() {
    int score;
    if (severity == 'Mild') {
      score = 1;
    } else if (severity == 'Moderate') {
      score = 3;
    } else {
      score = 5;
    }
    return '$name · $score/5';
  }
}

class CalendarSymptomEditSheet extends StatefulWidget {
  final List<String> initialSymptoms;
  final void Function(List<String> updatedSymptoms) onSave;

  const CalendarSymptomEditSheet({
    super.key,
    required this.initialSymptoms,
    required this.onSave,
  });

  @override
  State<CalendarSymptomEditSheet> createState() => _CalendarSymptomEditSheetState();
}

class _CalendarSymptomEditSheetState extends State<CalendarSymptomEditSheet> {
  late List<CalendarSymptomEntry> _entries;

  final List<Map<String, dynamic>> _suggestedSymptoms = [
    {'name': 'Chills', 'icon': Icons.thermostat},
    {'name': 'Irritable', 'icon': Icons.sentiment_dissatisfied},
    {'name': 'Insomnia', 'icon': Icons.bedtime},
    {'name': 'Brain Fog', 'icon': Icons.psychology},
    {'name': 'Joint Pain', 'icon': Icons.bolt},
  ];

  @override
  void initState() {
    super.initState();
    _entries = widget.initialSymptoms
        .map(CalendarSymptomEntry.fromDisplayString)
        .toList();
  }

  void _setSeverity(int index, String severity) {
    setState(() {
      _entries[index].severity = severity;
    });
  }

  void _adjustDuration(int index, int delta) {
    setState(() {
      final newVal = _entries[index].durationMinutes + delta;
      if (newVal >= 5) _entries[index].durationMinutes = newVal;
    });
  }

  void _deleteEntry(int index) {
    setState(() {
      _entries.removeAt(index);
    });
  }

  void _addSuggestion(String name) {
    // Avoid duplicates
    if (_entries.any((e) => e.name.toLowerCase() == name.toLowerCase())) return;
    setState(() {
      _entries.add(CalendarSymptomEntry(name: name, severity: 'Moderate'));
    });
  }

  void _save() {
    final updated = _entries.map((e) => e.toDisplayString()).toList();
    widget.onSave(updated);
    Navigator.pop(context);
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    if (rem == 0) return '${hours}h';
    return '${hours}h ${rem}m';
  }

  @override
  Widget build(BuildContext context) {
    // Which suggested symptoms are not yet in the list
    final available = _suggestedSymptoms
        .where((s) => !_entries.any(
              (e) => e.name.toLowerCase() == (s['name'] as String).toLowerCase(),
            ))
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
              color: const Color(0xFFD8C9E0).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),

          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Log Your Symptoms',
                        style: GoogleFonts.notoSerif(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3A3A3A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Adjust intensity, duration or remove',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: const Color(0xFF7A7068),
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[100],
                      ),
                      child: const Icon(Icons.close, color: Color(0xFFB0A89E), size: 22),
                    ),
                  ),
                ),
              ],
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
                  // --- LOGGED TODAY section ---
                  Text(
                    'LOGGED TODAY',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF9B8B7E),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_entries.isEmpty)
                    _buildEmptyLogged()
                  else
                    ..._entries.asMap().entries.map((entry) {
                      return _buildSymptomCard(entry.key, entry.value);
                    }),

                  const SizedBox(height: 28),

                  // --- ADD SYMPTOMS section ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ADD SYMPTOMS',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF9B8B7E),
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'Tap to add to today',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: const Color(0xFFB0A89E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.9,
                    children: [
                      ...available.map((s) {
                        final name = s['name'] as String;
                        final icon = s['icon'] as IconData;
                        return _buildAddSymptomTile(name, icon);
                      }),
                      _buildViewMoreTile(),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Done button
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF2F0EE))),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9B8B7E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFF9B8B7E).withValues(alpha: 0.3),
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
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

  Widget _buildEmptyLogged() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          'No symptoms logged for this day.',
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: const Color(0xFFB0A89E),
          ),
        ),
      ),
    );
  }

  Widget _buildSymptomCard(int index, CalendarSymptomEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE6E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row: name + severity selector + delete
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Expand/collapse icon (cosmetic chevron to match design)
                Icon(
                  Icons.expand_more,
                  size: 20,
                  color: const Color(0xFF9B8B7E),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.name,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3A3A),
                    ),
                  ),
                ),
                // Severity icon selector
                _buildSeveritySelector(index, entry.severity),
                const SizedBox(width: 8),
                Container(width: 1, height: 24, color: const Color(0xFFEAE6E0)),
                const SizedBox(width: 8),
                // Delete button
                InkWell(
                  onTap: () => _deleteEntry(index),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outlined,
                      size: 20,
                      color: const Color(0xFFB0A89E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Duration row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFBF9F7),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border(top: BorderSide(color: Color(0xFFEAE6E0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DURATION',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF9B8B7E),
                    letterSpacing: 1.0,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFEAE6E0)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _adjustDuration(index, -5),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F5F0),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.remove, size: 16, color: Color(0xFF6B5878)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatDuration(entry.durationMinutes),
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3A3A3A),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () => _adjustDuration(index, 5),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F5F0),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.add, size: 16, color: Color(0xFF6B5878)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeveritySelector(int index, String currentSeverity) {
    final levels = [
      {'key': 'Mild', 'icon': Icons.sentiment_satisfied_outlined},
      {'key': 'Moderate', 'icon': Icons.sentiment_neutral_outlined},
      {'key': 'Severe', 'icon': Icons.sentiment_dissatisfied_outlined},
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5F0),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: levels.map((l) {
          final key = l['key'] as String;
          final icon = l['icon'] as IconData;
          final isSelected = currentSeverity == key;
          return InkWell(
            onTap: () => _setSeverity(index, key),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6B5878) : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [const BoxShadow(color: Color(0x226B5878), blurRadius: 6, offset: Offset(0, 2))]
                    : null,
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? Colors.white : const Color(0xFF9B8B7E),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAddSymptomTile(String name, IconData icon) {
    return InkWell(
      onTap: () => _addSuggestion(name),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEAE6E0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFF7F5F0),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF6B5878), size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A3A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewMoreTile() {
    return InkWell(
      onTap: () {}, // Could navigate to symptom library
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F5F0).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFD8C9E0),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD8C9E0)),
              ),
              child: const Icon(Icons.add, color: Color(0xFF9B8B7E), size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'View More',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: const Color(0xFF9B8B7E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
