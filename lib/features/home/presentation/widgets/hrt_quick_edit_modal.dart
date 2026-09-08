import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../onboarding/domain/models/medication.dart';
import '../../../onboarding/presentation/providers/medications_provider.dart';

class HrtQuickEditModal extends ConsumerStatefulWidget {
  final Medication medication;
  final VoidCallback? onNavigateToHrtTracker;

  const HrtQuickEditModal({
    super.key,
    required this.medication,
    this.onNavigateToHrtTracker,
  });

  @override
  ConsumerState<HrtQuickEditModal> createState() => _HrtQuickEditModalState();
}

class _HrtQuickEditModalState extends ConsumerState<HrtQuickEditModal> {
  late TextEditingController _doseController;
  late String _selectedUnit;
  late String _selectedFrequency;
  late List<int> _selectedWeekdays;
  String? _weekdayError;

  final List<String> _frequencies = [
    'Daily',
    'Twice weekly',
    'Weekly',
    'As needed',
  ];

  final List<String> _monthsNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    final med = widget.medication;
    _doseController = TextEditingController(
      text: med.dose.toStringAsFixed(med.dose == med.dose.toInt() ? 0 : 2).replaceAll(RegExp(r'\.00$'), ''),
    );
    _selectedUnit = med.unit;
    _selectedFrequency = med.frequency.isEmpty ? 'Daily' : med.frequency;
    _selectedWeekdays = List<int>.from(med.selectedWeekdays);
  }

  @override
  void dispose() {
    _doseController.dispose();
    super.dispose();
  }

  List<double> _getAvailableDoses(String unit) {
    final u = unit.toLowerCase();
    if (u == 'mcg') {
      return [5.0, 10.0, 12.5, 25.0, 50.0, 75.0, 100.0, 125.0, 150.0, 200.0, 250.0, 400.0, 500.0];
    } else if (u == 'mg') {
      return [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 10.0, 20.0, 50.0, 100.0, 150.0, 200.0, 300.0, 400.0];
    } else if (u == 'g') {
      return [0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0];
    } else if (u == 'pumps') {
      return [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0];
    } else {
      return List.generate(15, (i) => (i + 1).toDouble());
    }
  }

  void _openDosePicker() {
    final doses = _getAvailableDoses(_selectedUnit);
    final currentDose = double.tryParse(_doseController.text) ?? 1.0;
    int initialIndex = doses.indexWhere((d) => (d - currentDose).abs() < 0.01);
    if (initialIndex == -1) initialIndex = 0;

    double tempDose = doses[initialIndex];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFEF8F6),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0C4BC).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: GoogleFonts.manrope(color: const Color(0xFF78716C))),
                  ),
                  Text(
                    'Select Dose',
                    style: GoogleFonts.notoSerif(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _doseController.text = tempDose.toStringAsFixed(tempDose == tempDose.toInt() ? 0 : 2).replaceAll(RegExp(r'\.00$'), '');
                      });
                      Navigator.pop(context);
                    },
                    child: Text('Done', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: initialIndex),
                  itemExtent: 44,
                  onSelectedItemChanged: (index) {
                    tempDose = doses[index];
                  },
                  children: doses.map((d) {
                    return Center(
                      child: Text(
                        d.toStringAsFixed(d == d.toInt() ? 0 : 2).replaceAll(RegExp(r'\.00$'), ''),
                        style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _save() {
    final lowerFreq = _selectedFrequency.toLowerCase();
    if (lowerFreq.contains('twice') && _selectedWeekdays.length != 2) {
      setState(() {
        _weekdayError = 'Please select exactly 2 days of the week.';
      });
      return;
    }
    if (lowerFreq.contains('weekly') && !lowerFreq.contains('twice') && _selectedWeekdays.length != 1) {
      setState(() {
        _weekdayError = 'Please select 1 day of the week.';
      });
      return;
    }

    final parsedDose = double.tryParse(_doseController.text) ?? widget.medication.dose;
    final updatedMedication = widget.medication.copyWith(
      dose: parsedDose,
      unit: _selectedUnit,
      frequency: _selectedFrequency,
      selectedWeekdays: _selectedWeekdays,
    );

    final isClinical = parsedDose != widget.medication.dose ||
        _selectedUnit != widget.medication.unit ||
        _selectedFrequency != widget.medication.frequency;

    if (isClinical) {
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            'Doctor Confirmation',
            style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Was this regimen change prescribed or recommended by your doctor?',
            style: GoogleFonts.manrope(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ).then((isDoctor) {
        ref.read(medicationsProvider.notifier).updateMedication(updatedMedication);
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } else {
      ref.read(medicationsProvider.notifier).updateMedication(updatedMedication);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final med = widget.medication;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFEF8F6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD0C4BC).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: GoogleFonts.notoSerif(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1D1B1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${med.type.displayName} • Edit Medication',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: const Color(0xFF78716C),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF78716C)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 1. DOSE SECTION
            Text(
              'DOSE',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: const Color(0xFF8A817C),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _openDosePicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE7E5E4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _doseController.text.isEmpty ? '0' : _doseController.text,
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          const Icon(Icons.unfold_more, color: Color(0xFF8A817C), size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F5F0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE7E5E4)),
                  ),
                  child: Text(
                    _selectedUnit,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF67594E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. FREQUENCY SECTION
            Text(
              'FREQUENCY',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: const Color(0xFF8A817C),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _frequencies.map((freq) {
                final isSelected = _selectedFrequency.toLowerCase() == freq.toLowerCase();
                return ChoiceChip(
                  label: Text(freq),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedFrequency = freq;
                        _weekdayError = null;
                        if (freq.toLowerCase().contains('twice')) {
                          if (_selectedWeekdays.length != 2) _selectedWeekdays = [1, 4];
                        } else if (freq.toLowerCase().contains('weekly')) {
                          if (_selectedWeekdays.length != 1) _selectedWeekdays = [1];
                        } else if (freq.toLowerCase().contains('needed')) {
                          _selectedWeekdays = [];
                        } else {
                          _selectedWeekdays = [1, 2, 3, 4, 5, 6, 7];
                        }
                      });
                    }
                  },
                  labelStyle: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF4D453F),
                  ),
                  selectedColor: AppTheme.primary,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primary : const Color(0xFFE7E5E4),
                    ),
                  ),
                );
              }).toList(),
            ),
            Builder(builder: (context) {
              final lower = _selectedFrequency.toLowerCase();
              final isTwice = lower.contains('twice');
              final isWeekly = lower.contains('weekly') && !isTwice;
              if (!isTwice && !isWeekly) return const SizedBox.shrink();

              final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),
                  Text(
                    isTwice
                        ? 'SELECT SCHEDULED DAYS (REQUIRED: 2 DAYS)'
                        : 'SELECT SCHEDULED DAY (REQUIRED: 1 DAY)',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: const Color(0xFF8A817C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(7, (index) {
                      final weekday = index + 1;
                      final isSelected = _selectedWeekdays.contains(weekday);
                      return ChoiceChip(
                        label: Text(weekdayNames[index]),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _weekdayError = null;
                            final newSelected = List<int>.from(_selectedWeekdays);
                            if (isWeekly) {
                              newSelected.clear();
                              newSelected.add(weekday);
                            } else {
                              if (isSelected) {
                                if (newSelected.length > 1) newSelected.remove(weekday);
                              } else {
                                if (newSelected.length >= 2) newSelected.removeAt(0);
                                newSelected.add(weekday);
                              }
                            }
                            newSelected.sort();
                            _selectedWeekdays = newSelected;
                          });
                        },
                        selectedColor: AppTheme.primary,
                        backgroundColor: Colors.white,
                        labelStyle: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF4D453F),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected ? AppTheme.primary : const Color(0xFFE7E5E4),
                          ),
                        ),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      );
                    }),
                  ),
                  if (_weekdayError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _weekdayError!,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8C3A25),
                      ),
                    ),
                  ],
                ],
              );
            }),
            const SizedBox(height: 28),

            // 3. MEDICATION MANAGEMENT (HRT TRACKER)
            Text(
              'MEDICATION MANAGEMENT',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: const Color(0xFF8A817C),
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                widget.onNavigateToHrtTracker?.call();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F5F0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE7E5E4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.settings_outlined, color: Color(0xFF67594E), size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manage or Stop Taking',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurface,
                              ),
                            ),
                            Text(
                              'Access full management in HRT Tracker',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: const Color(0xFF78716C),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF8A817C), size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
