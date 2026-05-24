import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/services/auth_service.dart';
import 'package:eunora/core/utils/animation_system.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    // Email validation
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _isLoading = false;
        _errorText = 'Please enter a valid email address.';
      });
      return;
    }

    try {
      final auth = ref.read(authServiceProvider);
      await auth.sendPasswordReset(email);
      if (mounted) {
        setState(() => _isLoading = false);
        context.push('/forgot-password-success', extra: email);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorText = e.message ?? "We couldn't find an account associated with this email.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorText = 'An error occurred. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = _errorText != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFEF8F6), // surface
      body: Stack(
        children: [
          // Background decorations
          _buildDecorations(),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildBackButton(),
                  const SizedBox(height: 32),
                  _buildHeader(),
                  const SizedBox(height: 32),
                  if (hasError) _buildErrorBanner(),
                  const SizedBox(height: 24),
                  _buildEmailInput(hasError),
                  const SizedBox(height: 40),
                  _buildSubmitButton(),
                  const SizedBox(height: 24),
                  _buildSupportLink(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: () => context.pop(),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_back, size: 18, color: Color(0xFF67594E)),
            const SizedBox(width: 8),
            Text(
              'Back to Login',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF67594E),
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
          'Reset Password',
          style: GoogleFonts.notoSerif(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1D1B1A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Enter the email associated with your account, and we’ll send you a link to reset your password.',
          style: GoogleFonts.manrope(
            fontSize: 15,
            color: const Color(0xFF4D453F),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDAD6).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBA1A1A).withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 20, color: Color(0xFFBA1A1A)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Email not found. Please check and try again.',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF410002),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailInput(bool hasError) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Email Address',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D1B1A),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE7E1DF), // surface-container-highest
            borderRadius: BorderRadius.circular(100),
            border: hasError ? Border.all(color: const Color(0xFFBA1A1A), width: 1) : null,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D1B1A).withOpacity(0.02),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _emailController,
            enabled: !_isLoading,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.manrope(fontSize: 16, color: const Color(0xFF1D1B1A)),
            decoration: InputDecoration(
              hintText: 'e.g., sarah@example.com',
              hintStyle: GoogleFonts.manrope(
                color: const Color(0xFF4D453F).withOpacity(0.4),
              ),
              prefixIcon: Icon(
                Icons.mail_outline,
                size: 20,
                color: hasError ? const Color(0xFFBA1A1A) : const Color(0xFF4D453F),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 6),
            child: Text(
              _errorText!,
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: const Color(0xFFBA1A1A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF67594E), Color(0xFF817266)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D1B1A).withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Bounceable(
        onTap: _isLoading ? null : _handleSubmit,
        child: IgnorePointer(
          child: ElevatedButton(
            onPressed: _isLoading ? null : () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Send Reset Link',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupportLink() {
    return Center(
      child: TextButton(
        onPressed: () {},
        child: Text(
          'Need help? Contact Support',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF67594E),
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
              left: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDDDF5).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDAD3).withOpacity(0.1),
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
