import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eunora/features/onboarding/presentation/widgets/onboarding_header.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/onboarding/presentation/providers/menopause_stage_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:eunora/core/utils/animation_system.dart';

class MenopauseStagePage extends ConsumerStatefulWidget {
  const MenopauseStagePage({super.key});

  @override
  ConsumerState<MenopauseStagePage> createState() => _MenopauseStagePageState();
}

class _MenopauseStagePageState extends ConsumerState<MenopauseStagePage> {
  late PageController _pageController;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8)
      ..addListener(() {
        setState(() {
          _currentPage = _pageController.page ?? 0;
        });
      });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(menopauseStageProvider);
    final notifier = ref.read(menopauseStageProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          // Background blobs
          _buildBackgroundBlobs(),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTitleSection(),
                        const SizedBox(height: 20),
                        _buildCardStack(state, notifier),
                        const SizedBox(height: 16),
                        _buildCarouselDots(),
                      ],
                    ),
                  ),
                ),
                _buildFooter(context, state),
              ],
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
          top: -100,
          right: -100,
          width: 300,
          height: 300,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEDDDF5).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          left: -100,
          width: 400,
          height: 400,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF2DFD0).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const OnboardingHeader(
      currentStep: 0,
    );
  }

  Widget _buildCarouselDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final isActive = index == _currentPage.round();
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActive ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : AppTheme.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        'Tell us where you are in your journey...',
        textAlign: TextAlign.center,
        style: GoogleFonts.notoSerif(
          fontSize: 20,
          color: const Color(0xFF1D1B1A).withOpacity(0.6),
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildCardStack(MenopauseStageState state, MenopauseStageNotifier notifier) {
    final stages = [
      _StageData(
        stage: MenopauseStage.irregular,
        title: '"My periods have become irregular"',
        subtitle: "Not sure what's happening yet, but things are changing.",
        icon: Icons.autorenew,
      ),
      _StageData(
        stage: MenopauseStage.noPeriod12Months,
        title: '"I haven\'t had a period for 12+ months"',
        subtitle: "The clinical marker of menopause transition.",
        icon: Icons.pause_circle_outline,
      ),
      _StageData(
        stage: MenopauseStage.postmenopause,
        title: '"I am on postmenopause period"',
        subtitle: "Long-term physiological stabilization achieved.",
        icon: Icons.check_circle_outline,
      ),
      _StageData(
        stage: MenopauseStage.surgical,
        title: '"I Surgical menopause"',
        subtitle: "Non-linear transition due to intervention.",
        icon: Icons.medical_services_outlined,
      ),
      _StageData(
        stage: MenopauseStage.pcos,
        title: '"I have special PCOS & Hormone Condition"',
        subtitle: "Complex hormonal interactions requiring specific data.",
        icon: Icons.hub_outlined,
      ),
    ];

    return SizedBox(
      height: 520,
      child: PageView.builder(
        controller: _pageController,
        itemCount: stages.length,
        clipBehavior: Clip.none,
        itemBuilder: (context, index) {
          final data = stages[index];
          final isSelected = state.selectedStage == data.stage;
          
          // Calculate scale and opacity based on distance from current page
          double relativePosition = index - _currentPage;
          double scale = (1 - (relativePosition.abs() * 0.15)).clamp(0.75, 1.0);
          double opacity = (1 - (relativePosition.abs() * 0.6)).clamp(0.2, 1.0);
          
          return Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
                child: _buildPremiumCard(
                  data: data,
                  isSelected: isSelected,
                  onTap: () => notifier.selectStage(data.stage),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumCard({
    required _StageData data,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Bounceable(
      onTap: onTap,
      scaleFactor: 0.98,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background card stack effect
          Positioned(
            bottom: -12,
            left: 20,
            right: 20,
            top: 12,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFFE8E0F0), // secondary-container
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: isSelected ? AppTheme.primary : AppTheme.primary.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Organic Overlay
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.1,
                    child: CustomPaint(
                      painter: OrganicOverlayPainter(),
                    ),
                  ),
                ),
                
                if (isSelected)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check, color: AppTheme.primary, size: 24),
                    ),
                  ),

                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        data.icon,
                        size: 56,
                        color: const Color(0xFF9B8B7E),
                      ),
                    ),
                    
                    // Text
                    Column(
                      children: [
                        Text(
                          data.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSerif(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF3A3A3A),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          data.subtitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: const Color(0xFF6C6074),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                    
                    // Button indicator
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: Colors.white.withOpacity(0.6)),
                          ),
                          child: Text(
                            'TAP TO CHOOSE',
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: const Color(0xFF6C6074),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Icon(
                          Icons.expand_more,
                          color: AppTheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, MenopauseStageState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 48),
      child: Column(
        children: [
          Text(
            'SLIDE OR TAP TO EXPLORE YOUR OPTIONS',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Bounceable(
                  onTap: () => context.pop(),
                  child: IgnorePointer(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.surfaceContainerHighest,
                        foregroundColor: AppTheme.onSurfaceVariant,
                        minimumSize: const Size(0, 56),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Previous',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Bounceable(
                  onTap: state.selectedStage != null ? () {
                    switch (state.selectedStage) {
                      case MenopauseStage.irregular:
                        context.push('/perimenopause-profile');
                        break;
                      case MenopauseStage.noPeriod12Months:
                        context.push('/menopause-stage-profile');
                        break;
                      case MenopauseStage.postmenopause:
                        context.push('/postmenopause-profile');
                        break;
                      case MenopauseStage.surgical:
                        context.push('/surgical-menopause-profile');
                        break;
                      case MenopauseStage.pcos:
                        context.push('/pcos-profile');
                        break;
                      default:
                        context.go('/home');
                    }
                  } : null,
                  child: IgnorePointer(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: AppTheme.primary.withOpacity(0.4),
                      ),
                      child: Text(
                        'Next Path',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StageData {
  final MenopauseStage stage;
  final String title;
  final String subtitle;
  final IconData icon;

  _StageData({
    required this.stage,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class OrganicOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.5);
    path1.quadraticBezierTo(size.width * 0.25, size.height * 0.3, size.width * 0.5, size.height * 0.5);
    path1.quadraticBezierTo(size.width * 0.75, size.height * 0.7, size.width, size.height * 0.5);
    canvas.drawPath(path1, paint..color = AppTheme.primary.withOpacity(0.1));

    final path2 = Path();
    path2.moveTo(0, size.height * 0.4);
    path2.quadraticBezierTo(size.width * 0.3, size.height * 0.6, size.width * 0.6, size.height * 0.4);
    path2.quadraticBezierTo(size.width * 0.8, size.height * 0.2, size.width, size.height * 0.4);
    canvas.drawPath(path2, paint..color = AppTheme.primary.withOpacity(0.05));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
