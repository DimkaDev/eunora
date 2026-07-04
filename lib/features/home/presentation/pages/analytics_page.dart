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

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  bool _isSufficient = false; // Overwritten dynamically by data check
  int _selectedPeriodIndex = 1; // 30 days selected by default

  List<DailyLog> _allLogs = [];
  bool _isLoadingData = true;

  // Selected interactive point index and value for Severity Trend chart
  int? _selectedTrendDayIndex;
  double? _selectedTrendValue;

  // Personalized Heatmap thresholds computed dynamically
  double _q1 = 1.66;
  double _q2 = 3.33;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingData = true;
    });

    try {
      final firestore = ref.read(firestoreServiceProvider);
      // Fetch 180 days to fully cover 90-day threshold requirements and trend baselines
      final start = DateTime.now().subtract(const Duration(days: 180));
      final logs = await firestore.getDailyLogsHistory(user.uid, start, DateTime.now());

      // Sort logs oldest first
      logs.sort((a, b) => a.date.compareTo(b.date));

      // Calculate heatmap thresholds using trailing 90 days of non-empty loads
      final DateTime ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));
      final List<double> dailyLoadsLast90Days = [];
      for (final log in logs) {
        if (log.date.isAfter(ninetyDaysAgo) && log.symptoms.isNotEmpty) {
          double totalIntensity = 0.0;
          for (final s in log.symptoms) {
            totalIntensity += s.intensity?.toDouble() ?? (s.severity == 'Mild' ? 1.0 : s.severity == 'Moderate' ? 3.0 : 5.0);
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

      // Check if we have sufficient data (at least 7 days logged all-time)
      final bool hasSufficient = logs.length >= 7;

      if (mounted) {
        setState(() {
          _allLogs = logs;
          _q1 = q1;
          _q2 = q2;
          _isSufficient = hasSufficient;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading analytics logs: $e");
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
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
              _buildStateSwitcher(),
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
              _buildPeriodSelector(),
              const SizedBox(height: 24),

              // Section 1: Symptom Frequency
              _buildSymptomFrequencyCard(),
              const SizedBox(height: 24),

              // Section 2: Most Frequent Symptoms
              _buildMostFrequentSymptomsCard(),
              const SizedBox(height: 24),

              // Section 3: Severity Trend
              _buildSeverityTrendCard(),
              const SizedBox(height: 24),

              // Section 4: What Affects Your Symptoms / AI Insights
              _buildAiInsightsSection(isPremium),
              const SizedBox(height: 24),

              // Section 5: Recommendations (Only shown when sufficient data)
              if (_isSufficient) ...[
                _buildRecommendationsSection(),
                const SizedBox(height: 24),
              ],

              // Section 5b: AI Correlations (Only shown when sufficient data)
              if (_isSufficient) ...[
                _buildAiCapabilityBanner(),
                const SizedBox(height: 12),
                _buildDisclaimerBar(),
                const SizedBox(height: 20),
                _buildCorrelationsSection(isPremium),
                const SizedBox(height: 24),
              ],

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

  Widget _buildStateSwitcher() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DASHBOARD STATE',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppTheme.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _isSufficient
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFDAD6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _isSufficient ? 'SUFFICIENT DATA' : 'INSUFFICIENT DATA',
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: _isSufficient
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFBA1A1A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isSufficient = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !_isSufficient ? AppTheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        'Insufficient (Empty)',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: !_isSufficient ? FontWeight.bold : FontWeight.normal,
                          color: !_isSufficient ? Colors.white : AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isSufficient = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _isSufficient ? AppTheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        'Sufficient (Active)',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: _isSufficient ? FontWeight.bold : FontWeight.normal,
                          color: _isSufficient ? Colors.white : AppTheme.onSurfaceVariant,
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

  Widget _buildPeriodSelector() {
    final periods = ['7 days', '30 days', '90 days'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: List.generate(periods.length, (index) {
          final isSelected = _selectedPeriodIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriodIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    periods[index],
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSymptomFrequencyCard() {
    // Fixed 28-day window (4 rows x 7 cols)
    final DateTime today = DateTime.now();
    final DateTime startDate = today.subtract(const Duration(days: 27));

    final Map<String, double?> dailyLoads = {};
    for (int i = 0; i < 28; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      dailyLoads[dateKey] = null;
    }

    int loggedDaysCount = 0;
    for (final log in _allLogs) {
      if (log.date.isAfter(startDate.subtract(const Duration(days: 1))) && log.date.isBefore(today.add(const Duration(days: 1)))) {
        final dateKey = "${log.date.year}-${log.date.month.toString().padLeft(2, '0')}-${log.date.day.toString().padLeft(2, '0')}";
        if (log.symptoms.isNotEmpty) {
          double sumIntensity = 0.0;
          for (final s in log.symptoms) {
            sumIntensity += s.intensity?.toDouble() ?? (s.severity == 'Mild' ? 1.0 : s.severity == 'Moderate' ? 3.0 : 5.0);
          }
          dailyLoads[dateKey] = sumIntensity / log.symptoms.length;
        } else {
          dailyLoads[dateKey] = 0.0;
        }
        loggedDaysCount++;
      }
    }

    final periodLabel = "Last 28 Days";

    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SYMPTOM FREQUENCY',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    periodLabel,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$loggedDaysCount/28',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  Text(
                    'DAYS LOGGED',
                    style: GoogleFonts.manrope(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Heatmap grid (4 rows x 7 cols)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 28,
            itemBuilder: (context, index) {
              final cellDate = startDate.add(Duration(days: index));
              final cellKey = "${cellDate.year}-${cellDate.month.toString().padLeft(2, '0')}-${cellDate.day.toString().padLeft(2, '0')}";
              final dailyLoad = dailyLoads[cellKey];

              Color color = const Color(0xFFF7F5F0); // Default cream no-data
              Border? border = Border.all(color: AppTheme.outlineVariant.withOpacity(0.3));

              if (dailyLoad != null) {
                border = null;
                if (dailyLoad <= _q1) {
                  color = const Color(0xFFD8C9E0).withOpacity(0.4); // Soft lavender 40%
                } else if (dailyLoad <= _q2) {
                  color = const Color(0xFFE8A89B).withOpacity(0.55); // Peachy Rose 55%
                } else {
                  color = const Color(0xFFE8A89B); // Peachy Rose 100%
                }
              }

              return Container(
                decoration: BoxDecoration(
                  color: color,
                  border: border,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Legend Bar
          Row(
            children: [
              Text(
                'FEW',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.outline,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFD8C9E0),
                        Color(0xFFE8A89B),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'MANY',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMostFrequentSymptomsCard() {
    final filteredLogs = _getFilteredLogs();

    final Map<String, int> symptomDays = {};
    final Map<String, double> symptomIntensitySum = {};
    final Map<String, String> symptomNames = {};

    for (final log in filteredLogs) {
      final Set<String> symptomsLoggedToday = {};
      for (final s in log.symptoms) {
        final id = s.symptom.id;
        symptomsLoggedToday.add(id);
        symptomNames[id] = s.symptom.name;
        final intensity = s.intensity?.toDouble() ?? (s.severity == 'Mild' ? 1.0 : s.severity == 'Moderate' ? 3.0 : 5.0);
        symptomIntensitySum[id] = (symptomIntensitySum[id] ?? 0.0) + intensity;
      }

      for (final id in symptomsLoggedToday) {
        symptomDays[id] = (symptomDays[id] ?? 0) + 1;
      }
    }

    final List<Map<String, dynamic>> ranks = [];
    symptomDays.forEach((id, days) {
      final avgIntensity = symptomIntensitySum[id]! / days;
      ranks.add({
        'id': id,
        'name': symptomNames[id] ?? id,
        'days_logged': days,
        'avg_intensity': avgIntensity,
      });
    });

    // Sort: days_logged DESC, tie-break avg_intensity DESC
    ranks.sort((a, b) {
      final int daysCompare = (b['days_logged'] as int).compareTo(a['days_logged'] as int);
      if (daysCompare != 0) return daysCompare;
      return (b['avg_intensity'] as double).compareTo(a['avg_intensity'] as double);
    });

    final top5 = ranks.take(5).toList();
    final topDaysCount = top5.isNotEmpty ? (top5.first['days_logged'] as int) : 1;

    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MOST FREQUENT SYMPTOMS',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),

          if (top5.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No symptoms logged in this period.',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...List.generate(top5.length, (index) {
              final item = top5[index];
              final String name = item['name'] as String;
              final int days = item['days_logged'] as int;
              final double factor = days / topDaysCount;

              Color color = AppTheme.primary;
              if (index == 1) {
                color = const Color(0xFF814F45);
              } else if (index == 2) {
                color = const Color(0xFFD0C1D8);
              } else if (index >= 3) {
                color = AppTheme.outline;
              }

              return Padding(
                padding: EdgeInsets.only(bottom: index == top5.length - 1 ? 0 : 16),
                child: _buildSymptomBar(
                  name,
                  '$days day${days == 1 ? '' : 's'}',
                  factor,
                  color,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSymptomBar(String label, String value, double factor, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: 10,
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: factor.clamp(0.01, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeverityTrendCard() {
    final filteredLogs = _getFilteredLogs();
    final int days = _getPeriodDays();

    // Map logs by date (midnight) for quick lookup
    final Map<String, double> dailyLoads = {};
    for (final log in filteredLogs) {
      final key = "${log.date.year}-${log.date.month.toString().padLeft(2, '0')}-${log.date.day.toString().padLeft(2, '0')}";
      if (log.symptoms.isNotEmpty) {
        double sumIntensity = 0.0;
        for (final s in log.symptoms) {
          sumIntensity += s.intensity?.toDouble() ?? (s.severity == 'Mild' ? 1.0 : s.severity == 'Moderate' ? 3.0 : 5.0);
        }
        dailyLoads[key] = sumIntensity / log.symptoms.length;
      }
    }

    // Build timeline points: Gaps (no-log days) are kept as null
    final DateTime today = DateTime.now();
    final DateTime startDate = today.subtract(Duration(days: days - 1));

    final List<double?> rawPoints = [];
    for (int i = 0; i < days; i++) {
      final d = startDate.add(Duration(days: i));
      final key = "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      rawPoints.add(dailyLoads[key]);
    }

    // Process points according to X-axis density:
    // 7-day view -> one point per day, raw values
    // 30/90-day view -> 3-day rolling average per point
    final List<double?> processedPoints = [];
    if (days == 7) {
      processedPoints.addAll(rawPoints);
    } else {
      // 3-day rolling average
      for (int i = 0; i < rawPoints.length; i++) {
        final List<double> window = [];
        for (int offset = -2; offset <= 0; offset++) {
          final idx = i + offset;
          if (idx >= 0 && rawPoints[idx] != null) {
            window.add(rawPoints[idx]!);
          }
        }
        if (window.isNotEmpty) {
          processedPoints.add(window.reduce((a, b) => a + b) / window.length);
        } else {
          processedPoints.add(null);
        }
      }
    }

    // Calculate trend percentage: split period at its midpoint
    final int halfIndex = days ~/ 2;
    final List<double> firstHalf = [];
    final List<double> secondHalf = [];

    for (int i = 0; i < rawPoints.length; i++) {
      final val = rawPoints[i];
      if (val != null) {
        if (i < halfIndex) {
          firstHalf.add(val);
        } else {
          secondHalf.add(val);
        }
      }
    }

    bool showTrend = firstHalf.length >= 4 && secondHalf.length >= 4;
    String trendText = "Keep logging to see your trend";
    Color trendColor = AppTheme.outline;
    IconData trendIcon = Icons.trending_flat;

    if (showTrend) {
      final double avgFirst = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
      final double avgSecond = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

      if (avgFirst > 0.0) {
        final double pct = (avgFirst - avgSecond) / avgFirst * 100;
        if (pct >= 0) {
          trendText = "${pct.toStringAsFixed(0)}% improvement";
          trendColor = const Color(0xFF2E7D32); // Success Green
          trendIcon = Icons.trending_down;
        } else {
          trendText = "${pct.abs().toStringAsFixed(0)}% increase";
          trendColor = const Color(0xFFE8A89B); // Neutral Peachy Rose
          trendIcon = Icons.trending_up;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SEVERITY TREND',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: AppTheme.onSurface,
                ),
              ),
              Row(
                children: [
                  Icon(trendIcon, size: 14, color: trendColor),
                  const SizedBox(width: 4),
                  Text(
                    trendText,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: trendColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dynamic interactive trend painter
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final double stepX = width / (processedPoints.length - 1);

              return GestureDetector(
                onPanUpdate: (details) {
                  final double localX = details.localPosition.dx.clamp(0.0, width);
                  final int index = (localX / stepX).round().clamp(0, processedPoints.length - 1);
                  final double? val = processedPoints[index];
                  if (val != null && mounted) {
                    setState(() {
                      _selectedTrendDayIndex = index;
                      _selectedTrendValue = val;
                    });
                  }
                },
                onTapUp: (details) {
                  final double localX = details.localPosition.dx.clamp(0.0, width);
                  final int index = (localX / stepX).round().clamp(0, processedPoints.length - 1);
                  final double? val = processedPoints[index];
                  if (val != null && mounted) {
                    setState(() {
                      _selectedTrendDayIndex = index;
                      _selectedTrendValue = val;
                    });
                  }
                },
                child: Column(
                  children: [
                    SizedBox(
                      height: 112,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: DynamicTrendPainter(
                          points: processedPoints,
                          selectedIndex: _selectedTrendDayIndex,
                        ),
                      ),
                    ),
                    if (_selectedTrendDayIndex != null && _selectedTrendValue != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${days - 1 - _selectedTrendDayIndex!} days ago: Severity Load ${_selectedTrendValue!.toStringAsFixed(1)} (Average out of 5)',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$days days ago',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.outline,
                ),
              ),
              Text(
                'Today',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsightsSection(bool isPremium) {
    if (!_isSufficient) {
      // Insufficient Data state: building insights empty state card
      final int logsCount = _allLogs.length;
      final int percent = ((logsCount / 7.0) * 100).round().clamp(0, 100);
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
            const SizedBox(height: 8),
            // Glowing pulsing stars icon
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8C9E0).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppTheme.primary,
                      size: 48,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD8C9E0),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Your insights are building',
              style: GoogleFonts.notoSerif(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Log your symptoms for 7 days and Eunora will start finding patterns. You're on day $logsCount.",
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
                  '$logsCount of 7 days',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryContainer,
                  ),
                ),
                Text(
                  '$percent%',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: logsCount / 7.0,
                minHeight: 6,
                backgroundColor: AppTheme.surfaceContainer,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryContainer),
              ),
            ),
            const SizedBox(height: 24),

            // Log Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.push('/daily-logging', extra: DateTime.now());
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
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
        ),
      );
    } else {
      // Fetch dynamic insights correlations directly from the insightsProvider
      final insightsAsync = ref.watch(insightsProvider);

      return insightsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
        data: (insights) {
          // Filter displayable trigger correlations only
          final displayableTriggers = insights.where((i) => i.type == InsightType.trigger && i.direction != null).take(3).toList();
          
          if (displayableTriggers.isEmpty) {
            // Hide section entirely on dashboard teaser if 0 displayable correlations exist
            return const SizedBox.shrink();
          }

          return Container(
            padding: const EdgeInsets.all(20),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'WHAT AFFECTS YOU?',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    InkWell(
                      onTap: () => context.push('/insights'),
                      child: Text(
                        'See all affects',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                ...List.generate(displayableTriggers.length, (index) {
                  final item = displayableTriggers[index];
                  final bool needsLock = !isPremium;

                  IconData icon = Icons.auto_awesome;
                  Color iconBg = const Color(0xFFEDDDF5);
                  Color iconColor = const Color(0xFF211828);

                  if (item.triggerId == 't_caffeine') {
                    icon = Icons.coffee;
                    iconBg = const Color(0xFFEFEBE9); // brown/cream
                    iconColor = const Color(0xFF5D4037);
                  } else if (item.triggerId == 't_alcohol') {
                    icon = Icons.wine_bar;
                    iconBg = const Color(0xFFFFEBEE); // soft red
                    iconColor = const Color(0xFFC2185B);
                  } else if (item.triggerId == 't_stress') {
                    icon = Icons.psychology;
                    iconBg = const Color(0xFFFFF3E0); // soft orange
                    iconColor = const Color(0xFFE65100);
                  } else if (item.triggerId == 't_exercise') {
                    icon = Icons.fitness_center;
                    iconBg = const Color(0xFFE8F5E9); // soft green
                    iconColor = const Color(0xFF2E7D32);
                  } else if (item.triggerId == 't_weather') {
                    icon = Icons.thermostat;
                    iconBg = const Color(0xFFE1F5FE); // soft blue
                    iconColor = const Color(0xFF0288D1);
                  } else if (item.triggerId == 't_sleep') {
                    icon = Icons.bedtime;
                    iconBg = const Color(0xFFEDE7F6); // soft purple/blue
                    iconColor = const Color(0xFF512DA8);
                  }

                  final String triggerName = item.label.split(' → ').first;
                  String symptomText = item.label.split(' → ').last;

                  // Strip off test suffix info e.g. " (+1.5 Hot Flashes same day (56% correlation, based on 7 events))"
                  if (symptomText.contains(' (')) {
                    symptomText = symptomText.split(' (').first;
                  }

                  // Determine if this is a positive effect for the user.
                  // For example, if symptom severity decreased (negative correlation e.g. -1.2 Hot Flashes) or sleep improved.
                  // If effectSize is negative (symptoms improved/decreased) -> positive impact!
                  // If symptom is "Sleep quality" and effectSize is positive (sleep quality increased) -> positive impact!
                  final double effectSize = item.effectSize ?? 0.0;
                  final bool isSymptomImprovement = item.direction == 'negative'; // negative effect size = lower symptom severity
                  final bool isPositiveOutcome = isSymptomImprovement || (item.symptomId == 's_sleep' && effectSize > 0);

                  // Determine if this correlation is High Confidence
                  final bool isHighConfidence = (item.eventCount ?? 0) >= 14 && (item.correlationPercent ?? 0) >= 70;

                  return Padding(
                    padding: EdgeInsets.only(bottom: index == displayableTriggers.length - 1 ? 0 : 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: iconBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            color: iconColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text.rich(
                                      TextSpan(
                                        text: needsLock ? 'Premium correlation found for ' : 'On days with ',
                                        children: [
                                          TextSpan(
                                            text: triggerName,
                                            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text: needsLock ? '. Unlock to see impact.' : ', ',
                                          ),
                                          if (!needsLock)
                                            TextSpan(
                                              text: symptomText,
                                              style: GoogleFonts.manrope(
                                                fontWeight: FontWeight.normal,
                                                color: isPositiveOutcome ? const Color(0xFF2E7D32) : AppTheme.onSurface,
                                              ),
                                            ),
                                        ],
                                      ),
                                      style: GoogleFonts.manrope(
                                        fontSize: 13,
                                        height: 1.5,
                                        color: AppTheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  if (isHighConfidence && !needsLock) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'High confidence',
                                        style: GoogleFonts.manrope(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF2E7D32),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (needsLock) ...[
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () => context.push('/premium-upgrade'),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.lock_outline, size: 12, color: AppTheme.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Unlock pattern',
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      );
    }
  }

  Widget _buildRecommendationsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F8F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0ECE0).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECOMMENDED FOR YOU',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildRecommendationItem('Try evening exercises'),
          const SizedBox(height: 8),
          _buildRecommendationItem('Track water intake'),
          const SizedBox(height: 8),
          _buildRecommendationItem('Stress management tips'),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurface,
            ),
          ),
          const Icon(
            Icons.north_east,
            size: 14,
            color: AppTheme.primary,
          ),
        ],
      ),
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
                const SizedBox(height: 24),

                // Log Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/daily-logging', extra: DateTime.now());
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

  Widget _buildCorrelationsSection(bool isPremium) {
    final insightsAsync = ref.watch(insightsProvider);

    return insightsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (insights) {
        final displayableTriggers = insights.where((i) => i.type == InsightType.trigger && i.direction != null).take(3).toList();

        if (displayableTriggers.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AI CORRELATIONS',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: AppTheme.onSurface,
                  ),
                ),
                InkWell(
                  onTap: () => context.push('/insights'),
                  child: Text(
                    'See all insights',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...displayableTriggers.map((item) {
              final bool needsLock = !isPremium;

              IconData icon = Icons.auto_awesome;
              Color iconColor = AppTheme.primary;

              if (item.triggerId == 't_caffeine') {
                icon = Icons.coffee;
                iconColor = const Color(0xFF8D6E63); // Brown
              } else if (item.triggerId == 't_alcohol') {
                icon = Icons.wine_bar;
                iconColor = const Color(0xFFD32F2F); // Red
              } else if (item.triggerId == 't_stress') {
                icon = Icons.psychology;
                iconColor = const Color(0xFFF59E0B); // Orange
              } else if (item.triggerId == 't_exercise') {
                icon = Icons.fitness_center;
                iconColor = const Color(0xFF388E3C); // Green
              } else if (item.triggerId == 't_weather') {
                icon = Icons.thermostat;
                iconColor = AppTheme.primary;
              } else if (item.triggerId == 't_sleep') {
                icon = Icons.bedtime;
                iconColor = const Color(0xFF3F51B5); // Blue
              }

              final String triggerName = item.label.split(' → ').first;
              String symptomText = item.label.split(' → ').last;

              // Strip off test suffix info e.g. " (+1.5 Hot Flashes same day (56% correlation, based on 7 events))"
              if (symptomText.contains(' (')) {
                symptomText = symptomText.split(' (').first;
              }

              final double effectSize = item.effectSize ?? 0.0;
              final bool isSymptomImprovement = item.direction == 'negative';
              final bool isPositiveOutcome = isSymptomImprovement || (item.symptomId == 's_sleep' && effectSize > 0);

              Color accentColor = const Color(0xFFE8A89B); // Peachy rose for positive correlation
              if (isPositiveOutcome) {
                accentColor = const Color(0xFFA8D5BA); // Success Green
              }

              final String textPrefix = needsLock ? 'Unlock to see pattern details' : symptomText.split(' ').first;
              final String textSuffix = needsLock ? '' : ' ' + symptomText.split(' ').skip(1).join(' ');

              final bool isHighConfidence = (item.eventCount ?? 0) >= 14 && (item.correlationPercent ?? 0) >= 70;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildCorrelationCard(
                  icon: icon,
                  iconColor: needsLock ? AppTheme.outline : iconColor,
                  title: triggerName,
                  effectTextPrefix: textPrefix,
                  effectTextSuffix: textSuffix,
                  effectColor: needsLock ? AppTheme.outline : (isPositiveOutcome ? const Color(0xFF388E3C) : AppTheme.primary),
                  badgeLabel: needsLock ? 'Locked' : (isPositiveOutcome ? 'Protective factor' : 'Strong link'),
                  badgeBg: needsLock ? AppTheme.surfaceContainer : accentColor.withOpacity(0.15),
                  badgeColor: needsLock ? AppTheme.outline : (isPositiveOutcome ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F)),
                  borderColor: needsLock ? AppTheme.outline : accentColor,
                  correlationPct: (item.correlationPercent ?? 0) / 100.0,
                  correlationLabel: '${item.correlationPercent ?? 0}% correlation',
                  eventsLabel: 'Based on ${item.eventCount ?? 0} events',
                  showBadge: !isHighConfidence,
                  isHighConfidence: isHighConfidence && !needsLock,
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildCorrelationCard({
    String? emoji,
    IconData? icon,
    Color? iconColor,
    required String title,
    required String effectTextPrefix,
    required String effectTextSuffix,
    Color? effectColor,
    required String badgeLabel,
    required Color badgeBg,
    required Color badgeColor,
    required Color borderColor,
    required double correlationPct,
    required String correlationLabel,
    required String eventsLabel,
    String? footnote,
    bool showBadge = true,
    bool isHighConfidence = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: BorderSide(
            color: borderColor,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: icon/emoji + title + badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (emoji != null)
                    Text(emoji, style: const TextStyle(fontSize: 28))
                  else
                    Icon(icon, color: iconColor, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
              if (isHighConfidence)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'High confidence',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                )
              else if (showBadge && badgeLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    badgeLabel,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Effect text (Bolding only the measured change)
          Text.rich(
            TextSpan(
              text: '',
              children: [
                TextSpan(
                  text: effectTextPrefix,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    color: effectColor ?? AppTheme.onSurface,
                  ),
                ),
                TextSpan(
                  text: effectTextSuffix,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.normal,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),

          const SizedBox(height: 12),

          // Progress bar row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                correlationLabel,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppTheme.outline,
                ),
              ),
              Text(
                eventsLabel,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppTheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: correlationPct,
              minHeight: 6,
              backgroundColor: AppTheme.surfaceContainer,
              valueColor: AlwaysStoppedAnimation<Color>(borderColor),
            ),
          ),

          if (footnote != null) ...[
            const SizedBox(height: 12),
            Text(
              footnote,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppTheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
