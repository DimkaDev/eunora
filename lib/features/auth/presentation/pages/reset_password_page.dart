import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNumber => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial => _passwordController.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
  bool get _passwordsMatch => _passwordController.text == _confirmController.text && _passwordController.text.isNotEmpty;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _handleReset() async {
    if (!_hasMinLength || !_hasUppercase || !_hasNumber || !_hasSpecial || !_passwordsMatch) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() => _isLoading = false);
      context.go('/reset-password-success');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF8F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF67594E)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Reset Your Password',
          style: GoogleFonts.notoSerif(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF67594E),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildDecorations(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildIconHeader(),
                  const SizedBox(height: 32),
                  _buildPasswordForm(),
                  const SizedBox(height: 40),
                  _buildResetButton(),
                  const SizedBox(height: 24),
                  _buildFooterLink(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFF2EDEA),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_reset, size: 32, color: Color(0xFF67594E)),
        ),
        const SizedBox(height: 16),
        Text(
          'Enter your new secure password below to regain access to your sanctuary.',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: const Color(0xFF4D453F),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('New Password'),
        const SizedBox(height: 8),
        _buildPasswordField(_passwordController, '••••••••'),
        const SizedBox(height: 16),
        _buildRequirementsList(),
        const SizedBox(height: 24),
        _buildLabel('Confirm Password'),
        const SizedBox(height: 8),
        _buildPasswordField(_confirmController, '••••••••', showObscureToggle: false),
        if (_confirmController.text.isNotEmpty && !_passwordsMatch)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              'Passwords must match',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: const Color(0xFF67594E),
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1D1B1A),
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String hint, {bool showObscureToggle = true}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE7E1DF),
        borderRadius: BorderRadius.circular(100),
      ),
      child: TextField(
        controller: controller,
        obscureText: _obscurePassword,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.manrope(fontSize: 16, color: const Color(0xFF1D1B1A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.manrope(color: const Color(0xFF4D453F).withOpacity(0.4)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          suffixIcon: showObscureToggle
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 20,
                    color: const Color(0xFF4D453F).withOpacity(0.6),
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildRequirementsList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EDEA).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildRequirementRow('At least 8 characters', _hasMinLength),
          const SizedBox(height: 12),
          _buildRequirementRow('One uppercase letter', _hasUppercase),
          const SizedBox(height: 12),
          _buildRequirementRow('One number (0-9)', _hasNumber),
          const SizedBox(height: 12),
          _buildRequirementRow('One special character (!@#\$)', _hasSpecial),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool met) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: met ? const Color(0xFF67594E) : const Color(0xFFD0C4BC),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF4D453F),
          ),
        ),
      ],
    );
  }

  Widget _buildResetButton() {
    final bool canSubmit = _hasMinLength && _hasUppercase && _hasNumber && _hasSpecial && _passwordsMatch;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: canSubmit
            ? const LinearGradient(colors: [Color(0xFF67594E), Color(0xFF817266)])
            : null,
        color: canSubmit ? null : Colors.grey[300],
        borderRadius: BorderRadius.circular(100),
        boxShadow: canSubmit
            ? [BoxShadow(color: const Color(0xFF67594E).withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 8))]
            : null,
      ),
      child: ElevatedButton(
        onPressed: canSubmit && !_isLoading ? _handleReset : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: const StadiumBorder(),
        ),
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Reset Password', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                ],
              ),
      ),
    );
  }

  Widget _buildFooterLink() {
    return TextButton(
      onPressed: () => context.go('/signin'),
      child: Text(
        'Return to Login',
        style: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF67594E),
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
              top: 100,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(color: const Color(0xFFEDDDF5).withOpacity(0.1), shape: BoxShape.circle),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(color: const Color(0xFFFFDAD3).withOpacity(0.1), shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
