import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
        // For demonstration, trigger error if email contains "error"
        if (_emailController.text.contains('error')) {
          _errorText = 'Invalid email or password. Please try again.';
        } else {
          context.go('/home');
        }
      });
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
          'Sign in to your MenoSync account',
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
    final bool hasError = _errorText != null;

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
            enabled: !_isLoading,
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
                onTap: _isLoading ? null : () => context.push('/forgot-password'),
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
            enabled: !_isLoading,
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
                    _errorText!,
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
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _isLoading
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
      ],
    );
  }

  Widget _buildSocialButton(String label, IconData? icon, {bool isGoogle = false}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD0C4BC).withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: _isLoading ? null : () {},
        borderRadius: BorderRadius.circular(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isGoogle)
              Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuB3RKwb287WL6LcvvN-g0EuUlzOBO_YTt9wEWApQdRZ7ZlVuvNiO3-IHmqFoX-1BoYEw_rk_bnr2lTT0sIqnSfd9IXLxGQwPAlSLpUVfXjKnYkZNyH3mJFyrtteggj1wLvkxod3cN1coUOuAIUwlVE9g-h2yN1zbshyZbjmj2bk0ozdSUMVlkGO55gwogcLlxOeLjVfNHal7UTiV5ntTf4yM6dhXzr752CP80RWPNm1T_ML-DAot2HIxgcRA3C8lR6E8ifo1nw1tiA',
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
}
