import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/medication.dart';
import '../providers/medications_provider.dart';

class AddMedicationPage extends ConsumerStatefulWidget {
  final dynamic initialData; // Can be Medication for edit or String for prefill name

  const AddMedicationPage({super.key, this.initialData});

  @override
  ConsumerState<AddMedicationPage> createState() => _AddMedicationPageState();
}

class _AddMedicationPageState extends ConsumerState<AddMedicationPage> {
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _doseController = TextEditingController(text: '50');
    _notesController = TextEditingController();

    if (widget.initialData is Medication) {
      final med = widget.initialData as Medication;
      _nameController.text = med.name;
      _doseController.text = med.dose.toStringAsFixed(med.dose == med.dose.toInt() ? 0 : 2);
      _notesController.text = med.notes ?? '';
      _selectedType = med.type;
      _selectedUnit = med.unit;
      _selectedFrequency = med.frequency;
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4D453F)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.initialData is Medication ? 'Edit Medication' : 'Add Medication',
          style: const TextStyle(
            fontFamily: 'Noto Serif',
            fontStyle: FontStyle.italic,
            fontSize: 18,
            color: Color(0xFF231A11),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Medication Name'),
                  const SizedBox(height: 8),
                  _buildNameInput(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('How do you take it?'),
                  const SizedBox(height: 12),
                  _buildTypeSelection(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Dose'),
                            const SizedBox(height: 8),
                            _buildDoseInput(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Frequency'),
                            const SizedBox(height: 8),
                            _buildFrequencyDropdown(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 120), // Space for footer
                ],
              ),
            ),
          ),
          if (_showDropdown) _buildSearchDropdown(),
          _buildFooter(),
        ],
      ),
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
        color: const Color(0xFFEEEEEE),
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
    return Positioned(
      top: 100, // Adjust based on layout
      left: 24,
      right: 24,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
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
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.05) : const Color(0xFFFAF9F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFF5F5F4),
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
                color: isSelected ? AppTheme.primary : const Color(0xFF44403C),
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

  Widget _buildDoseInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _doseController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              validator: (value) => value == null || value.isEmpty ? '?' : null,
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: const Color(0xFFD6D3D1),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedUnit,
              onChanged: (val) => setState(() => _selectedUnit = val!),
              items: ['mg', 'mcg', 'pumps', 'applicator']
                  .map((u) => DropdownMenuItem(value: u, child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(u, style: const TextStyle(fontSize: 13)),
                  )))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedFrequency,
          onChanged: (val) => setState(() => _selectedFrequency = val!),
          items: ['Daily', 'Twice weekly', 'Weekly', 'As needed']
              .map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 13))))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildNotesInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
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

  Widget _buildFooter() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          border: Border(top: BorderSide(color: const Color(0xFFF5F5F4))),
        ),
        child: ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            widget.initialData is Medication ? 'Update Medication' : 'Confirm & Add',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
