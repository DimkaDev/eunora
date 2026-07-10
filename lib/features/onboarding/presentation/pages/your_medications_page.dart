import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/onboarding_header.dart';
import '../widgets/medication_list_item.dart';
import '../providers/medications_provider.dart';
import '../../domain/models/medication.dart';
import '../widgets/add_medication_modal.dart';

class YourMedicationsPage extends ConsumerWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  const YourMedicationsPage({super.key, this.onNext, this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(medicationsProvider);
    final notifier = ref.read(medicationsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFFEF8F6),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                OnboardingHeader(
                  currentStep: 2,
                  subtitle: 'MEDICATIONS',
                  onBack: () {
                    if (onBack != null) {
                      onBack!();
                    } else if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/menopause-stage');
                    }
                  },
                  onSkip: () => _showInfoDialog(context),
                ),
                if (state.error != null) _buildErrorBanner(context, ref, state.error!),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Your Medications',
                          style: GoogleFonts.notoSerif(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1D1B1A),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Track your current hormone therapy and other medications to identify patterns.',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            color: const Color(0xFF1D1B1A).withOpacity(0.6),
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
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddMedicationModal(initialData: medication),
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
          builder: (context) => const AddMedicationModal(),
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
                    if (hasMedications) {
                      if (onNext != null) {
                        onNext!();
                      } else {
                        context.push('/symptom-logging');
                      }
                    } else {
                      ref.read(medicationsProvider.notifier).setError(
                        'Please select or add a medication to continue, or tap Skip if you are not on HRT.'
                      );
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
                      context.push('/symptom-logging');
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
                  'HRT & Medications Info',
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
              'Tracking your medications and hormone replacement therapy (HRT) is crucial for identifying patterns and managing your menopause symptoms safely.',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF4D453F),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoRow(
              icon: Icons.science,
              title: 'Hormone Replacement Therapy (HRT)',
              desc: 'Includes estrogen (patches, gels, pills), progesterone, or combination therapy prescribed to relieve symptoms.',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.health_and_safety,
              title: 'Why We Track',
              desc: 'Different types, doses, and delivery methods have varied absorption rates and impacts on your body.',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.warning_amber_rounded,
              title: 'Safety First',
              desc: 'We always recommend reviewing your medication routine and symptoms with your healthcare provider.',
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
