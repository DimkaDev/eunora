import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:eunora/core/utils/animation_system.dart';
import '../providers/other_medications_provider.dart';
import '../../domain/models/other_medication.dart';
import '../widgets/onboarding_header.dart';
import '../widgets/other_medication_list_item.dart';

class OtherMedicationsPage extends ConsumerWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  const OtherMedicationsPage({super.key, this.onNext, this.onBack});

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
                OnboardingHeader(
                  currentStep: 4,
                  subtitle: 'OTHER MEDICATIONS',
                  onBack: onBack,
                  onSkip: () => _showInfoDialog(context),
                ),
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
                            if (state.isTakingAnythingElse) ...[
                              _buildCurrentListHeader(),
                              const SizedBox(height: 16),
                              if (state.medications.isEmpty)
                                _buildEmptyState(context)
                              else
                                _buildMedicationList(context, state.medications, notifier),
                              const SizedBox(height: 24),
                              _buildAddButton(context),
                              const SizedBox(height: 16),
                              _buildQuickAddSection(context, notifier),
                              const SizedBox(height: 16),
                              _buildNoOtherMedsLink(notifier),
                            ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          textAlign: TextAlign.start,
          text: TextSpan(
            style: GoogleFonts.notoSerif(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D1B1A), // on-surface
              height: 1.2,
            ),
            children: [
              const TextSpan(text: 'Other Medications & '),
              TextSpan(
                text: 'Supplements',
                style: GoogleFonts.notoSerif(
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF67594E),
                  fontWeight: FontWeight.bold,
                ), // primary
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Let's keep track of your overall wellness routine to ensure holistic care.",
          style: GoogleFonts.manrope(
            fontSize: 16,
            color: const Color(0xFF1D1B1A).withOpacity(0.6),
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
          AnimatedSwitch(
            value: value,
            onChanged: notifier.toggleIsTakingAnythingElse,
            activeColor: const Color(0xFF817266),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentListHeader() {
    return const Text(
      'YOUR CURRENT LIST',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1D1B1A),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE7E5E4),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.medication, color: Color(0xFFD6D3D1), size: 30),
          ),
          const SizedBox(height: 12),
          const Text(
            'No medications added yet.',
            style: TextStyle(
              color: Color(0xFFA8A29E),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationList(BuildContext context, List<OtherMedication> medications, OtherMedicationsNotifier notifier) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: medications.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final med = medications[index];
        return OtherMedicationListItem(
          medication: med,
          onDelete: () => notifier.removeMedication(med.id),
          onEdit: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddOtherMedicationModal(medication: med),
            );
          },
        );
      },
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primary.withOpacity(0.2), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle, color: AppTheme.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              'Add Medication or Supplement',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddSection(BuildContext context, OtherMedicationsNotifier notifier) {
    final commonMeds = ['Vitamin D', 'Calcium', 'Magnesium', 'Ibuprofen', 'Antidepressant'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E0F0).withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8E0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QUICK START COMMON CHOICES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6C6074),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: commonMeds.map((name) => _buildQuickAddChip(context, name, notifier)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddChip(BuildContext context, String name, OtherMedicationsNotifier notifier) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AddOtherMedicationModal(initialName: name),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          name,
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildNoOtherMedsLink(OtherMedicationsNotifier notifier) {
    return Center(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 10,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFFEF8F6).withOpacity(0),
                  const Color(0xFFFEF8F6),
                ],
              ),
            ),
          ),
          Container(
            color: const Color(0xFFFEF8F6),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 ElevatedButton(
                  onPressed: () {
                    if (onNext != null) {
                      onNext!();
                    } else {
                      context.push('/health-conditions');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF67594E),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    if (onNext != null) {
                      onNext!();
                    } else {
                      context.push('/health-conditions');
                    }
                  },
                  child: Text(
                    'SKIP THIS STEP',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4D453F).withOpacity(0.6),
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFEF8F6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Supplements & Medications',
                  style: GoogleFonts.notoSerif(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1D1B1A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF9B8B7E)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Vitamins, minerals, and herbal supplements play a significant role in your overall wellbeing during menopause.',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF4D453F),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoRow(
              icon: Icons.spa,
              title: 'Wellness Supplements',
              desc: 'Calcium, Vitamin D, and Magnesium are often used to support bone health and muscle relaxation.',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.loop,
              title: 'Potential Interactions',
              desc: 'Some over-the-counter supplements can interact with hormonal treatments. Keeping a unified log helps ensure your safety.',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.calendar_today,
              title: 'Daily Reminders',
              desc: 'Setting reminders ensures consistent intake, maximizing the effectiveness of your wellness regimen.',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Got it',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFF1D1B1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: const Color(0xFF4D453F),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AddOtherMedicationModal extends ConsumerStatefulWidget {
  final OtherMedication? medication;
  final String? initialName;

  const AddOtherMedicationModal({super.key, this.medication, this.initialName});

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
    _nameController = TextEditingController(text: widget.medication?.name ?? widget.initialName);
    _doseController = TextEditingController(text: widget.medication?.dose);
    _selectedCategory = widget.medication?.category ?? _getDefaultCategory(widget.initialName);
    _selectedFrequency = widget.medication?.frequency ?? 'Daily';
    _hasReminder = widget.medication?.hasReminder ?? false;
  }

  String? _getDefaultCategory(String? name) {
    if (name == null) return null;
    final lowerName = name.toLowerCase();
    if (lowerName.contains('vitamin')) return 'Vitamins';
    if (lowerName.contains('calcium') || lowerName.contains('magnesium')) return 'Minerals';
    if (lowerName.contains('herbal') || lowerName.contains('herb')) return 'Herbal';
    if (lowerName.contains('ibuprofen') || lowerName.contains('antidepressant')) return 'Other';
    return null;
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
                        AnimatedSwitch(
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
