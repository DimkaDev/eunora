import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import '../widgets/onboarding_header.dart';
import '../providers/onboarding_profile_provider.dart';

class LifestyleHabitsPage extends ConsumerStatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  const LifestyleHabitsPage({super.key, this.onNext, this.onBack});

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(onboardingProfileProvider);
      if (profile != null) {
        setState(() {
          _smokingStatus = profile.smokingStatus ?? 'Never';
          _alcoholFrequency = profile.alcoholFrequency ?? 'Rarely';
          _sleepHours = profile.sleepHours ?? 7;
          _exerciseFrequency = profile.exerciseFrequency ?? '3-4x/week';
          _caffeineIntake = profile.caffeineIntake ?? 'Moderate';
        });
      }
    });
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
                OnboardingHeader(
                  currentStep: 8,
                  subtitle: 'LIFESTYLE',
                  onBack: widget.onBack,
                  onSkip: () => _showInfoDialog(context),
                ),
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
        Text(
          'Your Lifestyle Baseline',
          style: GoogleFonts.notoSerif(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1D1B1A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Help us understand your baseline. This identifies lifestyle patterns that may correlate with your symptoms.',
          style: GoogleFonts.manrope(
            fontSize: 16,
            color: const Color(0xFF1D1B1A).withOpacity(0.6),
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
                    ref.read(onboardingProfileProvider.notifier).updateProfile((p) => p.copyWith(
                      smokingStatus: _smokingStatus,
                      alcoholFrequency: _alcoholFrequency,
                      sleepHours: _sleepHours,
                      exerciseFrequency: _exerciseFrequency,
                      caffeineIntake: _caffeineIntake,
                    ));
                    if (widget.onNext != null) {
                      widget.onNext!();
                    } else {
                      context.push('/active-setup');
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
                    ref.read(onboardingProfileProvider.notifier).updateProfile((p) => p.copyWith(
                      smokingStatus: null,
                      alcoholFrequency: null,
                      sleepHours: null,
                      exerciseFrequency: null,
                      caffeineIntake: null,
                    ));
                    if (widget.onNext != null) {
                      widget.onNext!();
                    } else {
                      context.push('/active-setup');
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
                  'Lifestyle Habits Info',
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
              'Daily routines have a profound impact on how you experience and manage menopause symptoms.',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF4D453F),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoRow(
              icon: Icons.restaurant,
              title: 'Nutrition & Diet',
              desc: 'Balanced meals rich in calcium and low in triggers (like sugar or alcohol) help stabilize energy and mood.',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.bedtime,
              title: 'Sleep Hygiene',
              desc: 'Quality sleep supports hormone balance, cognitive clarity, and symptom recovery.',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.fitness_center,
              title: 'Physical Activity',
              desc: 'Strength training and cardio help maintain bone density, improve sleep, and regulate mood.',
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
