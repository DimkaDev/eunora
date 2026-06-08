import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/utils/animation_system.dart';
import 'package:eunora/core/theme/app_theme.dart';
import '../widgets/onboarding_header.dart';

class ContraceptionPage extends ConsumerStatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  const ContraceptionPage({super.key, this.onNext, this.onBack});

  @override
  ConsumerState<ContraceptionPage> createState() => _ContraceptionPageState();
}

class _ContraceptionPageState extends ConsumerState<ContraceptionPage> {
  bool? _isUsingContraception;
  String _selectedType = 'Progestin-only pill';
  final TextEditingController _brandController = TextEditingController(text: 'Cerazette');
  final TextEditingController _doseQuantityController = TextEditingController();
  final TextEditingController _doseUnitController = TextEditingController(text: 'mcg');
  String _selectedContraceptionUnit = 'mcg';

  final List<String> _types = [
    'Combination pill',
    'Progestin-only pill',
    'Copper IUD',
    'Hormonal IUD',
    'Subdermal implant',
    'Injection',
    'Barrier method',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedContraceptionUnit = _doseUnitController.text.isEmpty ? 'mcg' : _doseUnitController.text;
  }

  @override
  void dispose() {
    _brandController.dispose();
    _doseQuantityController.dispose();
    _doseUnitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF8F6), // background
      body: SafeArea(
        child: Column(
          children: [
            OnboardingHeader(
              currentStep: 6,
              subtitle: 'CONTRACEPTION',
              onBack: widget.onBack,
              onSkip: () => _showInfoDialog(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildQuestion(),
                    if (_isUsingContraception == true) ...[
                      const SizedBox(height: 32),
                      _buildDetailsSection(),
                    ],
                    const SizedBox(height: 48),
                    _buildInfoText(),
                    const SizedBox(height: 48),
                    _buildFooterButtons(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contraception',
          style: GoogleFonts.notoSerif(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1D1B1A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '(Optional - but helpful for understanding your health)',
          style: GoogleFonts.manrope(
            fontSize: 16,
            color: const Color(0xFF1D1B1A).withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Are you currently using any form of contraception?',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1D1B1A),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildChoiceCard(
                label: 'Yes',
                isSelected: _isUsingContraception == true,
                icon: Icons.check,
                onTap: () => setState(() => _isUsingContraception = true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChoiceCard(
                label: 'No',
                isSelected: _isUsingContraception == false,
                icon: Icons.close,
                onTap: () => setState(() => _isUsingContraception = false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChoiceCard({
    required String label,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Bounceable(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF67594E).withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF67594E) : const Color(0xFFE7E1DF),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF67594E) : const Color(0xFFE7E1DF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF4D453F),
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1B1A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepLabel('1', 'WHAT TYPE?'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _types.map((type) {
            final isSelected = _selectedType == type;
            return ChoiceChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedType = type);
              },
              selectedColor: const Color(0xFF67594E),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF4D453F),
                fontSize: 14,
                fontFamily: 'Manrope',
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF67594E) : const Color(0xFF7F756E).withOpacity(0.3),
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        _buildStepLabel('2', 'BRAND NAME', optional: true),
        const SizedBox(height: 16),
        _buildTextField(_brandController, 'e.g., Yasmin, Mirena'),
        const SizedBox(height: 32),
        _buildStepLabel('3', 'DOSE', optional: true),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildTextField(_doseQuantityController, 'Quantity (e.g., 30)'),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: _buildDropdownField(
                value: _selectedContraceptionUnit,
                items: const ['mcg', 'mg', 'tablets', 'injections', 'implants'],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedContraceptionUnit = val;
                      _doseUnitController.text = val;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7F756E).withOpacity(0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          isExpanded: true,
          style: const TextStyle(fontSize: 18, fontFamily: 'Manrope', color: Color(0xFF1D1B1A)),
          items: items
              .map((u) => DropdownMenuItem(
                    value: u,
                    child: Text(u),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildStepLabel(String number, String label, {bool optional = false}) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFFEDDDF5), // secondary-container
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C6074),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Color(0xFF1D1B1A),
          ),
        ),
        if (optional) ...[
          const SizedBox(width: 4),
          Text(
            '(optional)',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF1D1B1A).withOpacity(0.4),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 18, fontFamily: 'Manrope'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: const Color(0xFF1D1B1A).withOpacity(0.2)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: const Color(0xFF7F756E).withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: const Color(0xFF7F756E).withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF67594E), width: 2),
        ),
      ),
    );
  }

  Widget _buildInfoText() {
    return const Center(
      child: Text(
        'Understanding your hormonal balance helps us curate a better experience for your unique journey.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Noto Serif',
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: Color(0xFF4D453F),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildFooterButtons(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: () {
            if (widget.onNext != null) {
              widget.onNext!();
            } else {
              context.push('/weight');
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
            if (widget.onNext != null) {
              widget.onNext!();
            } else {
              context.push('/weight');
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
                  'Contraception during Transition',
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
              'Contraception needs change during perimenopause. Understanding your current method helps map hormonal influence.',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF4D453F),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoRow(
              icon: Icons.pregnant_woman,
              title: 'Pregnancy Risk',
              desc: 'Even with irregular periods, pregnancy is still possible during perimenopause until menopause is clinically confirmed.',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.layers,
              title: 'Hormone Levels',
              desc: 'Hormonal contraceptives (like pills or IUDs) can mask or manage perimenopause symptoms.',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.sync_alt,
              title: 'Transition Options',
              desc: 'Discussing non-hormonal versus hormonal options with your doctor can help you find the best balance.',
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
