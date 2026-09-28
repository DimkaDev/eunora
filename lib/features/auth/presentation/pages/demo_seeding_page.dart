import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/services/demo_generator_service.dart';
import 'package:eunora/features/onboarding/presentation/providers/medications_provider.dart';

class DemoSeedingPage extends ConsumerStatefulWidget {
  final DemoPersona persona;

  const DemoSeedingPage({
    super.key,
    this.persona = DemoPersona.demoA,
  });

  @override
  ConsumerState<DemoSeedingPage> createState() => _DemoSeedingPageState();
}

class _DemoSeedingPageState extends ConsumerState<DemoSeedingPage> {
  String _statusText = 'Signing in...';
  double _progress = 0.0;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSeeding());
  }

  void _update(String text, double progress) {
    if (mounted) {
      setState(() {
        _statusText = text;
        _progress = progress;
      });
    }
  }

  Future<void> _runSeeding() async {
    try {
      _update('Signing in anonymously...', 0.05);
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        final credential = await FirebaseAuth.instance.signInAnonymously();
        user = credential.user;
      }
      if (user == null) throw Exception('Anonymous sign-in failed');

      const service = DemoGeneratorService();
      await service.generatePersonaData(
        user: user,
        persona: widget.persona,
        onProgress: _update,
      );

      // Refresh Riverpod providers so UI immediately loads seeded data
      _update('Finalizing demo state...', 0.98);
      try {
        await ref.read(medicationsProvider.notifier).loadFromFirestore();
      } catch (_) {}

      _update('Done! Opening your demo...', 1.0);
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed: $e\n\nCheck Firestore rules allow anonymous users.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.science_outlined, size: 36, color: AppTheme.primary),
              ),
              const SizedBox(height: 24),
              Text(
                'Setting Up Demo ${widget.persona.code}',
                style: GoogleFonts.notoSerif(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Generating ${widget.persona.durationDays} days of realistic sample data\n(${widget.persona.description})',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDAD3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: const Color(0xFF6E3E3E),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.go('/signin'),
                  child: Text(
                    'Go Back',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ] else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 6,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _statusText,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
