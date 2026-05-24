import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/utils/animation_system.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  int _resendSeconds = 45;
  Timer? _timer;
  bool _isLoading = false;
  String? _errorText;
  String? _infoText;

  @override
  void initState() {
    super.initState();
    _sendVerificationEmail();
    _startTimer();
  }

  void _sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        setState(() {
          _infoText = "Verification link sent successfully.";
        });
      }
    } catch (e) {
      setState(() {
        _errorText = "Could not send verification email: ${e.toString()}";
      });
    }
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'your email';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
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
                      'We sent a verification link to $email.\nPlease check your inbox and click the link to activate your account.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: const Color(0xFF3A3A3A).withOpacity(0.8),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (_infoText != null && _errorText == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _infoText!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (_errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _errorText!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: const Color(0xFFBA1A1A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
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
            'Eunora',
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
      child: Bounceable(
        onTap: _isLoading
            ? null
            : () async {
                setState(() {
                  _isLoading = true;
                  _errorText = null;
                  _infoText = null;
                });
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await user.reload();
                    final updatedUser = FirebaseAuth.instance.currentUser;
                    if (updatedUser != null && updatedUser.emailVerified) {
                      if (mounted) {
                        context.push('/account-confirmed');
                      }
                    } else {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                          _errorText = "Your email has not been verified yet. Please check your inbox and click the link.";
                        });
                      }
                    }
                  } else {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                        _errorText = "No user currently signed in.";
                      });
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                      _errorText = "Error verifying email: ${e.toString()}";
                    });
                  }
                }
              },
        child: IgnorePointer(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'I Have Verified My Email',
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
          "Didn't receive the link?",
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: const Color(0xFF4D453F),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _resendSeconds == 0
              ? () {
                  _sendVerificationEmail();
                  setState(() => _resendSeconds = 45);
                  _startTimer();
                }
              : null,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            side: const BorderSide(color: Color(0xFF9B8B7E)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Resend Link',
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
          onPressed: () => context.go('/signup'),
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
