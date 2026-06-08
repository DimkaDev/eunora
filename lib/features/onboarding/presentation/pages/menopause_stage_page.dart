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
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  const MenopauseStagePage({super.key, this.onNext, this.onBack});

  @override
  ConsumerState<MenopauseStagePage> createState() => _MenopauseStagePageState();
}

class _MenopauseStagePageState extends ConsumerState<MenopauseStagePage> {
  late PageController _pageController;
  final ValueNotifier<int> _activePageIndexNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _activePageIndexNotifier.dispose();
    super.dispose();
  }

  void _showInfoDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFEF8F6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'About Menopause Stages',
                  style: GoogleFonts.notoSerif(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1D1B1A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF9B8B7E)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Understanding your current stage helps Eunora customize your dashboard, track relevant patterns, and offer targeted insights. Here is a brief guide to the options:',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF4D453F),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoRow(
              icon: Icons.autorenew,
              title: 'Irregular Periods (Perimenopause)',
              desc: 'Hormone fluctuations begin, leading to changes in cycles and early symptoms like hot flashes or mood swings.',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.pause_circle_outline,
              title: 'No Period for 12+ Months (Menopause)',
              desc: 'The official clinical milestone. You have reached menopause once you have gone 12 consecutive months without a period.',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.check_circle_outline,
              title: 'Postmenopause',
              desc: 'The years following menopause. Symptoms may stabilize, but long-term wellness tracking remains essential.',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.medical_services_outlined,
              title: 'Surgical Menopause',
              desc: 'Induced suddenly due to bilateral oophorectomy (removal of both ovaries) or medical treatments.',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.hub_outlined,
              title: 'PCOS / Hormone Conditions',
              desc: 'Special conditions such as Polycystic Ovary Syndrome that alter hormonal baselines.',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Got it',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1D1B1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: const Color(0xFF7F756E),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
                    physics: const ClampingScrollPhysics(),
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
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFEDDDF5).withOpacity(0.5),
                  const Color(0xFFEDDDF5).withOpacity(0.0),
                ],
              ),
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
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFF2DFD0).withOpacity(0.5),
                  const Color(0xFFF2DFD0).withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return OnboardingHeader(
      currentStep: 0,
      subtitle: 'MENOPAUSE STAGE',
      onSkip: _showInfoDialog,
      showBackButton: false,
    );
  }

  Widget _buildCarouselDots() {
    return ValueListenableBuilder<int>(
      valueListenable: _activePageIndexNotifier,
      builder: (context, activeIndex, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final isActive = index == activeIndex;
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
      },
    );
  }

  Widget _buildTitleSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Journey',
            style: GoogleFonts.notoSerif(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D1B1A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us where you are in your journey',
            style: GoogleFonts.manrope(
              fontSize: 16,
              color: const Color(0xFF1D1B1A).withOpacity(0.6),
            ),
          ),
        ],
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
        onPageChanged: (index) {
          _activePageIndexNotifier.value = index;
        },
        itemBuilder: (context, index) {
          final data = stages[index];
          final isSelected = state.selectedStage == data.stage;
          
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double page = 0.0;
              if (_pageController.hasClients && _pageController.position.hasContentDimensions) {
                page = _pageController.page ?? 0.0;
              } else {
                page = 0.0;
              }
              
              // Calculate scale and opacity based on distance from current page
              double relativePosition = index - page;
              double scale = (1 - (relativePosition.abs() * 0.15)).clamp(0.75, 1.0);
              double opacity = (1 - (relativePosition.abs() * 0.6)).clamp(0.2, 1.0);
              
              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
              child: _buildPremiumCard(
                data: data,
                isSelected: isSelected,
                onTap: () => notifier.selectStage(data.stage),
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
    final hasSelection = state.selectedStage != null;
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
          SizedBox(
            width: double.infinity,
            child: Bounceable(
              onTap: hasSelection
                  ? () {
                      if (widget.onNext != null) {
                        widget.onNext!();
                      } else {
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
                      }
                    }
                  : null,
              child: IgnorePointer(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasSelection ? AppTheme.primary : const Color(0xFFE8E0F0).withOpacity(0.6),
                    foregroundColor: hasSelection ? Colors.white : const Color(0xFF9B8B7E),
                    minimumSize: const Size(0, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: hasSelection ? 8 : 0,
                    shadowColor: hasSelection ? AppTheme.primary.withOpacity(0.4) : Colors.transparent,
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
