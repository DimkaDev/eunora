import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/onboarding_header.dart';

class ContraceptionPage extends ConsumerStatefulWidget {
  const ContraceptionPage({super.key});

  @override
  ConsumerState<ContraceptionPage> createState() => _ContraceptionPageState();
}

class _ContraceptionPageState extends ConsumerState<ContraceptionPage> {
  bool? _isUsingContraception;
  String _selectedType = 'Progestin-only pill';
  final TextEditingController _brandController = TextEditingController(text: 'Cerazette');
  final TextEditingController _doseController = TextEditingController();

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
  void dispose() {
    _brandController.dispose();
    _doseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF8F6), // background
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const OnboardingHeader(currentStep: 7), // Step 8 of 11 (0-indexed 7)
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
                        const SizedBox(height: 120), // Footer space
                      ],
                    ),
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contraception',
          style: TextStyle(
            fontFamily: 'Noto Serif',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D1B1A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '(Optional - but helpful for understanding your health)',
          style: TextStyle(
            fontFamily: 'Manrope',
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
    return GestureDetector(
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
        _buildTextField(_doseController, 'e.g., 30 mcg ethinyl estradiol'),
      ],
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

  Widget _buildStickyFooter(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            TextButton(
              onPressed: () => context.push('/weight'),
              child: const Text(
                'Skip',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF67594E),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => context.push('/weight'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF67594E),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
