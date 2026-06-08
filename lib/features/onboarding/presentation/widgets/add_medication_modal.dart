import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/medication.dart';
import '../providers/medications_provider.dart';

class AddMedicationModal extends ConsumerStatefulWidget {
  final dynamic initialData; // Can be Medication for edit or String for prefill name

  const AddMedicationModal({super.key, this.initialData});

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
  
  bool _showDropdown = false;
  final List<String> _commonHRT = ['Estradiol', 'Estradot', 'Estrogen Gel', 'Utrogestan', 'Femoston'];
  List<String> _filteredMeds = [];
  bool _isCustomDose = false;

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

      final presets = _getDosePresets(med.type);
      final formattedDose = med.dose.toStringAsFixed(med.dose == med.dose.toInt() ? 0 : 2);
      if (!presets.contains(formattedDose)) {
        _isCustomDose = true;
      }
    } else if (widget.initialData is String) {
      _nameController.text = widget.initialData as String;
    }

    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    final query = _nameController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _showDropdown = false;
        _filteredMeds = [];
      });
      return;
    }

    final filtered = _commonHRT.where((m) => m.toLowerCase().contains(query)).toList();
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
      return [12.5, 25.0, 37.5, 50.0, 62.5, 75.0, 87.5, 100.0, 112.5, 125.0, 150.0, 175.0, 200.0, 250.0];
    } else if (u == 'mg') {
      return [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 10.0, 20.0, 50.0, 100.0, 150.0, 200.0, 300.0, 400.0];
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
                      Navigator.pop(context);
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
                    onDoseChanged(doses[index]);
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
      final medication = Medication(
        id: widget.initialData is Medication ? (widget.initialData as Medication).id : null,
        name: _nameController.text,
        type: _selectedType,
        dose: double.tryParse(_doseController.text) ?? 0,
        unit: _selectedUnit,
        frequency: _selectedFrequency,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (widget.initialData is Medication) {
        ref.read(medicationsProvider.notifier).updateMedication(medication);
      } else {
        ref.read(medicationsProvider.notifier).addMedication(medication);
      }

      context.pop();
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
                    const SizedBox(height: 32),
                    
                    // Name Input
                    _buildSectionHeader('Medication Name'),
                    const SizedBox(height: 8),
                    _buildNameInput(),
                    
                    if (_showDropdown) ...[
                      const SizedBox(height: 8),
                      _buildSearchDropdown(),
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
                    _buildSectionHeader('Frequency'),
                    const SizedBox(height: 8),
                    _buildFrequencySelector(),
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

  Widget _buildSearchDropdown() {
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
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'COMMON HRT',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFFA8A29E),
                letterSpacing: 1.0,
              ),
            ),
          ),
          ..._filteredMeds.map((name) => ListTile(
            leading: Icon(Icons.medication, color: AppTheme.primary.withOpacity(0.4)),
            title: Text(name, style: const TextStyle(fontSize: 14)),
            onTap: () {
              _nameController.text = name;
              setState(() => _showDropdown = false);
            },
          )),
        ],
      ),
    );
  }

  Widget _buildTypeSelection() {
    final types = [
      MedicationType.patch,
      MedicationType.pill,
      MedicationType.gel,
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
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
          if (type == MedicationType.gel) {
            _selectedUnit = 'pumps';
            _doseController.text = '1';
          } else if (type == MedicationType.patch) {
            _selectedUnit = 'mcg';
            _doseController.text = '50';
          } else if (type == MedicationType.pill) {
            _selectedUnit = 'mg';
            _doseController.text = '1';
          } else {
            _selectedUnit = 'mg';
            _doseController.text = '1';
          }
          _isCustomDose = false;
        });
      },
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
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'rectangle': return Icons.rectangle_outlined;
      case 'pill': return Icons.medication;
      case 'clean_hands': return Icons.clean_hands;
      default: return Icons.more_horiz;
    }
  }

  Widget _buildDoseSelector() {
    final presets = _getDosePresets(_selectedType);
    final currentDoseStr = _doseController.text;
    final showUnitSelector = _selectedType == MedicationType.other;
    
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
                if (val != null) {
                  setState(() => _selectedUnit = val);
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
                        if (val != null) {
                          setState(() {
                            _selectedUnit = val;
                            final doses = _getAvailableDoses(val);
                            _doseController.text = doses[0].toStringAsFixed(doses[0] == doses[0].toInt() ? 0 : 2);
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: frequencies.map((freq) {
        final isSelected = _selectedFrequency == freq;
        return ChoiceChip(
          label: Text(freq),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedFrequency = freq);
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
}
