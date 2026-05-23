import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

class ResetPasswordSuccessPage extends StatefulWidget {
  const ResetPasswordSuccessPage({super.key});

  @override
  State<ResetPasswordSuccessPage> createState() => _ResetPasswordSuccessPageState();
}

class _ResetPasswordSuccessPageState extends State<ResetPasswordSuccessPage> {
  int _countdown = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        _timer?.cancel();
        if (mounted) {
          context.go('/signin');
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF8F6),
      body: Stack(
        children: [
          _buildDecorations(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCelebratoryIcon(),
                  const SizedBox(height: 32),
                  _buildMessage(),
                  const SizedBox(height: 32),
                  _buildIllustrationCard(),
                  const SizedBox(height: 48),
                  _buildActionButton(context),
                  const SizedBox(height: 16),
                  _buildCountdownText(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebratoryIcon() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D1B1A).withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  const Color(0xFFD8C9E0).withOpacity(0.3),
                  Colors.transparent,
                  const Color(0xFFD8C9E0).withOpacity(0.3),
                ],
              ),
            ),
          ),
          const Icon(
            Icons.check_circle,
            size: 48,
            color: Color(0xFF43A047),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage() {
    return Column(
      children: [
        Text(
          'Password reset successfully!',
          style: GoogleFonts.notoSerif(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF67594E),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'You can now log in with your new password',
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: const Color(0xFF4D453F),
          ),
        ),
      ],
    );
  }

  Widget _buildIllustrationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D1B1A).withOpacity(0.03),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCd0eOVpVV4NgFzOE9va4Opwk4-0J_RvOR1hcb6-KQMuHLcblUNPUqkYsIQDcZTKEduXYaVYM3vjqQ3QA_tuSCqD0gy8tfqN7urLVrvumHlDGZon6hcdGrhHIZ-yvR_2-U6MEzeWzf6Qjvwq9RTwg-mPANYLON-aC0f8bXyNFgrfUjdazOTnGzdDlxCo5Qnk5CJZgysBarnU7X5EBTCINVlZlzqNJI1SddBV9BOAm08XW8aHmtmcuEha-N03ZQbp7yuluLFoMgft7s',
            fit: BoxFit.cover,
            opacity: const AlwaysStoppedAnimation(0.8),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF67594E), Color(0xFF817266)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF67594E).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => context.go('/signin'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          'Return to Login',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownText() {
    return Text(
      'Redirecting to home in $_countdown seconds...',
      style: GoogleFonts.manrope(
        fontSize: 12,
        color: const Color(0xFF4D453F).withOpacity(0.6),
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildDecorations() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDDDF5).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDAD3).withOpacity(0.15),
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
