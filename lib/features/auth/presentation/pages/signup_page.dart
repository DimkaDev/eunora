import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/auth/presentation/providers/signup_provider.dart';

class SignUpPage extends ConsumerWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signUpProvider);
    final notifier = ref.read(signUpProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF444444)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Create Your MenoSync Account',
          style: GoogleFonts.notoSerif(
            color: const Color(0xFF1D1B1A),
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            _buildInputField(
              label: 'Email Address',
              placeholder: 'you@email.com',
              value: state.email,
              errorText: state.showErrors ? state.emailError : null,
              onChanged: notifier.updateEmail,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _buildInputField(
              label: 'Password',
              placeholder: 'Create a secure password',
              value: state.password,
              obscureText: true,
              onChanged: notifier.updatePassword,
              errorText: state.showErrors && state.passwordError != null ? state.passwordError : null,
              bottomWidget: _buildPasswordRequirements(state),
            ),
            const SizedBox(height: 20),
            _buildInputField(
              label: 'Confirm Password',
              placeholder: 'Confirm your password',
              value: state.confirmPassword,
              obscureText: true,
              onChanged: notifier.updateConfirmPassword,
              errorText: state.showErrors ? state.confirmPasswordError : null,
              bottomWidget: Text(
                'Passwords must match',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: state.showErrors && !state.passwordsMatch ? const Color(0xFFE8A89B) : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // if (notifier.validate()) {
                  //   context.push('/verify-email');
                  // }
                  //TODO
                    context.push('/verify-email');

                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9B8B7E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Create Account',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR CONTINUE WITH',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: Colors.grey,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton('G'),
                const SizedBox(width: 16),
                _buildSocialButton('A'),
              ],
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () => context.push('/signin'),
              child: Text(
                'Already have account? Sign in',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.only(top: 24),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0x1A9B8B7E))),
              ),
              child: Text(
                '"This is the start of a more supported,\nharmonious transition."',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSerif(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String placeholder,
    required String value,
    required Function(String) onChanged,
    bool obscureText = false,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
    Widget? bottomWidget,
  }) {
    final bool hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: const Color(0xFF4D453F),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: onChanged,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: GoogleFonts.manrope(fontSize: 14),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.manrope(color: Colors.grey[400]),
            filled: true,
            fillColor: hasError ? const Color(0xFFFFF9F8) : const Color(0xFFEEEEEE),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? const Color(0xFFE8A89B) : const Color(0xFF9B8B7E),
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? const Color(0xFFE8A89B) : const Color(0xFF9B8B7E),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF9B8B7E),
                width: 2,
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                const Icon(Icons.error, size: 14, color: Color(0xFFE8A89B)),
                const SizedBox(width: 4),
                Text(
                  errorText,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: const Color(0xFFE8A89B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        if (bottomWidget != null) Padding(padding: const EdgeInsets.only(top: 8), child: bottomWidget),
      ],
    );
  }

  Widget _buildPasswordRequirements(SignUpState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRequirementItem('At least 8 characters', state.hasMinLength),
        _buildRequirementItem('One uppercase letter', state.hasUppercase),
        _buildRequirementItem('One number', state.hasNumber),
        _buildRequirementItem('One special character (!@#\$%)', state.hasSpecialChar),
      ],
    );
  }

  Widget _buildRequirementItem(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 4),
      child: Row(
        children: [
          Text(
            met ? '✓' : '✕',
            style: TextStyle(
              color: met ? const Color(0xFF9B8B7E) : (met ? Colors.grey : const Color(0xFFE8A89B)),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: met ? Colors.grey[600] : (met ? Colors.grey[600] : const Color(0xFFE8A89B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(String label) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF444444),
          ),
        ),
      ),
    );
  }
}
