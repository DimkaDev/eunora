import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/services/auth_service.dart';
import 'package:eunora/core/utils/animation_system.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isEmailLoading = false;
  bool _isGoogleLoading = false;
  
  String? _emailErrorText;
  String? _googleErrorText;
  
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    setState(() {
      _isEmailLoading = true;
      _emailErrorText = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      await auth.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        final user = FirebaseAuth.instance.currentUser;
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
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isEmailLoading = false;
          _emailErrorText = e.message ?? 'Invalid email or password. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isEmailLoading = false;
          _emailErrorText = 'An unexpected error occurred. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF8F6), // surface
      body: Stack(
        children: [
          // Decorative background blobs
          _buildDecorations(),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildFormCard(),
                      const SizedBox(height: 12),
                      _buildTestSeedButton(),
                      const SizedBox(height: 24),
                      _buildSocialSection(),
                      const SizedBox(height: 40),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Color(0xFFF2EDEA), // surface-container
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.spa,
            color: Color(0xFF67594E), // primary
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Welcome Back',
          style: GoogleFonts.notoSerif(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1D1B1A), // on-surface
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Sign in to your Eunora account',
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF4D453F), // on-surface-variant
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    final bool hasError = _emailErrorText != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D1B1A).withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email
          Text(
            'EMAIL ADDRESS',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D1B1A),
            ),
          ),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _emailController,
            hint: 'you@email.com',
            icon: Icons.mail_outline,
            hasError: hasError,
            enabled: !_isEmailLoading && !_isGoogleLoading,
          ),
          const SizedBox(height: 16),
          
          // Password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PASSWORD',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1D1B1A),
                ),
              ),
              GestureDetector(
                onTap: _isEmailLoading || _isGoogleLoading ? null : () => context.push('/forgot-password'),
                child: Text(
                  'Forgot?',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: const Color(0xFF67594E),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _passwordController,
            hint: '••••••••',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            hasError: hasError,
            enabled: !_isEmailLoading && !_isGoogleLoading,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
                color: const Color(0xFF4D453F).withOpacity(0.6),
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),

          if (hasError) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.error_outline, size: 16, color: Color(0xFFBA1A1A)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _emailErrorText!,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: const Color(0xFFBA1A1A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),
          _buildPrimaryButton(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    bool hasError = false,
    bool enabled = true,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: hasError ? const Color(0xFFFFDAD6).withOpacity(0.2) : const Color(0xFFE7E1DF), // surface-container-highest
        borderRadius: BorderRadius.circular(12),
        border: hasError ? Border.all(color: const Color(0xFFBA1A1A).withOpacity(0.5)) : null,
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        enabled: enabled,
        style: GoogleFonts.manrope(
          fontSize: 14,
          color: const Color(0xFF1D1B1A),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.manrope(
            color: const Color(0xFF4D453F).withOpacity(0.5),
          ),
          prefixIcon: Icon(icon, size: 20, color: hasError ? const Color(0xFFBA1A1A) : const Color(0xFF4D453F)),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF67594E), Color(0xFF817266)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Bounceable(
        onTap: _isEmailLoading || _isGoogleLoading ? null : _handleSignIn,
        child: IgnorePointer(
          child: ElevatedButton(
            onPressed: _isEmailLoading || _isGoogleLoading ? null : () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isEmailLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Sign In',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: const Color(0xFFD0C4BC).withOpacity(0.3))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OR CONTINUE WITH',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4D453F).withOpacity(0.6),
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(child: Divider(color: const Color(0xFFD0C4BC).withOpacity(0.3))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildSocialButton('Apple', Icons.apple)),
            const SizedBox(width: 12),
            Expanded(child: _buildSocialButton('Google', null, isGoogle: true)),
          ],
        ),
        if (_googleErrorText != null) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 16, color: Color(0xFFBA1A1A)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _googleErrorText!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: const Color(0xFFBA1A1A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSocialButton(String label, IconData? icon, {bool isGoogle = false}) {
    final bool isThisLoading = isGoogle && _isGoogleLoading;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD0C4BC).withOpacity(0.3)),
      ),
      child: Bounceable(
        onTap: _isEmailLoading || _isGoogleLoading
            ? null
            : () async {
                if (isGoogle) {
                  setState(() {
                    _isGoogleLoading = true;
                    _googleErrorText = null;
                  });
                  try {
                    final credentials = await ref.read(authServiceProvider).signInWithGoogle();
                    if (credentials != null && mounted) {
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
                      if (mounted) {
                        setState(() => _isGoogleLoading = false);
                      }
                    }
                  } on FirebaseAuthException catch (e) {
                    if (mounted) {
                      setState(() {
                        _isGoogleLoading = false;
                        _googleErrorText = e.message ?? 'Google Sign-In failed.';
                      });
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        _isGoogleLoading = false;
                        _googleErrorText = 'Google Sign-In was cancelled or failed.';
                      });
                    }
                  }
                } else {
                  // Apple Sign-In mock
                }
              },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: isThisLoading
              ? [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF67594E)),
                    ),
                  )
                ]
              : [
                  if (isGoogle)
                    Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/3840px-Google_%22G%22_logo.svg.png',
                      width: 18,
                      height: 18,
                    )
                  else
                    Icon(icon, size: 18, color: const Color(0xFF1D1B1A)),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1D1B1A),
                    ),
                  ),
                ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: const Color(0xFF4D453F),
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/signup'),
          child: Text(
            'Create one',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF67594E),
              decoration: TextDecoration.underline,
              decorationThickness: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDecorations() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -50,
              left: -50,
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
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDAD3).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSeedButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF817266).withOpacity(0.4), width: 1.5),
      ),
      child: Bounceable(
        onTap: () => context.push('/demo'),
        child: Center(
          child: Text(
            '🧪  Try Demo (90-Day Sample Data)',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF67594E),
            ),
          ),
        ),
      ),
    );
  }
}

