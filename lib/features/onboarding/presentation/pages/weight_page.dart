import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/onboarding_header.dart';

class WeightPage extends ConsumerStatefulWidget {
  const WeightPage({super.key});

  @override
  ConsumerState<WeightPage> createState() => _WeightPageState();
}

class _WeightPageState extends ConsumerState<WeightPage> {
  double _weight = 70;
  bool _isMetric = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF8F6), // background
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const OnboardingHeader(currentStep: 8), // Step 9 of 11
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
        children: [
          const Text(
            "What's your current weight?",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Noto Serif',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1B1A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This identifies lifestyle patterns that may correlate with your symptoms.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              color: const Color(0xFF1D1B1A).withOpacity(0.6),
              height: 1.5,
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
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFEF8F6).withOpacity(0),
              const Color(0xFFFEF8F6),
              const Color(0xFFFEF8F6),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => context.push('/lifestyle-habits'),
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
              onPressed: () => context.push('/lifestyle-habits'),
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
}
