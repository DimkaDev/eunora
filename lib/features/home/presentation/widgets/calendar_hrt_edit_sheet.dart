import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';

/// A mutable copy of an HRT entry for editing within the sheet.
class HrtEditEntry {
  String name;
  String details;
  String status;
  bool isTaken;
  String dose;
  String unit; // 'mcg' | 'mg' | 'pump'
  String applicationType; // e.g. 'Patch' | 'Tablet' | 'Gel'
  String timeTaken; // e.g. '08:30'

  HrtEditEntry({
    required this.name,
    required this.details,
    required this.status,
    required this.isTaken,
    required this.dose,
    required this.unit,
    required this.applicationType,
    required this.timeTaken,
  });

  /// Parse from the `Map<String, String>` format used in MockDailyLog.
  factory HrtEditEntry.fromMap(Map<String, String> map) {
    final isTaken = map['isTaken'] == 'true';
    final details = map['details'] ?? '';
    // Parse dose and unit from details like '50 mcg · Patch'
    final detailParts = details.split('·');
    String dose = '50';
    String unit = 'mcg';
    String applicationType = 'Patch';
    if (detailParts.isNotEmpty) {
      final doseStr = detailParts.first.trim();
      final doseMatch = RegExp(r'(\d+)\s*(\w+)').firstMatch(doseStr);
      if (doseMatch != null) {
        dose = doseMatch.group(1) ?? '50';
        unit = doseMatch.group(2) ?? 'mcg';
      }
    }
    if (detailParts.length > 1) {
      applicationType = detailParts[1].trim();
    }

    // Parse time from status like 'Taken 08:30'
    String timeTaken = '08:00';
    final statusStr = map['status'] ?? '';
    final timeMatch = RegExp(r'(\d{1,2}:\d{2})').firstMatch(statusStr);
    if (timeMatch != null) {
      timeTaken = timeMatch.group(1) ?? '08:00';
    }

    return HrtEditEntry(
      name: map['name'] ?? '',
      details: details,
      status: statusStr,
      isTaken: isTaken,
      dose: dose,
      unit: unit,
      applicationType: applicationType,
      timeTaken: timeTaken,
    );
  }

  Map<String, String> toMap() {
    return {
      'name': name,
      'details': '$dose $unit · $applicationType',
      'status': isTaken ? 'Taken $timeTaken' : 'Not taken',
      'isTaken': isTaken.toString(),
    };
  }
}

class CalendarHrtEditSheet extends StatefulWidget {
  final List<Map<String, String>> initialHrt;
  final void Function(List<Map<String, String>> updated) onSave;

  const CalendarHrtEditSheet({
    super.key,
    required this.initialHrt,
    required this.onSave,
  });

  @override
  State<CalendarHrtEditSheet> createState() => _CalendarHrtEditSheetState();
}

class _CalendarHrtEditSheetState extends State<CalendarHrtEditSheet> {
  late List<HrtEditEntry> _entries;
  int? _expandedIndex; // which card is expanded for editing

  @override
  void initState() {
    super.initState();
    _entries = widget.initialHrt.map(HrtEditEntry.fromMap).toList();
  }

  void _toggleTaken(int index) {
    setState(() {
      _entries[index].isTaken = !_entries[index].isTaken;
    });
  }

  void _setUnit(int index, String unit) {
    setState(() {
      _entries[index].unit = unit;
    });
  }

  void _setDose(int index, String dose) {
    setState(() {
      _entries[index].dose = dose;
    });
  }

  void _toggleExpanded(int index) {
    setState(() {
      _expandedIndex = _expandedIndex == index ? null : index;
    });
  }

  void _save() {
    widget.onSave(_entries.map((e) => e.toMap()).toList());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFEF8F6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0DEDA),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Medication',
                      style: GoogleFonts.notoSerif(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1D1B1A),
                      ),
                    ),
                    Text(
                      'Tap a medication to edit details',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: const Color(0xFF7F756E),
                      ),
                    ),
                  ],
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
                        color: const Color(0xFFF2EDEA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Color(0xFF9B8B7E), size: 20),
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
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CURRENT PRESCRIPTION label
                  Text(
                    'CURRENT PRESCRIPTION',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: const Color(0xFF9B8B7E),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Medication cards
                  ..._entries.asMap().entries.map((e) {
                    return _buildMedicationCard(e.key, e.value);
                  }),

                  const SizedBox(height: 8),

                  // Wellness tip box
                  _buildTipCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(int index, HrtEditEntry entry) {
    final isExpanded = _expandedIndex == index;
    final isTaken = entry.isTaken;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded
              ? AppTheme.primary.withValues(alpha: 0.3)
              : const Color(0xFFEAE6E0),
          width: isExpanded ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main row: tap to expand
          InkWell(
            onTap: () => _toggleExpanded(index),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(20),
              bottom: Radius.circular(isExpanded ? 0 : 20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Medication icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2DFD0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.medication,
                        color: AppTheme.primary, size: 28),
                  ),
                  const SizedBox(width: 14),

                  // Name + details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.name,
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1D1B1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${entry.dose} ${entry.unit} · ${entry.applicationType}',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: const Color(0xFF7F756E),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status badge + expand icon
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isTaken
                              ? const Color(0xFFE8F5ED)
                              : const Color(0xFFFFF1ED),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isTaken
                              ? 'TAKEN ${entry.timeTaken}'
                              : 'NOT TAKEN',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: isTaken
                                ? const Color(0xFF2D5A3E)
                                : const Color(0xFF8C3A25),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 200),
                        turns: isExpanded ? 0.5 : 0,
                        child: const Icon(Icons.expand_more,
                            size: 20, color: Color(0xFF9B8B7E)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded editing panel
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF2EDEA)),
            _buildExpandedPanel(index, entry),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandedPanel(int index, HrtEditEntry entry) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F2F0),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Log Dose Now button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _entries[index].isTaken = true;
                  // Use current time
                  final now = TimeOfDay.now();
                  final h = now.hour.toString().padLeft(2, '0');
                  final m = now.minute.toString().padLeft(2, '0');
                  _entries[index].timeTaken = '$h:$m';
                });
              },
              icon: const Icon(Icons.history_edu, size: 22),
              label: Text(
                'Log Dose Now',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF817266),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Today's log
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEAE6E0)),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's Log",
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1D1B1A),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showTimePicker(index),
                      icon: const Icon(Icons.more_time, size: 16),
                      label: Text(
                        'Edit Time',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (entry.isTaken) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppTheme.primary, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          '${entry.timeTaken} ${_formatAmPm(entry.timeTaken)}',
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1D1B1A),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Manual',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: const Color(0xFF9B8B7E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  InkWell(
                    onTap: () => _toggleTaken(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFDAD3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.radio_button_unchecked,
                              color: Color(0xFF8C3A25), size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Not taken — tap to mark as taken',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: const Color(0xFF8C3A25),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Dose editor
          Text(
            'UPDATE DOSE',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: const Color(0xFF9B8B7E),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller:
                        TextEditingController(text: entry.dose),
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1D1B1A),
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onChanged: (v) => _setDose(index, v),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Unit selector
              Container(
                height: 56,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['mcg', 'mg', 'pump'].map((u) {
                    final isSelected = entry.unit == u;
                    return InkWell(
                      onTap: () => _setUnit(index, u),
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          u,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF7F756E),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2DFD0).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD6C3B5).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline,
              color: AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Consistency is key for hormone stability. Try to take your medication within the same time window each day.',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: const Color(0xFF51443A),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF2EDEA))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                  shadowColor: AppTheme.primary.withValues(alpha: 0.3),
                ),
                child: Text(
                  'Save changes',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTimePicker(int index) async {
    final current = _entries[index].timeTaken.split(':');
    final hour = int.tryParse(current.first) ?? 8;
    final minute = int.tryParse(current.last) ?? 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppTheme.primary,
            onPrimary: Colors.white,
            surface: const Color(0xFFFEF8F6),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        final h = picked.hour.toString().padLeft(2, '0');
        final m = picked.minute.toString().padLeft(2, '0');
        _entries[index].timeTaken = '$h:$m';
        _entries[index].isTaken = true;
      });
    }
  }

  String _formatAmPm(String time24) {
    final parts = time24.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    return hour < 12 ? 'AM' : 'PM';
  }
}
