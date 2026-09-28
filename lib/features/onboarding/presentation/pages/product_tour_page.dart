import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/theme/widgets/primary_gradient_button.dart';
import 'package:eunora/features/onboarding/presentation/providers/product_tour_provider.dart';

class ProductTourStepData {
  final String stepNumber;
  final String category;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Widget heroVisual;
  final List<String> bulletHighlights;

  const ProductTourStepData({
    required this.stepNumber,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.heroVisual,
    required this.bulletHighlights,
  });
}

class ProductTourPage extends ConsumerStatefulWidget {
  const ProductTourPage({super.key});

  @override
  ConsumerState<ProductTourPage> createState() => _ProductTourPageState();
}

class _ProductTourPageState extends ConsumerState<ProductTourPage> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeTourAndNavigateHome() async {
    await ref.read(productTourControllerProvider.notifier).markTourCompleted();
    if (mounted) {
      context.go('/home');
    }
  }

  void _nextPage(int totalPages) {
    if (_currentPage < totalPages - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeTourAndNavigateHome();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = _buildTourSteps();
    final isLastStep = _currentPage == steps.length - 1;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          // Soft ambient background tint
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: steps[_currentPage].accentColor.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryFixed.withOpacity(0.25),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Progress Bar & Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Column(
                    children: [
                      // Segmented Progress Bar
                      Row(
                        children: List.generate(steps.length, (index) {
                          final isCompleted = index <= _currentPage;
                          return Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 2.5),
                              height: 4,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? AppTheme.primary
                                    : AppTheme.outlineVariant.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 12),

                      // Navigation Bar: Back / Badge / Skip
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentPage > 0)
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                              color: AppTheme.primary,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _previousPage,
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainer.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.spa_rounded, color: AppTheme.primary, size: 14),
                                  const SizedBox(width: 5),
                                  Text(
                                    'EUNORA TOUR',
                                    style: GoogleFonts.manrope(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Step Counter
                          Text(
                            steps[_currentPage].stepNumber,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.outline,
                            ),
                          ),

                          // Skip Button
                          TextButton(
                            onPressed: _completeTourAndNavigateHome,
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.outline,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Skip',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.outline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Carousel of Tour Screens
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: steps.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final step = steps[index];
                      return _buildSlideContent(context, step);
                    },
                  ),
                ),

                // Bottom Action Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: PrimaryGradientButton(
                    text: isLastStep ? 'Get Started' : 'Next',
                    onPressed: () => _nextPage(steps.length),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideContent(BuildContext context, ProductTourStepData step) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Category Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: step.accentColor.withOpacity(0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              step.category.toUpperCase(),
              style: GoogleFonts.manrope(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSerif(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 5),

          // Subtitle
          Text(
            step.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryContainer,
            ),
          ),
          const SizedBox(height: 18),

          // Hero Visual Card
          step.heroVisual,
          const SizedBox(height: 18),

          // Informative Feature Highlights
          Column(
            children: step.bulletHighlights.map((highlight) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: step.accentColor.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, size: 13, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        highlight,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<ProductTourStepData> _buildTourSteps() {
    return [
      // 1. Daily Symptom Logging
      ProductTourStepData(
        stepNumber: '1 of 5',
        category: 'Quick Journal',
        title: 'Daily Symptom Logging',
        subtitle: 'Quick 60-second check-in, zero friction',
        icon: Icons.edit_note_rounded,
        accentColor: const Color(0xFFD4A5A5),
        bulletHighlights: [
          'Log symptoms, severity, and sleep in under a minute',
          'Tracks daily triggers like caffeine, alcohol, and stress',
        ],
        heroVisual: _buildLoggingVisual(),
      ),

      // 2. Calendar & Weekly Trends
      ProductTourStepData(
        stepNumber: '2 of 5',
        category: 'Visual History',
        title: 'Calendar & Weekly Trends',
        subtitle: 'Spot patterns and celebrate symptom-free days',
        icon: Icons.calendar_month_rounded,
        accentColor: const Color(0xFFB8A7C5),
        bulletHighlights: [
          'Symptom-free days are tracked and highlighted',
          'Objective week-to-week comparison with no guesswork',
        ],
        heroVisual: _buildCalendarVisual(),
      ),

      // 3. AI Pattern Recognition
      ProductTourStepData(
        stepNumber: '3 of 5',
        category: 'AI Engine',
        title: 'What Affects You?',
        subtitle: 'Discover hidden cause & effect connections',
        icon: Icons.auto_awesome_rounded,
        accentColor: const Color(0xFFA7C5D8),
        bulletHighlights: [
          'Uncovers next-day triggers you might otherwise miss',
          'Identifies protective habits that give you relief',
        ],
        heroVisual: _buildPatternVisual(),
      ),

      // 4. Smart HRT Journey
      ProductTourStepData(
        stepNumber: '4 of 5',
        category: 'Hormone Therapy',
        title: 'Smart HRT Journey',
        subtitle: 'Know with certainty if your therapy is working',
        icon: Icons.medication_rounded,
        accentColor: const Color(0xFF8EB8B5),
        bulletHighlights: [
          'Tracks scheduled regimens & as-needed doses',
          '14-day analysis measures before & after dose adjustments',
        ],
        heroVisual: _buildHrtVisual(),
      ),

      // 5. Menopause Health Passport
      ProductTourStepData(
        stepNumber: '5 of 5',
        category: 'Clinical Summary',
        title: 'Menopause Passport',
        subtitle: 'Data your doctor can actually read and act on',
        icon: Icons.assignment_ind_rounded,
        accentColor: const Color(0xFFD4B28A),
        bulletHighlights: [
          'Export clinical-grade PDF reports for your gynecologist',
          'Arrive prepared with objective numbers, not vague memory',
        ],
        heroVisual: _buildPassportVisual(),
      ),
    ];
  }

  // =========================================================================
  // SCREEN 1 HERO: Interactive-feel Daily Check-in Capsule
  // =========================================================================
  Widget _buildLoggingVisual() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.onSurface.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Time estimate badge + Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3ECE6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 12, color: AppTheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      '⏱ 60s Check-in',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Today, 21:00',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Symptom Pill Row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9EAE1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD4A5A5), width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_rounded, size: 15, color: Color(0xFFB54C4C)),
                    const SizedBox(width: 6),
                    Text(
                      'Hot Flashes',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF702626),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F5F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bedtime_outlined, size: 14, color: AppTheme.outline),
                    const SizedBox(width: 5),
                    Text(
                      'Night Sweats',
                      style: GoogleFonts.manrope(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F5F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.dark_mode_outlined, size: 14, color: AppTheme.outline),
                    const SizedBox(width: 5),
                    Text(
                      'Sleep 7.5h',
                      style: GoogleFonts.manrope(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Google-style 3-step Severity Pill Selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F3F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'Mild (1)',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.outline,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Center(
                      child: Text(
                        'Moderate (3)',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF9E5454),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'Severe (5)',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.outline,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Quick trigger tags
          Row(
            children: [
              Text(
                'Logged triggers: ',
                style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.outline),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Coffee · 2 cups, Mild stress',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SCREEN 2 HERO: Weekly Rhythm Strip & Symptom-Free Milestone Card
  // =========================================================================
  Widget _buildCalendarVisual() {
    final weekdays = [
      {'day': 'M', 'num': '14', 'free': false},
      {'day': 'T', 'num': '15', 'free': false},
      {'day': 'W', 'num': '16', 'free': true},
      {'day': 'T', 'num': '17', 'free': false},
      {'day': 'F', 'num': '18', 'free': true},
      {'day': 'S', 'num': '19', 'free': true},
      {'day': 'S', 'num': '20', 'free': false},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.onSurface.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weekdays.map((item) {
              final isFree = item['free'] as bool;
              final isToday = item['num'] == '19';
              return Column(
                children: [
                  Text(
                    item['day'] as String,
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.outline,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppTheme.primary
                          : (isFree ? const Color(0xFFE8F5E9) : const Color(0xFFF7F2EE)),
                      shape: BoxShape.circle,
                      border: isToday
                          ? Border.all(color: AppTheme.primary, width: 2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item['num'] as String,
                      style: GoogleFonts.manrope(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isToday
                            ? Colors.white
                            : (isFree ? const Color(0xFF2E7D32) : AppTheme.onSurface),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isFree)
                    const Icon(Icons.eco_rounded, size: 10, color: Color(0xFF2E7D32))
                  else
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD4A5A5),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFEFECE9)),
          const SizedBox(height: 12),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.spa_rounded, color: Color(0xFF2E7D32), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '3 Symptom-Free Days this week',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    Text(
                      'Score 2.4 vs 3.1 last week (–23% burden)',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SCREEN 3 HERO: AI Correlation Flow Cards (Cause ──▶ Effect)
  // =========================================================================
  Widget _buildPatternVisual() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.onSurface.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, size: 12, color: Color(0xFF1565C0)),
                    const SizedBox(width: 4),
                    Text(
                      'AI PATTERN DISCOVERY',
                      style: GoogleFonts.manrope(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1565C0),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'High Confidence',
                  style: GoogleFonts.manrope(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Flow Card 1: Trigger -> Symptom
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7F5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFDAD3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('☕', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 3),
                      Text('Coffee', style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '+38% next day',
                        style: GoogleFonts.manrope(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFB54C4C),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFFB54C4C)),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 3),
                      Text('Hot Flashes', style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Flow Card 2: Protective Habit
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCEDC8)),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_walk_rounded, size: 16, color: Color(0xFF33691E)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '20m Walking ── 35% milder fatigue',
                    style: GoogleFonts.manrope(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF33691E),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Protective',
                    style: GoogleFonts.manrope(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF33691E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SCREEN 4 HERO: Smart HRT Treatment Capsule & Dose Change Impact
  // =========================================================================
  Widget _buildHrtVisual() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.onSurface.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.medication_rounded, size: 18, color: Color(0xFF00695C)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estrogel 0.06%',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '2 pumps daily · Morning',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.outline),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 4),
                    Text(
                      'Taken',
                      style: GoogleFonts.manrope(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dose Change Tracker Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F7F5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Dose increased (1 → 2 pumps)',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Day 8 of 14',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 8 / 14,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFE8E3DF),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Before: 3.6 (Moderate)',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(fontSize: 10, color: AppTheme.outline),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Now: 1.8 (–50% severity)',
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
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

  // =========================================================================
  // SCREEN 5 HERO: Doctor-Ready Health Passport Summary Card
  // =========================================================================
  Widget _buildPassportVisual() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.onSurface.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBE9E7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.assignment_turned_in_rounded, size: 18, color: Color(0xFFD84315)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Clinician Summary',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '30-Day Clinical Dataset',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(fontSize: 10.5, color: AppTheme.outline),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F0EB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'PDF Ready',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Clinical Metrics Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F7F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildPassportMetricRow('Logged Days Coverage', '18 / 18 days (100%)'),
                const SizedBox(height: 6),
                _buildPassportMetricRow('Primary Symptom', 'Hot Flashes · Moderate'),
                const SizedBox(height: 6),
                _buildPassportMetricRow('HRT Adherence', '94% on-schedule'),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Action pill
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EAE4),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.file_download_outlined, size: 14, color: AppTheme.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'One-tap PDF Export for Appointments',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassportMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.outline),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
        ),
      ],
    );
  }
}
