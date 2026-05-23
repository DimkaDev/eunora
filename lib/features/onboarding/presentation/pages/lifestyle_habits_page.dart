import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/onboarding_header.dart';

class LifestyleHabitsPage extends ConsumerStatefulWidget {
  const LifestyleHabitsPage({super.key});

  @override
  ConsumerState<LifestyleHabitsPage> createState() => _LifestyleHabitsPageState();
}

class _LifestyleHabitsPageState extends ConsumerState<LifestyleHabitsPage> {
  String _smokingStatus = 'Never';
  String _alcoholFrequency = 'Rarely';
  double _sleepHours = 7;
  String _exerciseFrequency = '3-4x/week';
  String _caffeineIntake = 'Moderate';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF8F6), // background
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const OnboardingHeader(currentStep: 9), // Step 10 of 11
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildIntro(),
                        const SizedBox(height: 32),
                        _buildChoiceSection(
                          label: 'Do you smoke?',
                          options: ['Never', 'Former', 'Occasional', 'Daily', 'Prefer not to say'],
                          selected: _smokingStatus,
                          onSelected: (val) => setState(() => _smokingStatus = val),
                        ),
                        const SizedBox(height: 16),
                        _buildChoiceSection(
                          label: 'How often do you drink alcohol?',
                          options: ['Rarely', 'Occasionally', 'Regularly', 'Daily', 'Prefer not to say'],
                          selected: _alcoholFrequency,
                          onSelected: (val) => setState(() => _alcoholFrequency = val),
                        ),
                        const SizedBox(height: 16),
                        _buildSleepCard(),
                        const SizedBox(height: 16),
                        _buildChoiceSection(
                          label: 'How often do you exercise?',
                          options: ['Rarely/never', '1-2x/week', '3-4x/week', 'Daily'],
                          selected: _exerciseFrequency,
                          onSelected: (val) => setState(() => _exerciseFrequency = val),
                        ),
                        const SizedBox(height: 16),
                        _buildCaffeineGrid(),
                        const SizedBox(height: 160), // Footer space
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

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Lifestyle Baseline',
          style: TextStyle(
            fontFamily: 'Noto Serif',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D1B1A),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Help us understand your baseline. This identifies lifestyle patterns that may correlate with your symptoms.',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            color: const Color(0xFF4D453F),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceSection({
    required String label,
    required List<String> options,
    required String selected,
    required Function(String) onSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD0C4BC).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Color(0xFF67594E),
            ),
          ),
          const SizedBox(height: 24),
          Column(
            children: options.map((opt) {
              final isSelected = selected == opt;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => onSelected(opt),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEDDDF5) : const Color(0xFFF8F2F0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF67594E).withOpacity(0.3) : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          opt,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: const Color(0xFF1D1B1A),
                          ),
                        ),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? const Color(0xFF67594E) : const Color(0xFFD0C4BC),
                              width: isSelected ? 6 : 2,
                            ),
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD0C4BC).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TYPICAL SLEEP PER NIGHT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Color(0xFF67594E),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepperButton(Icons.remove, () {
                if (_sleepHours > 0) setState(() => _sleepHours -= 0.5);
              }),
              const SizedBox(width: 32),
              Column(
                children: [
                  Text(
                    _sleepHours.toString().replaceAll('.0', ''),
                    style: const TextStyle(
                      fontFamily: 'Noto Serif',
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1B1A),
                    ),
                  ),
                  const Text(
                    'HOURS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4D453F),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 32),
              _buildStepperButton(Icons.add, () {
                if (_sleepHours < 24) setState(() => _sleepHours += 0.5);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: Color(0xFFF8F2F0),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF67594E), size: 24),
      ),
    );
  }

  Widget _buildCaffeineGrid() {
    final List<Map<String, dynamic>> items = [
      {'label': 'None', 'icon': Icons.water_drop},
      {'label': 'Moderate', 'icon': Icons.coffee},
      {'label': 'High', 'icon': Icons.bolt},
      {'label': 'Privacy', 'icon': Icons.visibility_off},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD0C4BC).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TYPICAL DAILY CAFFEINE INTAKE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Color(0xFF67594E),
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: items.map((item) {
              final isSelected = _caffeineIntake == item['label'];
              return GestureDetector(
                onTap: () => setState(() => _caffeineIntake = item['label']),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEDDDF5) : const Color(0xFFF8F2F0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF67594E).withOpacity(0.3) : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item['icon'],
                        color: const Color(0xFF67594E),
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['label'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? const Color(0xFF67594E) : const Color(0xFF1D1B1A),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => context.push('/active-setup'),
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
              onPressed: () => context.push('/active-setup'),
              child: const Text(
                'SKIP THIS STEP',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4D453F),
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
