import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/other_medications_provider.dart';
import '../../domain/models/other_medication.dart';
import '../widgets/onboarding_header.dart';

class OtherMedicationsPage extends ConsumerWidget {
  const OtherMedicationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(otherMedicationsProvider);
    final notifier = ref.read(otherMedicationsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFFEF8F6), // surface
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const OnboardingHeader(currentStep: 5), // Step 6 of 11
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            const SizedBox(height: 24),
                            _buildTitle(),
                            const SizedBox(height: 40),
                            _buildMainToggle(notifier, state.isTakingAnythingElse),
                            const SizedBox(height: 32),
                            if (state.isTakingAnythingElse) _buildCurrentListCard(context, state.medications, notifier),
                            const SizedBox(height: 48),
                            _buildWhyItMattersCard(),
                            const SizedBox(height: 160), // Footer space
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildStickyFooter(context),
        ],
      ),
    );
  }


  Widget _buildTitle() {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontFamily: 'Noto Serif',
              fontSize: 32,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1D1B1A), // on-surface
              height: 1.1,
            ),
            children: [
              TextSpan(text: 'Other Medications & '),
              TextSpan(
                text: 'Supplements',
                style: TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF67594E)), // primary
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Let's keep track of your overall wellness routine to ensure holistic care.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF4D453F), // on-surface-variant
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMainToggle(OtherMedicationsNotifier notifier, bool value) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, // surface-container-lowest
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFD0C4BC).withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Are you taking any other medications or supplements?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1D1B1A),
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: notifier.toggleIsTakingAnythingElse,
            activeColor: const Color(0xFF817266), // primary-container
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentListCard(BuildContext context, List<OtherMedication> medications, OtherMedicationsNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFD0C4BC).withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR CURRENT LIST',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7F756E),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          if (medications.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No items added',
                  style: TextStyle(color: Color(0xFF7F756E), fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            ...medications.map((med) => _buildItemRow(context, notifier, med)),
          
          const SizedBox(height: 32),
          _buildAddButton(context),
          
          const SizedBox(height: 32),
          Center(
            child: TextButton(
              onPressed: () => notifier.toggleIsTakingAnythingElse(false),
              child: const Text(
                "I'm not taking anything else",
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7F756E),
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF7F756E),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, OtherMedicationsNotifier notifier, OtherMedication med) {
    return Dismissible(
      key: Key(med.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => notifier.removeMedication(med.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFBA1A1A), // error
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F2F0), // surface-container-low
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1D1B1A)),
                  ),
                  if (med.dose != null || med.frequency != null)
                    Text(
                      '${med.dose ?? ''}${med.dose != null && med.frequency != null ? ' • ' : ''}${med.frequency ?? ''}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF4D453F)),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF7F756E), size: 20),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => AddOtherMedicationModal(medication: med),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: const Color(0xFF7F756E).withOpacity(0.5), size: 20),
              onPressed: () => notifier.removeMedication(med.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const AddOtherMedicationModal(),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD0C4BC).withOpacity(0.5), style: BorderStyle.solid), // Dashed would be better
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFFF8F2F0).withOpacity(0.5),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF67594E).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Color(0xFF67594E)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add Medication or Supplement',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF67594E)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhyItMattersCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEDDDF5).withOpacity(0.4), // secondary-fixed / 40
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Why this matters?',
                  style: TextStyle(
                    fontFamily: 'Noto Serif',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF655A6E), // secondary
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Some supplements can interact with hormonal treatments. We help you stay safe and balanced.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4D4355), // on-secondary-fixed-variant
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: const DecorationImage(
                image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuDMUQ7DHdjz_vCd2kl8bVsKE4l6-OU12Zt8nCI6t4tfnbmh_gKsjZ3pe_lztKcHB5CVy27RqSoPbocrejtyMkGfJlkPjraVApNUHvLXuv7yZLBY0GnRs9WhlleF6pP63yPEHvuAn-eu0eIG7F5CZK8LDGlND7VjwFrME6mHWpPTnyAFZMzftO2-6xThrMJaqtNcSNjJi3xHGL26_26AfElFFcA9z2WfA7D-IBAEzonPnBLRyRqfBIWWIp9Evt6qTUdnmKeAyROqiyw'),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyFooter(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFEF8F6).withOpacity(0.0),
              const Color(0xFFFEF8F6),
            ],
            stops: const [0.0, 0.4],
          ),
        ),
        child: ElevatedButton(
          onPressed: () => context.push('/health-conditions'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF817266),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            elevation: 8,
            shadowColor: const Color(0xFF817266).withOpacity(0.3),
          ),
          child: const Text(
            'CONTINUE',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 14),
          ),
        ),
      ),
    );
  }
}

class AddOtherMedicationModal extends ConsumerStatefulWidget {
  final OtherMedication? medication;

  const AddOtherMedicationModal({super.key, this.medication});

  @override
  ConsumerState<AddOtherMedicationModal> createState() => _AddOtherMedicationModalState();
}

class _AddOtherMedicationModalState extends ConsumerState<AddOtherMedicationModal> {
  late final TextEditingController _nameController;
  late final TextEditingController _doseController;
  String? _selectedCategory;
  String? _selectedFrequency;
  bool _hasReminder = false;

  final List<String> _categories = ['Vitamins', 'Minerals', 'Herbal', 'Prescription', 'Other'];
  final List<String> _frequencies = ['Daily', 'Twice daily', 'Weekly', 'As needed'];
  final List<String> _suggestions = ['Vitamin D', 'Calcium', 'Magnesium', 'Ibuprofen', 'Antidepressant'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medication?.name);
    _doseController = TextEditingController(text: widget.medication?.dose);
    _selectedCategory = widget.medication?.category;
    _selectedFrequency = widget.medication?.frequency ?? 'Daily';
    _hasReminder = widget.medication?.hasReminder ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final notifier = ref.read(otherMedicationsProvider.notifier);
    if (widget.medication != null) {
      notifier.updateMedication(widget.medication!.copyWith(
        name: name,
        dose: _doseController.text.trim(),
        category: _selectedCategory,
        frequency: _selectedFrequency,
        hasReminder: _hasReminder,
      ));
    } else {
      notifier.addMedication(
        name: name,
        dose: _doseController.text.trim(),
        category: _selectedCategory,
        frequency: _selectedFrequency,
        hasReminder: _hasReminder,
      );
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
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
                  widget.medication != null ? 'Edit Medication' : 'Add Medication',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Track other treatments alongside your daily regimen.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF4D453F)),
                  ),
                  const SizedBox(height: 32),
                  
                  // Name Input
                  _buildLabel('Medication name'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nameController,
                    hint: 'e.g., Vitamin D, Magnesium',
                  ),
                  const SizedBox(height: 24),

                  // Category Selection
                  _buildLabel('Category'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((c) => _buildCategoryChip(c)).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Dose Input
                  _buildLabel('Dose (optional)'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _doseController,
                    hint: 'e.g., 2000 IU, 400 mg',
                  ),
                  const SizedBox(height: 24),

                  // Frequency Selection
                  _buildLabel('Frequency'),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.2,
                    children: _frequencies.map((f) => _buildFrequencyCard(f)).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Reminder Toggle
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F2F0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Set daily reminder',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1D1B1A)),
                              ),
                              Text(
                                "We'll notify you when it's time",
                                style: TextStyle(fontSize: 12, color: const Color(0xFF4D453F).withOpacity(0.8)),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _hasReminder,
                          onChanged: (v) => setState(() => _hasReminder = v),
                          activeColor: const Color(0xFF817266),
                        ),
                      ],
                    ),
                  ),
                  
                  if (widget.medication == null) ...[
                    const SizedBox(height: 40),
                    const Text(
                      'COMMON CHOICES',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7F756E), letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _suggestions.map((s) => _buildSuggestionChip(s)).toList(),
                    ),
                  ],
                  
                  const SizedBox(height: 120), // Bottom padding
                ],
              ),
            ),
          ),

          // Footer Actions
          Container(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 40 + MediaQuery.of(context).viewInsets.bottom),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF8F6),
              border: Border(top: BorderSide(color: Color(0xFFF2EDE9))),
            ),
            child: Column(
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
                    widget.medication != null ? 'SAVE CHANGES' : 'SAVE MEDICATION',
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1D1B1A)),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: const Color(0xFF4D453F).withOpacity(0.4)),
        filled: true,
        fillColor: const Color(0xFFF2EDE9), // surface-container-highest
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = isSelected ? null : category),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEDDDF5) : const Color(0xFFF2EDE9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? const Color(0xFF655A6E).withOpacity(0.2) : Colors.transparent),
        ),
        child: Text(
          category,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? const Color(0xFF6C6074) : const Color(0xFF4D453F),
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencyCard(String frequency) {
    final isSelected = _selectedFrequency == frequency;
    return InkWell(
      onTap: () => setState(() => _selectedFrequency = frequency),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F2F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF817266) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF817266) : const Color(0xFF7F756E),
                  width: isSelected ? 5 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              frequency,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1D1B1A)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String name) {
    return InkWell(
      onTap: () {
        setState(() {
          _nameController.text = name;
        });
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F2F0),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD0C4BC).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 14, color: Color(0xFF67594E)),
            const SizedBox(width: 4),
            Text(
              name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1D1B1A)),
            ),
          ],
        ),
      ),
    );
  }
}
