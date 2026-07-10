import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import '../widgets/onboarding_header.dart';
import '../providers/onboarding_profile_provider.dart';

class WeightPage extends ConsumerStatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  const WeightPage({super.key, this.onNext, this.onBack});

  @override
  ConsumerState<WeightPage> createState() => _WeightPageState();
}

class _WeightPageState extends ConsumerState<WeightPage> {
  double _weight = 70;
  bool _isMetric = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(onboardingProfileProvider);
      if (profile != null) {
        setState(() {
          _weight = profile.weight ?? 70;
          _isMetric = profile.isMetric ?? true;
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
                  currentStep: 7,
                  subtitle: 'WEIGHT',
                  onBack: widget.onBack,
                  onSkip: () => _showInfoDialog(context),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      _buildHeader(),
                      const Spacer(),
                      _buildWeightDisplay(),
                      const SizedBox(height: 40),
                      _buildSlider(),
                      const SizedBox(height: 40),
                      _buildToggle(),
                      const Spacer(flex: 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildStickyFooter(context),
          _buildDecorations(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What's your current weight?",
            style: GoogleFonts.notoSerif(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D1B1A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This identifies lifestyle patterns that may correlate with your symptoms.',
            style: GoogleFonts.manrope(
              fontSize: 16,
              color: const Color(0xFF1D1B1A).withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          _weight.round().toString(),
          style: const TextStyle(
            fontFamily: 'Noto Serif',
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: Color(0xFF67594E),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _isMetric ? 'kg' : 'lbs',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4D453F),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 12,
              activeTrackColor: const Color(0xFFF2EDEA),
              inactiveTrackColor: const Color(0xFFF2EDEA),
              thumbColor: const Color(0xFF67594E),
              overlayColor: const Color(0xFF67594E).withOpacity(0.12),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 16, elevation: 4),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 32),
            ),
            child: Slider(
              value: _weight,
              min: _isMetric ? 40 : 88,
              max: _isMetric ? 150 : 330,
              onChanged: (val) => setState(() => _weight = val),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isMetric ? '40 kg' : '88 lbs',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7F756E), letterSpacing: 1.2),
              ),
              Text(
                _isMetric ? '150 kg' : '330 lbs',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7F756E), letterSpacing: 1.2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7E5),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton('Metric (kg)', _isMetric),
          _buildToggleButton('Imperial (lbs)', !_isMetric),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) return;
          if (label.contains('kg')) {
            _weight = (_weight / 2.20462);
            _isMetric = true;
          } else {
            _weight = (_weight * 2.20462);
            _isMetric = false;
          }
          if (_weight < (label.contains('kg') ? 40 : 88)) _weight = (label.contains('kg') ? 40 : 88);
          if (_weight > (label.contains('kg') ? 150 : 330)) _weight = (label.contains('kg') ? 150 : 330);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF67594E) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF4D453F),
          ),
        ),
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
                      weight: _weight,
                      isMetric: _isMetric,
                    ));
                    if (widget.onNext != null) {
                      widget.onNext!();
                    } else {
                      context.push('/lifestyle-habits');
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
                      weight: null,
                      isMetric: _isMetric,
                    ));
                    if (widget.onNext != null) {
                      widget.onNext!();
                    } else {
                      context.push('/lifestyle-habits');
                    }
                  },
                  child: Text(
                    'SKIP THIS QUESTION',
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

  Widget _buildDecorations() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2DFD0).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDDDF5).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
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
                  'Weight & Menopause Info',
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
              'Metabolic changes during menopause frequently influence body weight and fat distribution.',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF4D453F),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoRow(
              icon: Icons.trending_up,
              title: 'Estrogen & Metabolism',
              desc: 'Lower estrogen levels can slow metabolism and shift fat storage towards the abdominal area.',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.directions_run,
              title: 'Bone & Muscle Health',
              desc: 'Tracking weight alongside muscle mass is essential for preventing osteoporosis and sarcopenia.',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.balance,
              title: 'Body Positivity',
              desc: 'Focusing on overall fitness, energy, and strength is more important than the number on the scale.',
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
