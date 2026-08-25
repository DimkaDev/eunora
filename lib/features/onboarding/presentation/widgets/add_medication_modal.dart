import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/medication.dart';
import '../providers/medications_provider.dart';
import '../providers/onboarding_profile_provider.dart';
import 'package:eunora/core/utils/animation_system.dart';
import 'package:eunora/features/home/presentation/widgets/dose_change_alert.dart';
import 'package:eunora/features/hrt_tracker/data/hrt_drug_library.dart';
import 'package:eunora/features/hrt_tracker/data/hrt_quick_add_service.dart';
import 'package:eunora/features/hrt_tracker/providers/hrt_quick_add_provider.dart';
import 'package:eunora/features/hrt_tracker/presentation/widgets/hrt_quick_add_card.dart';
import 'package:eunora/features/home/presentation/widgets/calendar_hrt_edit_sheet.dart';
import 'package:uuid/uuid.dart';

class AddMedicationModal extends ConsumerStatefulWidget {
  final dynamic initialData; // Can be Medication for edit or String for prefill name
  final bool showDiscontinuedToggle;
  final bool isRetrospectiveOneOff;
  final Function(HrtEditEntry entry)? onAddOneOffEntry;

  const AddMedicationModal({
    super.key,
    this.initialData,
    this.showDiscontinuedToggle = false,
    this.isRetrospectiveOneOff = false,
    this.onAddOneOffEntry,
  });

  @override
  ConsumerState<AddMedicationModal> createState() => _AddMedicationModalState();
}

class _AddMedicationModalState extends ConsumerState<AddMedicationModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _doseController;
  late TextEditingController _notesController;

  MedicationType _selectedType = MedicationType.pill;
  String _selectedUnit = 'mg';
  String _selectedFrequency = 'Daily';
  List<int> _selectedWeekdays = [1, 2, 3, 4, 5, 6, 7];
  String? _weekdayError;

  bool _showDropdown = false;
  List<String> _filteredMeds = [];
  bool _isCustomDose = false;
  String? _selectedQuickAddName;

  bool _isNotCurrentlyTaking = false;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _dateError;

  // --- HRT Drug Library v2 state ---
  bool _isCombined = false;
  String? _combinedComponents;
  String _drugCategory = 'systemicEstrogen';
  String _drugMarket = 'uk';

  /// Full library names for autocomplete (all 33 entries).
  static final List<String> _allLibraryNames =
      kHrtDrugLibrary.map((d) => d.name).toList();

  final List<String> _monthsNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _doseController = TextEditingController(text: '1');
    _notesController = TextEditingController();

    if (widget.initialData is Medication) {
      final med = widget.initialData as Medication;
      _nameController.text = med.name;
      _doseController.text = med.dose.toStringAsFixed(med.dose == med.dose.toInt() ? 0 : 2);
      _notesController.text = med.notes ?? '';
      _selectedType = med.type;
      _selectedUnit = med.unit;
      _selectedFrequency = med.frequency;
      _selectedWeekdays = List<int>.from(med.selectedWeekdays);
      _isNotCurrentlyTaking = med.endedAt != null;
      _startDate = med.startedAt;
      _endDate = med.endedAt;

      final presets = _getDosePresets(med.type);
      final formattedDose = med.dose.toStringAsFixed(med.dose == med.dose.toInt() ? 0 : 2);
      if (!presets.contains(formattedDose)) {
        _isCustomDose = true;
      }
    } else if (widget.initialData is String) {
      _nameController.text = widget.initialData as String;
      _selectedWeekdays = [1, 2, 3, 4, 5, 6, 7];
    } else {
      _selectedWeekdays = [1, 2, 3, 4, 5, 6, 7];
    }

    _nameController.addListener(_onNameChanged);

    // --- HRT Drug Library v2: restore combined state when editing ---
    if (widget.initialData is Medication) {
      final med = widget.initialData as Medication;
      _isCombined = med.isCombinedProduct;
      _combinedComponents = med.combinedComponents;
      _drugCategory = med.drugCategory;
      _drugMarket = med.market;
    }
  }

  /// Pre-fills the modal from a Quick-Add card selection.
  void _applyQuickAdd(HrtDrugOption drug) {
    setState(() {
      _selectedQuickAddName = drug.name;
      _nameController.text = drug.name;
      _showDropdown = false;
      _filteredMeds = [];
      _isCombined = drug.isCombinedProduct;
      _drugCategory = drug.category.name;
      _drugMarket = drug.market.name;
      // Derive combinedComponents from library (display-only)
      final def = HrtQuickAddService.findByName(drug.name);
      _combinedComponents = def != null && def.isCombinedProduct
          ? _defaultComponentsForDrug(drug.name)
          : null;
      // Map first common form to MedicationType
      final form = drug.commonForms.isNotEmpty ? drug.commonForms.first : 'tablet';
      _selectedType = _formToMedicationType(form);
      if (_selectedType == MedicationType.gel) {
        _selectedUnit = 'pumps';
        _doseController.text = '1';
      } else if (_selectedType == MedicationType.spray) {
        _selectedUnit = 'sprays';
        _doseController.text = '1';
      } else if (_selectedType == MedicationType.patch) {
        _selectedUnit = 'mcg';
        _doseController.text = '50';
      } else {
        _selectedUnit = 'mg';
        _doseController.text = '1';
      }
      _isCustomDose = false;
    });
  }

  static MedicationType _formToMedicationType(String form) {
    switch (form) {
      case 'patch': return MedicationType.patch;
      case 'gel': return MedicationType.gel;
      case 'spray': return MedicationType.spray;
      case 'tablet': return MedicationType.pill;
      case 'pessary': return MedicationType.pessary;
      case 'ring': return MedicationType.ring;
      default: return MedicationType.other;
    }
  }

  /// Returns a sensible default component description for known combined products.
  static String? _defaultComponentsForDrug(String name) {
    const map = <String, String>{
      'Evorel Conti': 'estradiol+norethindrone',
      'Evorel Sequi': 'estradiol+norethindrone',
      'Femoston': 'estradiol+dydrogesterone',
      'Femoston Conti': 'estradiol+dydrogesterone',
      'FemSeven Conti': 'estradiol+levonorgestrel',
      'FemSeven Sequi': 'estradiol+levonorgestrel',
      'Kliovance': 'estradiol+norethindrone',
      'Kliofem': 'estradiol+norethindrone',
      'Elleste Duet': 'estradiol+norethindrone',
      'Novofem': 'estradiol+norethindrone',
      'Prempro': 'conjugated estrogens+medroxyprogesterone',
      'Combipatch': 'estradiol+norethindrone',
      'Climara Pro': 'estradiol+levonorgestrel',
      'Bijuve': 'estradiol+micronized progesterone',
    };
    return map[name];
  }

  void _onNameChanged() {
    final query = _nameController.text.toLowerCase();
    if (_selectedQuickAddName != null && _nameController.text != _selectedQuickAddName) {
      setState(() {
        _selectedQuickAddName = null;
      });
    }
    if (query.isEmpty) {
      setState(() {
        _showDropdown = false;
        _filteredMeds = [];
      });
      return;
    }

    // Search the full 33-entry library (not the old 5-item hardcoded list)
    final filtered = _allLibraryNames
        .where((m) => m.toLowerCase().contains(query))
        .toList();
    setState(() {
      _filteredMeds = filtered;
      _showDropdown = filtered.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<String> _getDosePresets(MedicationType type) {
    switch (type) {
      case MedicationType.pill:
        return ['0.5', '1', '2', '5'];
      case MedicationType.patch:
        return ['25', '50', '75', '100'];
      case MedicationType.gel:
        return ['1', '2', '3', '4'];
      default:
        return ['1', '2', '5', '10'];
    }
  }

  List<double> _getAvailableDoses(String unit) {
    final u = unit.toLowerCase();
    if (u == 'mcg') {
      return [5.0, 10.0, 12.5, 25.0, 50.0, 75.0, 100.0, 125.0, 150.0, 200.0, 250.0, 400.0, 500.0, 800.0, 1000.0];
    } else if (u == 'mg') {
      return [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 10.0, 20.0, 50.0, 100.0, 150.0, 200.0, 300.0, 400.0];
    } else if (u == 'g') {
      return [0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 6.0, 7.5, 10.0, 15.0, 20.0];
    } else if (u == 'capsules') {
      return [1.0, 2.0, 3.0, 4.0, 5.0, 6.0];
    } else if (u == 'tablets') {
      return [0.5, 1.0, 1.5, 2.0, 3.0, 4.0];
    } else if (u == 'pumps') {
      return [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0];
    } else if (u == 'applicator') {
      return [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0];
    } else {
      return List.generate(20, (i) => (i + 1).toDouble());
    }
  }

  void _openDosePicker({
    required String unit,
    required double currentDose,
    required ValueChanged<double> onDoseChanged,
  }) {
    final doses = _getAvailableDoses(unit);
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
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: const Color(0xFF8A817C)),
                    ),
                  ),
                  Text(
                    'Select Dose',
                    style: GoogleFonts.notoSerif(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      double initialDose = 0;
                      if (widget.initialData is Medication) {
                        initialDose = (widget.initialData as Medication).dose;
                      }

                      final isOnboardingCompleted = ref.read(onboardingProfileProvider)?.isOnboardingCompleted ?? false;
                      if (isOnboardingCompleted && initialDose > 0 && (tempDose - initialDose).abs() > 0.01) {
                        showDialog(
                          context: this.context,
                          barrierDismissible: false,
                          barrierColor: const Color(0xFF1D1B1A).withOpacity(0.4),
                          builder: (dialogContext) {
                            return DoseChangeAlert(
                              change: {
                                'name': _nameController.text.isNotEmpty ? _nameController.text : 'Medication',
                                'oldDose': '${initialDose.toStringAsFixed(initialDose == initialDose.toInt() ? 0 : 2).replaceAll(RegExp(r'\.00$'), '')} $unit',
                                'newDose': '${tempDose.toStringAsFixed(tempDose == tempDose.toInt() ? 0 : 2).replaceAll(RegExp(r'\.00$'), '')} $unit',
                              },
                              onConfirm: () {
                                Navigator.pop(dialogContext);
                                onDoseChanged(tempDose);
                                Navigator.pop(context);
                              },
                              onCancel: () {
                                Navigator.pop(dialogContext);
                              },
                            );
                          },
                        );
                      } else {
                        onDoseChanged(tempDose);
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      'Done',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
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
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                        ),
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
    if (_formKey.currentState!.validate()) {
      if (_isNotCurrentlyTaking) {
        final now = DateTime.now();
        final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        final start = _startDate ?? now;
        final end = _endDate ?? now;

        if (start.isAfter(todayEnd) || end.isAfter(todayEnd)) {
          setState(() {
            _dateError = 'Dates cannot be in the future.';
          });
          return;
        }

        final startOnly = DateTime(start.year, start.month, start.day);
        final endOnly = DateTime(end.year, end.month, end.day);
        if (endOnly.isBefore(startOnly)) {
          setState(() {
            _dateError = 'End date cannot be before start date.';
          });
          return;
        }
      }

      // Validate weekday selection for Weekly and Twice Weekly
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

      // Auto-detect drug category from library if user typed the name manually
      final def = HrtQuickAddService.findByName(_nameController.text.trim());
      final finalCategory = def != null ? def.category.name : _drugCategory;
      final finalMarket = def != null ? def.market.name : _drugMarket;
      final finalIsCombined = def != null ? def.isCombinedProduct : _isCombined;
      final finalComponents = finalIsCombined
          ? (_combinedComponents ?? _defaultComponentsForDrug(_nameController.text.trim()))
          : null;

      final medication = Medication(
        id: widget.initialData is Medication ? (widget.initialData as Medication).id : null,
        name: _nameController.text.trim(),
        type: _selectedType,
        dose: double.tryParse(_doseController.text) ?? 0,
        unit: _selectedUnit,
        frequency: _selectedFrequency,
        selectedWeekdays: _selectedWeekdays,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        drugCategory: finalCategory,
        isCombinedProduct: finalIsCombined,
        combinedComponents: finalComponents,
        market: finalMarket,
        startedAt: _isNotCurrentlyTaking ? _startDate : (_startDate ?? (widget.initialData is Medication ? (widget.initialData as Medication).startedAt : null)),
        endedAt: _isNotCurrentlyTaking ? (_endDate ?? DateTime.now()) : null,
      );

      if (widget.isRetrospectiveOneOff) {
        final parsedDose = double.tryParse(_doseController.text) ?? 0;
        final oneOffEntry = HrtEditEntry(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          details: '${parsedDose.toStringAsFixed(parsedDose == parsedDose.toInt() ? 0 : 2)} $_selectedUnit · ${_selectedType.displayName}',
          status: 'Taken',
          isTaken: true,
          dose: parsedDose.toStringAsFixed(parsedDose == parsedDose.toInt() ? 0 : 2),
          unit: _selectedUnit,
          applicationType: _selectedType.displayName,
          timeTaken: '08:00',
        );
        widget.onAddOneOffEntry?.call(oneOffEntry);

        if (_alsoAddToCurrentMedications) {
          ref.read(medicationsProvider.notifier).addMedication(medication);
        }
      } else if (widget.initialData is Medication) {
        ref.read(medicationsProvider.notifier).updateMedication(medication);
      } else {
        ref.read(medicationsProvider.notifier).addMedication(medication);
      }

      context.pop();
    }
  }

  bool _alsoAddToCurrentMedications = false;

  Widget _buildRetrospectiveOneOffToggleSection() {
    if (!widget.isRetrospectiveOneOff) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _alsoAddToCurrentMedications ? AppTheme.primary : const Color(0xFFE7E5E4),
              width: _alsoAddToCurrentMedications ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Also add to my current medications",
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1D1B1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Default: Off. Enable to add to ongoing tracking schedule.',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: const Color(0xFF78716C),
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _alsoAddToCurrentMedications,
                activeColor: AppTheme.primary,
                onChanged: (val) {
                  setState(() {
                    _alsoAddToCurrentMedications = val;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDiscontinuedToggleSection() {
    if (!widget.showDiscontinuedToggle) {
      return const SizedBox.shrink();
    }
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isNotCurrentlyTaking ? const Color(0xFF67594E) : const Color(0xFFE7E5E4),
              width: _isNotCurrentlyTaking ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "I'm not currently taking this",
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1D1B1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Record a discontinued or past medication for your history',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: const Color(0xFF78716C),
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _isNotCurrentlyTaking,
                activeColor: const Color(0xFF67594E),
                onChanged: (val) {
                  setState(() {
                    _isNotCurrentlyTaking = val;
                    _dateError = null;
                    if (val) {
                      _startDate ??= DateTime.now();
                      _endDate ??= DateTime.now();
                    }
                  });
                },
              ),
            ],
          ),
        ),
        if (_isNotCurrentlyTaking) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Start Date'),
                    const SizedBox(height: 8),
                    _buildDatePickerTile(
                      date: _startDate ?? now,
                      onTap: () => _selectDate(
                        isStart: true,
                        initial: _startDate ?? now,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('End Date'),
                    const SizedBox(height: 8),
                    _buildDatePickerTile(
                      date: _endDate ?? now,
                      onTap: () => _selectDate(
                        isStart: false,
                        initial: _endDate ?? now,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_dateError != null) ...[
            const SizedBox(height: 8),
            Text(
              _dateError!,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF8C3A25),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildDatePickerTile({required DateTime date, required VoidCallback onTap}) {
    final formatted = "${_monthsNames[date.month - 1].substring(0, 3)} ${date.day}, ${date.year}";
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF2EDE9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formatted,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1D1B1A),
              ),
            ),
            const Icon(Icons.calendar_today, size: 16, color: Color(0xFF8A817C)),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate({required bool isStart, required DateTime initial}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(2000),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF1D1B1A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateError = null;
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFFEF8F6), // surface
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.initialData is Medication ? 'Edit Medication' : 'Add Medication',
                  style: const TextStyle(
                    fontFamily: 'Noto Serif',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF67594E),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF67594E)),
                  onPressed: () => context.pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF2EDE9),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF2EDE9)),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Keep track of your hormone therapy to help identify cycle wellness patterns.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF4D453F)),
                    ),
                    // --- Quick-Add Row (shown only on add, not edit) ---
                    if (widget.initialData is! Medication) ...[
                      _buildQuickAddRow(),
                      const SizedBox(height: 24),
                    ],

                    // Name Input
                    _buildSectionHeader('Medication Name'),
                    const SizedBox(height: 8),
                    _buildNameInput(),
                    
                    if (_showDropdown) ...[
                      const SizedBox(height: 8),
                      _buildSearchDropdown(),
                    ],

                    // Combined product info note
                    if (_isCombined) ...[
                      const SizedBox(height: 12),
                      _buildCombinedProductNote(),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Type Selection
                    _buildSectionHeader('How do you take it?'),
                    const SizedBox(height: 12),
                    _buildTypeSelection(),
                    
                    if (_selectedType == MedicationType.other) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF67594E).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF67594E).withOpacity(0.2)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFF67594E), size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Other administration methods could include subcutaneous injections, nasal sprays, vaginal creams, rings, or intrauterine devices (IUDs). Please specify details in the Notes section below.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF4D453F),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    
                    // Dosage
                    _buildSectionHeader('Dose'),
                    const SizedBox(height: 8),
                    _buildDoseSelector(),
                    const SizedBox(height: 24),

                    // Frequency
                    if (!widget.isRetrospectiveOneOff || _alsoAddToCurrentMedications) ...[
                      _buildSectionHeader('Frequency'),
                      const SizedBox(height: 8),
                      _buildFrequencySelector(),
                      const SizedBox(height: 24),
                    ],

                    // Retrospective One-Off Toggle
                    _buildRetrospectiveOneOffToggleSection(),

                    // Discontinued / Past medication toggle
                    _buildDiscontinuedToggleSection(),
                    const SizedBox(height: 24),

                    // Notes Input
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader('Notes'),
                        const Text(
                          'Optional',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFFA8A29E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildNotesInput(),
                    const SizedBox(height: 32),
                    
                    if (isKeyboardOpen) ...[
                      _buildFooterButtonsContent(),
                      const SizedBox(height: 24),
                    ] else ...[
                      const SizedBox(height: 120), // Bottom padding
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Sticky Footer Actions (hidden if keyboard is open to prevent occlusion)
          if (!isKeyboardOpen)
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF8F6),
                border: Border(top: BorderSide(color: Color(0xFFF2EDE9))),
              ),
              child: _buildFooterButtonsContent(),
            ),
        ],
      ),
    );
  }

  Widget _buildFooterButtonsContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF817266),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 0,
          ),
          child: Text(
            widget.initialData is Medication ? 'SAVE CHANGES' : 'CONFIRM & ADD',
            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.pop(),
          child: const Text(
            'CANCEL',
            style: TextStyle(color: Color(0xFF67594E), fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1D1B1A),
      ),
    );
  }

  Widget _buildNameInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2EDE9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(
          hintText: 'Search (e.g., Estradiol)',
          hintStyle: TextStyle(color: Color(0xFFA8A29E)),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: InputBorder.none,
          suffixIcon: Icon(Icons.search, color: Color(0xFFA8A29E)),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  bool _isFormSupported(MedicationType type) {
    final name = _nameController.text.trim().toLowerCase();
    if (name.isEmpty) return true;
    
    // Find definition in kHrtDrugLibrary
    final def = kHrtDrugLibrary.firstWhere(
      (d) => d.name.toLowerCase() == name,
      orElse: () => const HrtDrugDefinition(
        name: '',
        category: HrtDrugCategory.systemicEstrogen,
        commonForms: [],
        market: HrtMarket.both,
      ),
    );
    
    if (def.name.isEmpty) {
      // Custom drug not in library: all forms remain selectable
      return true;
    }
    
    // Map commonForms to MedicationType values
    return def.commonForms.any((form) {
      final cleanForm = form.toLowerCase();
      switch (type) {
        case MedicationType.patch:
          return cleanForm == 'patch';
        case MedicationType.pill:
          return cleanForm == 'tablet' || cleanForm == 'pill';
        case MedicationType.gel:
          return cleanForm == 'gel';
        case MedicationType.cream:
          return cleanForm == 'cream';
        case MedicationType.spray:
          return cleanForm == 'spray';
        case MedicationType.pessary:
          return cleanForm == 'pessary';
        case MedicationType.ring:
          return cleanForm == 'ring';
        case MedicationType.other:
          return true;
      }
    });
  }

  Widget _buildSearchDropdown() {
    // Group _filteredMeds by actual category
    final Map<String, List<String>> grouped = {};
    for (final name in _filteredMeds) {
      final def = kHrtDrugLibrary.firstWhere(
        (d) => d.name.toLowerCase() == name.toLowerCase(),
        orElse: () => HrtDrugDefinition(
          name: name,
          category: HrtDrugCategory.systemicEstrogen,
          commonForms: [],
          market: HrtMarket.both,
        ),
      );
      
      final String catHeader;
      final inLibrary = kHrtDrugLibrary.any((d) => d.name.toLowerCase() == name.toLowerCase());
      if (inLibrary) {
        switch (def.category) {
          case HrtDrugCategory.systemicEstrogen:
            catHeader = 'SYSTEMIC ESTROGEN';
            break;
          case HrtDrugCategory.combined:
            catHeader = 'COMBINED';
            break;
          case HrtDrugCategory.progestogenOnly:
            catHeader = 'PROGESTOGEN ONLY';
            break;
          case HrtDrugCategory.vaginalLocal:
            catHeader = 'VAGINAL/LOCAL';
            break;
        }
      } else {
        catHeader = 'OTHER';
      }
      grouped.putIfAbsent(catHeader, () => []).add(name);
    }

    final List<Widget> children = [];
    grouped.forEach((category, meds) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            category,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFFA8A29E),
              letterSpacing: 1.0,
            ),
          ),
        ),
      );
      children.addAll(meds.map((name) {
        final def = kHrtDrugLibrary.firstWhere(
          (d) => d.name.toLowerCase() == name.toLowerCase(),
          orElse: () => HrtDrugDefinition(
            name: name,
            category: HrtDrugCategory.systemicEstrogen,
            commonForms: [],
            market: HrtMarket.both,
          ),
        );
        return ListTile(
          leading: Icon(Icons.medication, color: AppTheme.primary.withOpacity(0.4)),
          title: Text(name, style: const TextStyle(fontSize: 14)),
          onTap: () {
            FocusScope.of(context).unfocus();
            _nameController.text = name;
            setState(() {
              _showDropdown = false;
              _isCombined = def.isCombinedProduct;
              _drugCategory = def.category.name;
              _drugMarket = def.market.name;
              _combinedComponents = def.isCombinedProduct
                  ? _defaultComponentsForDrug(name)
                  : null;
              
              // If the current selected form is not supported, change to the first supported form
              if (!_isFormSupported(_selectedType) && def.commonForms.isNotEmpty) {
                final firstForm = def.commonForms.first;
                _selectedType = _formToMedicationType(firstForm);
                if (_selectedType == MedicationType.patch) {
                  _selectedUnit = 'mcg';
                  _doseController.text = '50';
                } else if (_selectedType == MedicationType.gel) {
                  _selectedUnit = 'pumps';
                  _doseController.text = '1';
                } else if (_selectedType == MedicationType.spray) {
                  _selectedUnit = 'sprays';
                  _doseController.text = '1';
                } else {
                  _selectedUnit = 'mg';
                  _doseController.text = '1';
                }
              }
            });
          },
        );
      }));
    });

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2EDE9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: children,
      ),
    );
  }

  Widget _buildTypeSelection() {
    final types = [
      MedicationType.patch,
      MedicationType.pill,
      MedicationType.gel,
      MedicationType.spray,
      MedicationType.pessary,
      MedicationType.ring,
      MedicationType.other,
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: types.map((type) => _buildTypeTile(type)).toList(),
    );
  }

  Widget _buildTypeTile(MedicationType type) {
    final isSelected = _selectedType == type;
    final isEditing = widget.initialData is Medication;
    final isSupported = _isFormSupported(type);

    return InkWell(
      onTap: (isEditing || !isSupported) ? null : () {
        setState(() {
          _selectedType = type;
          if (type == MedicationType.gel) {
            _selectedUnit = 'pumps';
            _doseController.text = '1';
          } else if (type == MedicationType.spray) {
            _selectedUnit = 'sprays';
            _doseController.text = '1';
          } else if (type == MedicationType.patch) {
            _selectedUnit = 'mcg';
            _doseController.text = '50';
          } else if (type == MedicationType.pill) {
            _selectedUnit = 'mg';
            _doseController.text = '1';
          } else if (type == MedicationType.pessary) {
            _selectedUnit = 'mg';
            _doseController.text = '1';
          } else if (type == MedicationType.ring) {
            _selectedUnit = 'mg';
            _doseController.text = '1';
          } else {
            _selectedUnit = 'mg';
            _doseController.text = '1';
          }
          _isCustomDose = false;
        });
      },
      child: Opacity(
        opacity: (!isSupported || (isEditing && !isSelected)) ? 0.3 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primary : const Color(0xFFD0C4BC),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getIconData(type.iconName),
                color: AppTheme.primary.withOpacity(isSelected ? 1.0 : 0.7),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                type.displayName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppTheme.primary : const Color(0xFF4D453F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'rectangle': return Icons.rectangle_outlined;
      case 'pill': return Icons.medication;
      case 'clean_hands': return Icons.clean_hands;
      case 'air': return Icons.air;
      case 'vaccines': return Icons.vaccines;
      case 'radio_button_unchecked': return Icons.radio_button_unchecked;
      default: return Icons.more_horiz;
    }
  }

  Widget _buildDoseSelector() {
    final presets = _getDosePresets(_selectedType);
    final currentDoseStr = _doseController.text;
    final isEditing = widget.initialData is Medication;
    final showUnitSelector = _selectedType == MedicationType.other && !isEditing;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...presets.map((preset) {
              final isSelected = !_isCustomDose && currentDoseStr == preset;
              return ChoiceChip(
                label: Text('$preset $_selectedUnit'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _isCustomDose = false;
                      _doseController.text = preset;
                    });
                  }
                },
                selectedColor: const Color(0xFF67594E),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF4D453F),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF67594E) : const Color(0xFFD0C4BC),
                  ),
                ),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              );
            }),
            ChoiceChip(
              label: const Text('Custom'),
              selected: _isCustomDose,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _isCustomDose = true;
                  });
                  final dose = double.tryParse(_doseController.text) ?? 1.0;
                  _openDosePicker(
                    unit: _selectedUnit,
                    currentDose: dose,
                    onDoseChanged: (newDose) {
                      setState(() {
                        _doseController.text = newDose.toStringAsFixed(newDose == newDose.toInt() ? 0 : 2);
                      });
                    },
                  );
                }
              },
              selectedColor: const Color(0xFF67594E),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: _isCustomDose ? Colors.white : const Color(0xFF4D453F),
                fontSize: 13,
                fontWeight: _isCustomDose ? FontWeight.bold : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _isCustomDose ? const Color(0xFF67594E) : const Color(0xFFD0C4BC),
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isCustomDose) ...[
          _buildDoseInputRow(showUnitSelector: showUnitSelector),
        ] else ...[
          if (showUnitSelector) _buildUnitSelectorOnly(),
        ],
      ],
    );
  }

  Widget _buildUnitSelectorOnly() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EDE9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Unit: ', style: TextStyle(fontSize: 13, color: Color(0xFF4D453F))),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedUnit,
              onChanged: (val) {
                if (val != null && val != _selectedUnit) {
                  setState(() {
                    _selectedUnit = val;
                    _doseController.clear();
                  });
                }
              },
              items: ['mg', 'mcg', 'pumps', 'applicator']
                  .map((u) => DropdownMenuItem(
                        value: u,
                        child: Text(u, style: const TextStyle(fontSize: 13)),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoseInputRow({required bool showUnitSelector}) {
    final dose = double.tryParse(_doseController.text) ?? 1.0;
    return GestureDetector(
      onTap: () => _openDosePicker(
        unit: _selectedUnit,
        currentDose: dose,
        onDoseChanged: (newDose) {
          setState(() {
            _doseController.text = newDose.toStringAsFixed(newDose == newDose.toInt() ? 0 : 2);
          });
        },
      ),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFF2EDE9),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _doseController.text,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1D1B1A)),
            ),
            Row(
              children: [
                if (showUnitSelector)
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedUnit,
                      onChanged: (val) {
                        if (val != null && val != _selectedUnit) {
                          setState(() {
                            _selectedUnit = val;
                            _doseController.clear();
                          });
                        }
                      },
                      items: ['mg', 'mcg', 'pumps', 'applicator']
                          .map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 13))))
                          .toList(),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      _selectedUnit,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4D453F)),
                    ),
                  ),
                const Icon(Icons.arrow_drop_down, color: Color(0xFF4D453F)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencySelector() {
    final frequencies = ['Daily', 'Twice weekly', 'Weekly', 'As needed'];
    final lowerFreq = _selectedFrequency.toLowerCase();
    final isTwice = lowerFreq.contains('twice');
    final isWeekly = lowerFreq.contains('weekly') && !isTwice;

    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: frequencies.map((freq) {
            final isSelected = _selectedFrequency == freq;
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
              selectedColor: const Color(0xFF67594E),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF4D453F),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF67594E) : const Color(0xFFD0C4BC),
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            );
          }).toList(),
        ),
        if (isTwice || isWeekly) ...[
          const SizedBox(height: 14),
          Text(
            isTwice
                ? 'Select Scheduled Days (Required: 2 days)'
                : 'Select Scheduled Day (Required: 1 day)',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF67594E),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(7, (index) {
              final weekday = index + 1; // 1 = Mon ... 7 = Sun
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
                        if (newSelected.length > 1) {
                          newSelected.remove(weekday);
                        }
                      } else {
                        if (newSelected.length >= 2) {
                          newSelected.removeAt(0);
                        }
                        newSelected.add(weekday);
                      }
                    }
                    newSelected.sort();
                    _selectedWeekdays = newSelected;
                  });
                },
                selectedColor: const Color(0xFF67594E),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF4D453F),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF67594E) : const Color(0xFFD0C4BC),
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
      ],
    );
  }

  Widget _buildNotesInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2EDE9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: _notesController,
        maxLines: 3,
        style: const TextStyle(fontSize: 13),
        decoration: const InputDecoration(
          hintText: 'Any details for your doctor...',
          hintStyle: TextStyle(color: Color(0xFFA8A29E)),
          contentPadding: EdgeInsets.all(16),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildQuickAddRow() {
    final quickAddDrugs = ref.watch(hrtQuickAddProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Quick add',
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1D1B1A),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickAddDrugs.map((drug) {
            return QuickAddChip(
              label: drug.name,
              onTap: () => _applyQuickAdd(drug),
              isSelected: _selectedQuickAddName == drug.name,
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Info note shown when a combined product is selected.
  Widget _buildCombinedProductNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF67594E).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF67594E).withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF67594E), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This product contains both oestrogen and progestogen — no separate progestogen entry needed.',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: const Color(0xFF4D453F),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuickAddChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  const QuickAddChip({
    super.key,
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF67594E) : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? const Color(0xFF67594E) : const Color(0xFFE8E0F0),
          ),
          boxShadow: isSelected
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.primary,
          ),
        ),
      ),
    );
  }
}
