import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late AnimationController _logoController;
  late AnimationController _textController;

  late Animation<double> _ripple1Scale;
  late Animation<double> _ripple1Opacity;
  late Animation<double> _ripple2Scale;
  late Animation<double> _ripple2Opacity;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  final IconData _spaIcon = const IconData(0xf01ad, fontFamily: 'MaterialIcons');

  @override
  void initState() {
    super.initState();

    // 1. Ripple Animation Controller (Looping)
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _ripple1Scale = Tween<double>(begin: 0.8, end: 1.8).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _ripple1Opacity = Tween<double>(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _ripple2Scale = Tween<double>(begin: 0.8, end: 1.8).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _ripple2Opacity = Tween<double>(begin: 0.3, end: 0.0).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    // 2. Logo Animation Controller (Entrance springy bounce)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutBack,
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOut,
      ),
    );

    // 3. Text Animation Controller (Staggered fade-up)
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOut,
      ),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Cubic(0.16, 1, 0.3, 1),
      ),
    );

    // Start Animations sequence
    _logoController.forward().then((_) {
      _textController.forward();
    });

    // Navigate to correct destination as soon as auth state is initialized and animations finish
    Future.wait([
      Future.delayed(const Duration(milliseconds: 1800)),
      FirebaseAuth.instance.authStateChanges().first,
    ]).then((results) async {
      if (!mounted) return;
      final user = results[1] as User?;
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
        context.go('/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          // Ambient soft background glow blobs
          _buildBackgroundBlobs(),

          // Centered Splash elements
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Ripples + Logo Stack
                SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ripples
                      AnimatedBuilder(
                        animation: _rippleController,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: _ripple1Opacity.value,
                                child: Transform.scale(
                                  scale: _ripple1Scale.value,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.primary.withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Opacity(
                                opacity: _ripple2Opacity.value,
                                child: Transform.scale(
                                  scale: _ripple2Scale.value,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.primary.withOpacity(0.2),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      // Central Logo Widget
                      AnimatedBuilder(
                        animation: _logoController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _logoOpacity.value,
                            child: Transform.scale(
                              scale: _logoScale.value,
                              child: Container(
                                width: 104,
                                height: 104,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(36),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withOpacity(0.06),
                                      blurRadius: 24,
                                      offset: const Offset(0, 12),
                                    ),
                                    BoxShadow(
                                      color: AppTheme.primary.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _spaIcon,
                                  size: 52,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Title & Subtitle Fade Up
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textOpacity.value,
                      child: FractionalTranslation(
                        translation: _textSlide.value,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Text(
                        'Eunora',
                        style: GoogleFonts.notoSerif(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'YOUR HORMONAL HARMONY',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurfaceVariant.withOpacity(0.7),
                          letterSpacing: 3.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Loading Harmony Indicator
          Positioned(
            bottom: 64,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textOpacity.value,
                    child: child,
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primary.withOpacity(0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Initializing harmony...',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundBlobs() {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -80,
          width: 280,
          height: 280,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEDDDF5).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          left: -80,
          width: 320,
          height: 320,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF2DFD0).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
