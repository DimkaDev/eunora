import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/onboarding_header.dart';
import '../widgets/medication_list_item.dart';
import '../providers/medications_provider.dart';
import '../../domain/models/medication.dart';

class YourMedicationsPage extends ConsumerWidget {
  const YourMedicationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(medicationsProvider);
    final notifier = ref.read(medicationsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                OnboardingHeader(
                  currentStep: 2,
                  onBack: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/menopause-stage');
                    }
                  },
                ),
                if (state.error != null) _buildErrorBanner(context, ref, state.error!),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          'Your Medications',
                          style: TextStyle(
                            fontFamily: 'Noto Serif',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF231A11),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Track your current hormone therapy and other medications to identify patterns.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF78716C),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'YOUR CURRENT LIST',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D1B1A),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (state.medications.isEmpty)
                          _buildEmptyState(context)
                        else
                          _buildMedicationList(context, state.medications, notifier),
                        const SizedBox(height: 24),
                        _buildAddButton(context),
                        const SizedBox(height: 16),
                        _buildQuickAddSection(context, notifier),
                        const SizedBox(height: 48),
                        _buildZenScene(),
                        const SizedBox(height: 120), // Space for footer
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildFooter(context, ref, state.medications.isNotEmpty),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, WidgetRef ref, String error) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8A89B),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PLEASE ADD MEDICATION',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "It looks like you haven't added any medications yet. Please add your current HRT or other medications to continue.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          style: BorderStyle.solid, // Dash effect would require custom painter
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

  Widget _buildMedicationList(BuildContext context, List<Medication> medications, Medications notifier) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: medications.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final medication = medications[index];
        return MedicationListItem(
          medication: medication,
          onDelete: () => notifier.removeMedication(medication.id),
          onEdit: () {
            // TODO: Open edit page
            context.push('/add-medication', extra: medication);
          },
        );
      },
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/add-medication'),
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
              'Add New Medication',
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

  Widget _buildQuickAddSection(BuildContext context, Medications notifier) {
    final commonMeds = ['Estradiol', 'Utrogestan', 'Femoston'];

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
            'QUICK START COMMON HRT',
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

  Widget _buildQuickAddChip(BuildContext context, String name, Medications notifier) {
    return InkWell(
      onTap: () {
        // Open add page with prefilled name
        context.push('/add-medication', extra: name);
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

  Widget _buildZenScene() {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: const NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuDtWL4AykE8V9JCMtemWAbCNllXKTcSNg47QWMheLDHZ4Ap-vOtx3kAoKkAEIW9e5eeJVq2M4H774lhoFEIUvzo8z29ooU7l-cU6_ERBR3YPD3up-RlLb-b1ZV3X0CWGr3cGgJNpA5rKOPdgolcmOL7ZQb_FirKRLorCvY-4U2ryEGjwy-dVQ_8MacoVKwN5OIFy7RH37kiEL36gpWiJQlt1t8-VR_F_AR4kIhuEratpyuGuDTdhtqb6ZxdpFyeKx9-OiY75fMyL6c'),
            fit: BoxFit.cover,
            colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
            opacity: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref, bool hasMedications) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F5F0).withOpacity(0.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (hasMedications) {
                    context.push('/symptom-logging');
                  } else {
                    ref.read(medicationsProvider.notifier).setError(
                      'Please select or add a medication to continue, or tap Skip if you are not on HRT.'
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                  shadowColor: AppTheme.primary.withOpacity(0.2),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.push('/home'),
              child: const Text(
                'Skip for now',
                style: TextStyle(
                  color: Color(0xFFA8A29E),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
