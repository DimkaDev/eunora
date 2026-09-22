import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
import 'dart:math';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/services/firestore_service.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/insights/models/insight_result.dart';
import 'package:eunora/features/insights/providers/insights_provider.dart';
import 'package:eunora/features/passport/providers/passport_provider.dart';
import 'package:eunora/features/passport/providers/passport_screen_controller.dart';
import 'package:eunora/core/services/premium_guard_provider.dart';

// Modular sub-widgets
import 'package:eunora/features/home/presentation/widgets/analytics/state_switcher_widget.dart';
import 'package:eunora/features/home/presentation/widgets/analytics/period_selector_widget.dart';
import 'package:eunora/features/home/presentation/widgets/analytics/symptom_frequency_card.dart';
import 'package:eunora/features/home/presentation/widgets/analytics/most_frequent_symptoms_card.dart';
import 'package:eunora/features/home/presentation/widgets/analytics/severity_trend_card.dart';
import 'package:eunora/features/home/presentation/widgets/analytics/recommendation_item_widget.dart';
import 'package:eunora/features/home/presentation/widgets/analytics/recommendation_section_widget.dart';
import 'package:eunora/features/home/presentation/widgets/analytics/what_affects_you_card.dart';
import 'package:eunora/features/home/presentation/widgets/analytics/ai_correlations_hrt_card.dart';
import 'package:eunora/features/analysis/domain/models/analysis_period.dart';
import 'package:eunora/features/analysis/domain/models/hrt_change_result.dart';
import 'package:eunora/features/analysis/domain/models/pattern_result.dart';
import 'package:eunora/features/analysis/presentation/providers/analysis_provider.dart';
import 'package:eunora/features/analysis/presentation/providers/hrt_change_provider.dart';
import 'package:eunora/features/analysis/presentation/providers/pattern_provider.dart';
import 'package:eunora/features/analysis/services/analysis_engine.dart';
import 'package:eunora/features/analysis/services/hrt_change_analyzer.dart';
import 'package:eunora/features/analysis/services/pattern_engine.dart';
import 'package:eunora/features/onboarding/domain/models/medication.dart';
import 'package:eunora/features/onboarding/presentation/providers/medications_provider.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  final List<DailyLog>? customLogs;
  final List<Medication>? customMeds;
  final HrtAnalysisResult? customHrtResult;

  const AnalyticsPage({
    super.key,
    this.customLogs,
    this.customMeds,
    this.customHrtResult,
  });

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  bool _isSufficient = false; // Overwritten dynamically by data check
  int _selectedPeriodIndex = 1; // 30 days selected by default

  List<DailyLog> _allLogs = [];
  bool _isLoadingData = true;

  // Personalized Heatmap thresholds computed dynamically
  double _q1 = 1.66;
  double _q2 = 3.33;

  @override
  void initState() {
    super.initState();
    if (widget.customLogs != null) {
      _processLogs(widget.customLogs!);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadData();
      });
    }
  }

  @override
  void didUpdateWidget(covariant AnalyticsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.customLogs != oldWidget.customLogs && widget.customLogs != null) {
      _processLogs(widget.customLogs!);
    }
  }

  void _processLogs(List<DailyLog> logs) {
    final completedLogs = logs.where((l) => l.isCompleted).toList();
    completedLogs.sort((a, b) => a.date.compareTo(b.date));

    final DateTime ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));
    final List<double> dailyLoadsLast90Days = [];
    for (final log in completedLogs) {
      if (log.date.isAfter(ninetyDaysAgo) && log.symptoms.isNotEmpty) {
        double totalIntensity = 0.0;
        for (final s in log.symptoms) {
          totalIntensity += s.intensity?.toDouble() ??
              (s.severity == 'Mild' ? 1.0 : s.severity == 'Moderate' ? 3.0 : 5.0);
        }
        dailyLoadsLast90Days.add(totalIntensity / log.symptoms.length);
      }
    }

    double q1 = 1.66;
    double q2 = 3.33;
    if (dailyLoadsLast90Days.isNotEmpty) {
      final sorted = List<double>.from(dailyLoadsLast90Days)..sort();
      q1 = _percentile(sorted, 33);
      q2 = _percentile(sorted, 66);
    }

    final bool hasSufficient = completedLogs.length >= 7;

    if (mounted) {
      setState(() {
        _allLogs = completedLogs;
        _q1 = q1;
        _q2 = q2;
        _isSufficient = hasSufficient;
        _isLoadingData = false;
      });
    } else {
      _allLogs = completedLogs;
      _q1 = q1;
      _q2 = q2;
      _isSufficient = hasSufficient;
      _isLoadingData = false;
    }
  }

  Future<void> _loadData() async {
    if (widget.customLogs != null) {
      _processLogs(widget.customLogs!);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
      return;
    }

    setState(() {
      _isLoadingData = true;
    });

    try {
      final firestore = ref.read(firestoreServiceProvider);
      // Fetch 180 days to fully cover 90-day threshold requirements and trend baselines
      final start = DateTime.now().subtract(const Duration(days: 180));
      final rawLogs = await firestore.getDailyLogsHistory(user.uid, start, DateTime.now());
      _processLogs(rawLogs);
    } catch (e) {
      debugPrint("Error loading analytics logs: $e");
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  AnalysisPeriod _getSelectedPeriod() {
    switch (_selectedPeriodIndex) {
      case 0:
        return AnalysisPeriod.days7;
      case 1:
        return AnalysisPeriod.days30;
      case 2:
        return AnalysisPeriod.days90;
      default:
        return AnalysisPeriod.days30;
    }
  }

  double _percentile(List<double> sorted, double percentile) {
    if (sorted.isEmpty) return 0.0;
    final double index = (percentile / 100.0) * (sorted.length - 1);
    final int low = index.floor();
    final int high = index.ceil();
    if (low == high) return sorted[low];
    return sorted[low] + (index - low) * (sorted[high] - sorted[low]);
  }

  int _getPeriodDays() {
    switch (_selectedPeriodIndex) {
      case 0:
        return 7;
      case 1:
        return 30;
      case 2:
        return 90;
      default:
        return 30;
    }
  }

  bool get _isTodayLogged {
    final now = DateTime.now();
    return _allLogs.any((log) =>
        log.date.year == now.year &&
        log.date.month == now.month &&
        log.date.day == now.day &&
        log.isCompleted);
  }

  List<DailyLog> _getFilteredLogs() {
    final int days = _getPeriodDays();
    final DateTime cutoff = DateTime.now().subtract(Duration(days: days));
    return _allLogs.where((log) => log.date.isAfter(cutoff)).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F5F0),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
      );
    }

    final isPremium = ref.watch(premiumGuardProvider);

    final period = _getSelectedPeriod();
    final periodDays = _getPeriodDays();

    final analysisEngine = ref.watch(analysisEngineProvider);
    final patternEngine = ref.watch(patternEngineProvider);

    final analysis = analysisEngine.analyzeWindow(logs: _allLogs, period: period);
    final analysis30d = period == AnalysisPeriod.days30
        ? analysis
        : analysisEngine.analyzeWindow(logs: _allLogs, period: AnalysisPeriod.days30);

    final patternResult = patternEngine.analyze(logs: _allLogs, period: period);
    final patternResult30d = period == AnalysisPeriod.days30
        ? patternResult
        : patternEngine.analyze(logs: _allLogs, period: AnalysisPeriod.days30);

    final medicationsState = ref.watch(medicationsProvider);
    final medications = widget.customMeds ?? medicationsState.medications;
    final bool isHrtSetUp = medications.isNotEmpty;

    HrtAnalysisResult? hrtResult = widget.customHrtResult;
    if (hrtResult == null && isHrtSetUp) {
      final hrtAsync = ref.watch(hrtAnalysisResultProvider);
      hrtResult = hrtAsync.valueOrNull;
      if (hrtResult == null && widget.customLogs != null) {
        hrtResult = const HrtChangeAnalyzer().analyze(
          doseChanges: const [],
          medications: medications,
          logs: _allLogs,
        );
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // State Switcher (Sticky/Interactive for review)
              StateSwitcherWidget(
                isSufficient: _isSufficient,
                onStateChanged: (val) => setState(() => _isSufficient = val),
              ),
              const SizedBox(height: 24),

              // Header Section
              Text(
                'Your Insights',
                style: GoogleFonts.notoSerif(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Understanding your body's rhythm.",
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Time Period Selector
              PeriodSelectorWidget(
                selectedPeriodIndex: _selectedPeriodIndex,
                onPeriodChanged: (idx) => setState(() => _selectedPeriodIndex = idx),
              ),
              const SizedBox(height: 24),

              // Section 1: Symptom Frequency
              SymptomFrequencyCard(
                allLogs: _allLogs,
                q1: _q1,
                q2: _q2,
                periodDays: periodDays,
              ),
              const SizedBox(height: 24),

              // Section 2: Most Frequent Symptoms
              MostFrequentSymptomsCard(
                filteredLogs: _getFilteredLogs(),
                periodDays: periodDays,
                loggedDaysCount: analysis.loggedDaysCount,
              ),
              const SizedBox(height: 24),

              // Section 3: Severity Trend
              SeverityTrendCard(
                filteredLogs: _getFilteredLogs(),
                periodDays: periodDays,
                loggedDaysCount: analysis.loggedDaysCount,
              ),
              const SizedBox(height: 24),

              // Section 4: What Affects You?
              WhatAffectsYouCard(
                patternResult: patternResult,
                selectedPeriod: period,
                isSleepTrusted: analysis.isSleepTrusted,
                loggedDaysCount: analysis.loggedDaysCount,
                isPremium: isPremium,
                onSeeAllEffects: () => context.push('/insights'),
              ),
              const SizedBox(height: 24),

              // Section 5: Recommendations (Only shown when sufficient data)
              if (_isSufficient) ...[
                _buildRecommendationsSection(),
                const SizedBox(height: 24),
              ],

              // Section 5b: AI Correlations & HRT Impact
              if (_isSufficient && (patternResult.hasPatterns || patternResult.buildingItems.isNotEmpty)) ...[
                _buildAiCapabilityBanner(),
                const SizedBox(height: 12),
                _buildDisclaimerBar(),
                const SizedBox(height: 20),
              ],
              AiCorrelationsHrtCard(
                patternResult: patternResult30d,
                hrtResult: hrtResult,
                isHrtSetUp: isHrtSetUp,
                loggedDaysCount: analysis30d.loggedDaysCount,
                isPremium: isPremium,
                onSeeAllInsights: () => context.push('/insights'),
              ),
              const SizedBox(height: 24),

              // Section 6: Menopause Passport / PDF Report
              _buildPdfReportSection(isPremium),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Widget Builders
  // ---------------------------------------------------------------------------

  Widget _buildRecommendationsSection() {
    return const RecommendationSectionWidget(
      children: [
        RecommendationItemWidget(label: 'Try evening exercises'),
        SizedBox(height: 8),
        RecommendationItemWidget(label: 'Track water intake'),
        SizedBox(height: 8),
        RecommendationItemWidget(label: 'Stress management tips'),
      ],
    );
  }

  Widget _buildPdfReportSection(bool isPremium) {
    final eligibilityAsync = ref.watch(passportScreenControllerProvider);

    return eligibilityAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (eligibility) {
        if (!eligibility.hasMinimumData) {
          // Passport needs 30 days of data card (replacing whole PDF card)
          final int logged = eligibility.totalDays;
          final int remaining = eligibility.daysRemaining;
          final int percent = ((logged / 30.0) * 100).round().clamp(0, 100);

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.import_contacts,
                        color: AppTheme.outline.withOpacity(0.2),
                        size: 64,
                      ),
                      const Positioned(
                        bottom: 0,
                        right: 0,
                        child: Icon(
                          Icons.schedule,
                          color: AppTheme.primary,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Your Passport needs 30 days of data',
                  style: GoogleFonts.notoSerif(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "You're $remaining days away. Keep logging daily to compile your clinical clinician-ready report.",
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: const Color(0xFF7F756E),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Progress bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$logged of 30 days',
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: logged / 30.0,
                    minHeight: 6,
                    backgroundColor: AppTheme.surfaceContainer,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFDAD3)),
                  ),
                ),
                if (!_isTodayLogged) ...[
                  const SizedBox(height: 24),
                  // Log Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await context.push('/daily-logging', extra: DateTime.now());
                        _loadData();
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFFFFDAD3),
                        foregroundColor: const Color(0xFF341009),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Log today',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        } else {
          // Sufficient Data state: active share doctor card
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.surfaceContainer),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDDDF5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.medical_information,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Share with Your Doctor',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Generate a comprehensive report of your symptoms and triggers.',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handlePdfGeneration(isPremium),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: Text(
                      'Generate PDF Report',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Future<void> _handlePdfGeneration(bool isPremium) async {
    if (!isPremium) {
      context.push('/premium-upgrade');
      return;
    }

    final int days = _getPeriodDays();
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    final File? file = await ref.read(passportProvider.notifier).generatePassportFile(
      startDate: startDate,
      endDate: endDate,
    );

    if (mounted && file != null) {
      context.push('/passport/preview', extra: file);
    }
  }
}

// ---------------------------------------------------------------------------
// Dynamic Severity Trend Curve Painter
// ---------------------------------------------------------------------------

class DynamicTrendPainter extends CustomPainter {
  final List<double?> points;
  final int? selectedIndex;

  DynamicTrendPainter({required this.points, this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, size.height),
        [
          const Color(0xFFEDDDF5).withOpacity(0.8),
          const Color(0xFFEDDDF5).withOpacity(0.0),
        ],
      )
      ..style = PaintingStyle.fill;

    final path = Path();
    final double stepX = size.width / (points.length - 1);

    // Filter index coordinates to draw the path line
    bool first = true;
    for (int i = 0; i < points.length; i++) {
      final val = points[i];
      if (val != null) {
        // Map Y axis fixed from 1.0 (bottom) to 5.0 (top)
        final double yRatio = (val - 1.0) / 4.0;
        final double yPos = size.height - (size.height * yRatio.clamp(0.0, 1.0));
        final double xPos = i * stepX;

        if (first) {
          path.moveTo(xPos, yPos);
          first = false;
        } else {
          path.lineTo(xPos, yPos);
        }
      }
    }

    if (!first) {
      canvas.drawPath(path, paint);

      // Create a closed fill path only under the line elements
      final fillPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw coordinate dots on the curve for every third point to align with mocks
    final dotPaint = Paint()
      ..color = const Color(0xFF814F45)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final selectedDotPaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i += max(1, points.length ~/ 5)) {
      if (i < points.length) {
        final val = points[i];
        if (val != null) {
          final double yRatio = (val - 1.0) / 4.0;
          final double yPos = size.height - (size.height * yRatio.clamp(0.0, 1.0));
          final double xPos = i * stepX;
          canvas.drawCircle(Offset(xPos, yPos), 3.5, dotPaint);
          canvas.drawCircle(Offset(xPos, yPos), 1.5, borderPaint);
        }
      }
    }

    // Highlight selected interactive point
    if (selectedIndex != null && selectedIndex! < points.length) {
      final val = points[selectedIndex!];
      if (val != null) {
        final double yRatio = (val - 1.0) / 4.0;
        final double yPos = size.height - (size.height * yRatio.clamp(0.0, 1.0));
        final double xPos = selectedIndex! * stepX;
        canvas.drawCircle(Offset(xPos, yPos), 6.0, selectedDotPaint);
        canvas.drawCircle(Offset(xPos, yPos), 3.0, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DynamicTrendPainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// AI Insights Correlations – inline widgets on AnalyticsPage
// ---------------------------------------------------------------------------

extension _CorrelationWidgets on _AnalyticsPageState {
  Widget _buildAiCapabilityBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF67594E), Color(0xFF817266), Color(0xFF655A6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF67594E).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Eunora AI has found patterns in your data',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Minimum 7 events required per insight · Updated weekly',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF856404).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFF856404),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'These patterns are for informational purposes only. Not medical advice. Discuss with your doctor.',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: const Color(0xFF856404),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
