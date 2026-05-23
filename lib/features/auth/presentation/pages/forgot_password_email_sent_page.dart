import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordEmailSentPage extends StatelessWidget {
  final String email;

  const ForgotPasswordEmailSentPage({
    super.key,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF8F6), // surface
      body: Stack(
        children: [
          // Ambient background elements
          _buildDecorations(),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIcon(),
                  const SizedBox(height: 32),
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildResendInfo(),
                  const SizedBox(height: 40),
                  _buildActions(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: const Color(0xFFE7E1DF).withOpacity(0.5), // surface-container-highest
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D1B1A).withOpacity(0.06),
            blurRadius: 48,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Gradient glow
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF67594E).withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const Icon(
            Icons.mark_email_read_outlined,
            size: 48,
            color: Color(0xFF67594E),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Link Sent',
          style: GoogleFonts.notoSerif(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1D1B1A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text.rich(
            TextSpan(
              text: "We've sent a password reset link to ",
              children: [
                TextSpan(
                  text: email,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF67594E),
                  ),
                ),
                const TextSpan(text: ". Please check your inbox and follow the instructions."),
              ],
            ),
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: const Color(0xFF4D453F),
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResendInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F2F0), // surface-container-low
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            "Didn't receive it? Check your spam folder or",
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: const Color(0xFF4D453F),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {},
            child: Text(
              'resend in 60s',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF67594E),
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFF67594E).withOpacity(0.3),
                decorationThickness: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        _buildPrimaryButton(context),
        const SizedBox(height: 16),
        // Adding a hidden way to proceed to OTP for testing purposes if needed
        // Or normally the user would click the link.
        // User asked for 6 digits screen, so I'll add a button to go there manually for now
        // since I don't have an email system.
        TextButton(
          onPressed: () => context.push('/forgot-password-otp'),
          child: Text(
            'Enter code manually',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF67594E).withOpacity(0.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF67594E), Color(0xFF817266)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF67594E).withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => context.go('/signin'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: const StadiumBorder(),
        ),
        child: Text(
          'Back to Login',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
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
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDDDF5).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              right: -100,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2DFD0).withOpacity(0.2),
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
