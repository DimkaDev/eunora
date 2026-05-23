import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final TextEditingController _codeController = TextEditingController();
  int _resendSeconds = 45;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        const SizedBox(height: 48),
                        _buildIcon(),
                        const SizedBox(height: 24),
                        Text(
                          'Verify Your Email',
                          style: GoogleFonts.notoSerif(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF3A3A3A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'We sent a verification code to sarah@email.com',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: const Color(0xFF3A3A3A).withOpacity(0.8),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 40),
                        _buildCodeInput(),
                        const SizedBox(height: 24),
                        _buildVerifyButton(context),
                        const SizedBox(height: 40),
                        _buildResendSection(),
                        const SizedBox(height: 40),
                        _buildFooter(),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF9B8B7E)),
            onPressed: () => context.pop(),
          ),
          Text(
            'MenoSync',
            style: GoogleFonts.notoSerif(
              fontSize: 20,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xFFF2EDEA),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.mail_outline,
        size: 40,
        color: Color(0xFF9B8B7E),
      ),
    );
  }

  Widget _buildCodeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Enter verification code',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3A3A3A),
            ),
          ),
        ),
        TextField(
          controller: _codeController,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 12,
            color: const Color(0xFF3A3A3A),
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: const Color(0xFFEEEEEE),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF9B8B7E), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF9B8B7E), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
            hintText: '000000',
            hintStyle: GoogleFonts.manrope(
              color: Colors.grey.withOpacity(0.5),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Check your email (spam folder too)',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppTheme.outline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF67594E), Color(0xFF817266)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/account-confirmed'),
          child: Center(
            child: Text(
              'Verify Email',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResendSection() {
    return Column(
      children: [
        Text(
          "Didn't receive the code?",
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: const Color(0xFF4D453F),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _resendSeconds == 0 ? () {
            setState(() => _resendSeconds = 45);
            _startTimer();
          } : null,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            side: const BorderSide(color: Color(0xFF9B8B7E)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Resend Code',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppTheme.primary,
            ),
          ),
        ),
        if (_resendSeconds > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Resend in ${_resendSeconds}s',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppTheme.outline,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          height: 1,
          width: double.infinity,
          color: const Color(0xFFD0C4BC).withOpacity(0.2),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {},
          child: Text(
            'Use a different email',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF9B8B7E),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
