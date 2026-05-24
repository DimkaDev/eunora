import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/home/presentation/widgets/dashboard_header.dart';
import 'package:eunora/features/home/presentation/widgets/insight_card.dart';
import 'package:eunora/features/home/presentation/widgets/weekly_patterns_card.dart';
import 'package:eunora/features/home/presentation/widgets/insight_teaser_card.dart';
import 'package:eunora/features/home/presentation/widgets/daily_log_card.dart';
import 'package:eunora/features/home/presentation/widgets/medication_hrt_card.dart';
import 'package:eunora/features/home/presentation/widgets/today_symptoms_card.dart';
import 'package:eunora/features/home/presentation/widgets/daily_triggers_card.dart';
import 'package:eunora/features/home/presentation/widgets/symptom_logging_sheet.dart';
import 'package:eunora/features/home/presentation/widgets/trigger_logging_sheet.dart';
import 'package:eunora/features/home/presentation/widgets/edit_symptoms_modal_sheet.dart';
import 'package:eunora/features/home/presentation/widgets/edit_triggers_modal_sheet.dart';
import 'package:eunora/features/home/presentation/pages/calendar_page.dart';
import 'package:eunora/features/home/presentation/pages/analytics_page.dart';
import 'package:eunora/features/home/presentation/pages/passport_page.dart';
import 'package:eunora/features/home/presentation/pages/hrt_tracker_page.dart';
import 'package:eunora/core/utils/animation_system.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late final InsightType _insightType;

  // Daily Logging States
  bool _estradiolTaken = false;
  bool _progesteroneTaken = false;
  final List<Map<String, String>> _loggedSymptoms = [];
  final List<Map<String, dynamic>> _loggedTriggers = [];

  @override
  void initState() {
    super.initState();
    // Choose a random InsightType once during load/initialization
    const types = InsightType.values;
    _insightType = types[Random().nextInt(types.length)];
  }

  double _getLoggingProgress() {
    double progress = 0.0;
    if (_estradiolTaken) progress += 0.2;
    if (_progesteroneTaken) progress += 0.2;
    if (_loggedSymptoms.isNotEmpty) progress += 0.3;
    if (_loggedTriggers.isNotEmpty) progress += 0.3;
    return progress;
  }

  void _showAddSymptomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SymptomLoggingSheet(
        onSave: (name, severity) {
          setState(() {
            final existingIndex = _loggedSymptoms.indexWhere((s) => s['name'] == name);
            if (existingIndex != -1) {
              _loggedSymptoms[existingIndex]['severity'] = severity;
            } else {
              _loggedSymptoms.add({'name': name, 'severity': severity});
            }
          });
        },
      ),
    );
  }

  void _showAddTriggerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TriggerLoggingSheet(
        onSave: (name, value, icon) {
          setState(() {
            final existingIndex = _loggedTriggers.indexWhere((t) => t['name'] == name);
            if (existingIndex != -1) {
              _loggedTriggers[existingIndex]['value'] = value;
            } else {
              _loggedTriggers.add({'name': name, 'value': value, 'icon': icon});
            }
          });
        },
      ),
    );
  }

  void _showEditSymptomsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditSymptomsModalSheet(
        initialSymptoms: _loggedSymptoms,
        onSave: (newSymptoms) {
          setState(() {
            _loggedSymptoms.clear();
            _loggedSymptoms.addAll(newSymptoms);
          });
        },
      ),
    );
  }

  void _showEditTriggersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditTriggersModalSheet(
        initialTriggers: _loggedTriggers,
        onSave: (newTriggers) {
          setState(() {
            _loggedTriggers.clear();
            _loggedTriggers.addAll(newTriggers);
          });
        },
      ),
    );
  }


  void _handleStartOrResumeLogging() async {
    final result = await context.push<Map<String, dynamic>>('/daily-logging');
    if (result != null) {
      setState(() {
        _loggedSymptoms.clear();
        if (result['symptoms'] != null) {
          _loggedSymptoms.addAll(
            (result['symptoms'] as List).map((e) => Map<String, String>.from(e as Map)),
          );
        }
        _loggedTriggers.clear();
        if (result['triggers'] != null) {
          _loggedTriggers.addAll(
            (result['triggers'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
          );
        }
        _estradiolTaken = result['estradiolTaken'] as bool? ?? false;
        _progesteroneTaken = result['progesteroneTaken'] as bool? ?? false;
      });
    }
  }

  Widget _buildHomeDashboard(double progress) {
    return Column(
      children: [
        const DashboardHeader(
          userName: 'Sarah',
          date: 'Wednesday, March 19',
          cycleInfo: '1 week in cycle',
          profileImageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCcyvRmigFQWEnghTEoPCUvu6Lls83qWwGf81JXXAHmxs_PI1albuWzfyX8hJHYDK2oDWVWOWPMCqACZzrOSiUrEriDUDMizBdlzmoikkKEMsviNymTb1SmeDL2M5mjpE7ZBB0lVSTa1Di99-xd5i_L5XTTvhH9uNbS-BEM4dPF7EevWWNXW_jzlWxSVjPjBZ3OPwiDpUtKeUmcOYd5ry2dtceFPJ-WL6Bp-ZEtlShywIcbEgix84xxFqoBGr1QXN6ehV00Hjb-W4c',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
            child: Column(
              children: [
                FadeInEntrance(
                  delay: Duration.zero,
                  child: DailyLogCard(
                    progress: progress,
                    onStartLog: _handleStartOrResumeLogging,
                  ),
                ),
                const SizedBox(height: 24),
                FadeInEntrance(
                  delay: const Duration(milliseconds: 100),
                  child: MedicationHrtCard(
                    estradiolTaken: _estradiolTaken,
                    progesteroneTaken: _progesteroneTaken,
                    onEstradiolChanged: (val) => setState(() => _estradiolTaken = val),
                    onProgesteroneChanged: (val) => setState(() => _progesteroneTaken = val),
                    onManageTap: () => setState(() => _selectedIndex = 4),
                  ),
                ),
                const SizedBox(height: 24),
                FadeInEntrance(
                  delay: const Duration(milliseconds: 150),
                  child: TodaySymptomsCard(
                    loggedSymptoms: _loggedSymptoms,
                    onAddSymptom: _showAddSymptomSheet,
                    onEditSymptom: _showEditSymptomsSheet,
                  ),
                ),
                const SizedBox(height: 24),
                FadeInEntrance(
                  delay: const Duration(milliseconds: 200),
                  child: DailyTriggersCard(
                    loggedTriggers: _loggedTriggers,
                    onAddTrigger: _showAddTriggerSheet,
                    onEditTrigger: _showEditTriggersSheet,
                  ),
                ),
                const SizedBox(height: 24),
                FadeInEntrance(
                  delay: const Duration(milliseconds: 250),
                  child: InsightCard(type: _insightType),
                ),
                const SizedBox(height: 24),
                FadeInEntrance(
                  delay: const Duration(milliseconds: 300),
                  child: const WeeklyPatternsCard(),
                ),
                const SizedBox(height: 24),
                FadeInEntrance(
                  delay: const Duration(milliseconds: 350),
                  child: const InsightTeaserCard(),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedTab(double progress) {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeDashboard(progress);
      case 1:
        return const CalendarPage();
      case 2:
        return const AnalyticsPage();
      case 3:
        return const PassportPage();
      case 4:
        return const HrtTrackerPage();
      default:
        return _buildHomeDashboard(progress);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _getLoggingProgress();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.98, end: 1.0).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_selectedIndex),
                child: _buildSelectedTab(progress),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomNavBar(),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 32),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5F0).withOpacity(0.9),
        border: const Border(top: BorderSide(color: Color(0xFFE7E5E4))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home, 'Home'),
          _buildNavItem(1, Icons.edit_calendar, 'Tracker'),
          _buildNavItem(2, Icons.insights, 'Analytics'),
          _buildNavItem(3, Icons.assignment_ind, 'Passport'),
          _buildNavItem(4, Icons.medication_liquid, 'HRT'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Bounceable(
      onTap: () => setState(() => _selectedIndex = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : const Color(0xFFA8A29E),
              size: 24,
              shadows: isSelected ? [const Shadow(color: AppTheme.primary, blurRadius: 2)] : null,
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.manrope(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: isSelected ? AppTheme.primary : const Color(0xFFA8A29E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

