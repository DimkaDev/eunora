import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/features/auth/presentation/providers/signup_provider.dart';
import 'package:eunora/core/utils/animation_system.dart';
import 'package:eunora/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
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
          'Create Your Eunora Account',
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
              obscureText: _obscurePassword,
              onChanged: notifier.updatePassword,
              errorText: state.showErrors && state.passwordError != null ? state.passwordError : null,
              bottomWidget: _buildPasswordRequirements(state),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                  color: const Color(0xFF4D453F).withOpacity(0.6),
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 20),
            _buildInputField(
              label: 'Confirm Password',
              placeholder: 'Confirm your password',
              value: state.confirmPassword,
              obscureText: _obscureConfirmPassword,
              onChanged: notifier.updateConfirmPassword,
              errorText: state.showErrors ? state.confirmPasswordError : null,
              bottomWidget: Text(
                'Passwords must match',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: state.showErrors && !state.passwordsMatch ? const Color(0xFFE8A89B) : Colors.grey,
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                  color: const Color(0xFF4D453F).withOpacity(0.6),
                ),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
            const SizedBox(height: 40),
            if (state.generalError != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: Color(0xFFBA1A1A)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.generalError!,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: const Color(0xFFBA1A1A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(
              width: double.infinity,
              child: Bounceable(
                onTap: (state.isLoading || state.isGoogleLoading)
                    ? null
                    : () async {
                        final success = await notifier.signUp();
                        if (success && context.mounted) {
                          context.go('/verify-email');
                        }
                      },
                child: IgnorePointer(
                  child: ElevatedButton(
                    onPressed: (state.isLoading || state.isGoogleLoading) ? null : () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B8B7E),
                      disabledBackgroundColor: const Color(0xFF9B8B7E).withOpacity(0.5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Create Account',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
            SizedBox(
              width: double.infinity,
              child: Bounceable(
                onTap: (state.isLoading || state.isGoogleLoading)
                    ? null
                    : () async {
                        notifier.setGoogleLoading(true);
                        notifier.setGeneralError(null);
                        try {
                           final credentials = await ref.read(authServiceProvider).signInWithGoogle();
                           if (credentials != null && context.mounted) {
                             final user = credentials.user;
                             if (user != null) {
                               final prefs = await SharedPreferences.getInstance();
                               if (!mounted) return;
                               final isCompleted = prefs.getBool('onboarding_completed_${user.uid}') ?? false;
                               if (isCompleted) {
                                 context.go('/home');
                               } else {
                                 context.go('/menopause-stage');
                               }
                             } else {
                               context.go('/menopause-stage');
                             }
                           } else {
                             notifier.setGoogleLoading(false);
                           }
                        } on FirebaseAuthException catch (e) {
                          notifier.setGoogleLoading(false);
                          notifier.setGeneralError(e.message ?? 'Google Sign-In failed.');
                        } catch (e) {
                          notifier.setGoogleLoading(false);
                          notifier.setGeneralError('Google Sign-In was cancelled or failed.');
                        }
                      },
                child: IgnorePointer(
                  child: OutlinedButton(
                    onPressed: (state.isLoading || state.isGoogleLoading) ? null : () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF9B8B7E), width: 2),
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4D453F),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: state.isGoogleLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Color(0xFF9B8B7E), strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFD0C4BC)),
                                ),
                                child: Image.network(
                                  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/3840px-Google_%22G%22_logo.svg.png',
                                  width: 18,
                                  height: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Continue with Google',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4D453F),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
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
    Widget? suffixIcon,
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
            suffixIcon: suffixIcon,
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
}
