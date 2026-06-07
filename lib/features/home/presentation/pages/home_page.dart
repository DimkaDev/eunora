import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:eunora/features/onboarding/presentation/providers/medications_provider.dart';
import 'package:eunora/features/onboarding/domain/models/medication.dart';
import 'package:eunora/features/home/presentation/widgets/calendar_hrt_edit_sheet.dart';



class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;
  late final InsightType _insightType;

  // Daily Logging States
  final Map<String, bool> _takenStatus = {};
  final Map<String, String> _takenTime = {};
  final List<Map<String, String>> _loggedSymptoms = [];
  final List<Map<String, dynamic>> _loggedTriggers = [];

  @override
  void initState() {
    super.initState();
    // Choose a random InsightType once during load/initialization
    const types = InsightType.values;
    _insightType = types[Random().nextInt(types.length)];

    // Initialize with standard logs for default mock medications
    _takenStatus['Estradiol Patch'] = false;
    _takenTime['Estradiol Patch'] = '08:30';
    _takenStatus['Progesterone'] = false;
    _takenTime['Progesterone'] = '21:00';
  }

  double _getLoggingProgress(List<Medication> medications) {
    double progress = 0.0;

    // Check mandatory medications (daily or bedtime)
    final mandatoryMeds = medications.where((med) {
      final freq = med.frequency.toLowerCase();
      return freq.contains('daily') || freq.contains('bedtime');
    }).toList();

    if (mandatoryMeds.isEmpty) {
      progress += 0.4;
    } else {
      int takenCount = 0;
      for (final med in mandatoryMeds) {
        if (_takenStatus[med.name] ?? false) {
          takenCount++;
        }
      }
      progress += (0.4 * takenCount) / mandatoryMeds.length;
    }

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


  void _showHrtLoggingSheet(List<Medication> medications) {
    final hrtList = medications.map((med) {
      final isTaken = _takenStatus[med.name] ?? false;
      final time = _takenTime[med.name] ?? '08:00';
      final appType = med.type.displayName;
      
      return {
        'name': med.name,
        'details': '${med.dose.toStringAsFixed(0)} ${med.unit} · $appType',
        'status': isTaken ? 'Taken $time' : 'Not taken',
        'isTaken': isTaken.toString(),
      };
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => CalendarHrtEditSheet(
          initialHrt: hrtList,
          onSave: (updatedList) {
            setState(() {
              for (final updated in updatedList) {
                final name = updated['name'] ?? '';
                final isTaken = updated['isTaken'] == 'true';
                final status = updated['status'] ?? '';
                
                String time = '08:00';
                final match = RegExp(r'(\d{1,2}:\d{2})').firstMatch(status);
                if (match != null) {
                  time = match.group(1) ?? '08:00';
                }

                _takenStatus[name] = isTaken;
                _takenTime[name] = time;
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Doses logged successfully!',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                ),
                backgroundColor: AppTheme.primary,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
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
        final est = result['estradiolTaken'] as bool? ?? false;
        final prog = result['progesteroneTaken'] as bool? ?? false;
        _takenStatus['Estradiol Patch'] = est;
        _takenStatus['Estradiol'] = est;
        _takenStatus['Progesterone'] = prog;
        _takenStatus['Utrogestan'] = prog;
      });
    }
  }

  Widget _buildHomeDashboard(double progress, List<Medication> medications) {
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
                  delay: const Duration(milliseconds: 30),
                  child: MedicationHrtCard(
                    medications: medications,
                    takenStatus: _takenStatus,
                    onTakenStatusChanged: (newStatus) {
                      setState(() {
                        _takenStatus.clear();
                        _takenStatus.addAll(newStatus);
                      });
                    },
                    onManageTap: () => _showHrtLoggingSheet(medications),
                  ),
                ),
                const SizedBox(height: 24),
                FadeInEntrance(
                  delay: const Duration(milliseconds: 60),
                  child: TodaySymptomsCard(
                    loggedSymptoms: _loggedSymptoms,
                    onAddSymptom: _showAddSymptomSheet,
                    onEditSymptom: _showEditSymptomsSheet,
                  ),
                ),
                const SizedBox(height: 24),
                FadeInEntrance(
                  delay: const Duration(milliseconds: 90),
                  child: DailyTriggersCard(
                    loggedTriggers: _loggedTriggers,
                    onAddTrigger: _showAddTriggerSheet,
                    onEditTrigger: _showEditTriggersSheet,
                  ),
                ),
                const SizedBox(height: 24),
                FadeInEntrance(
                  delay: const Duration(milliseconds: 120),
                  child: InsightCard(type: _insightType),
                ),
                const SizedBox(height: 24),
                FadeInEntrance(
                  delay: const Duration(milliseconds: 150),
                  child: const WeeklyPatternsCard(),
                ),
                const SizedBox(height: 24),
                FadeInEntrance(
                  delay: const Duration(milliseconds: 180),
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

  Widget _buildSelectedTab(double progress, List<Medication> medications) {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeDashboard(progress, medications);
      case 1:
        return const CalendarPage();
      case 2:
        return const AnalyticsPage();
      case 3:
        return const PassportPage();
      case 4:
        return const HrtTrackerPage();
      default:
        return _buildHomeDashboard(progress, medications);
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicationsState = ref.watch(medicationsProvider);
    final medications = medicationsState.medications;

    // Auto-populate default medications if completely empty
    if (medications.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.read(medicationsProvider).medications.isEmpty) {
          final refNotifier = ref.read(medicationsProvider.notifier);
          refNotifier.addMedication(Medication(
            name: 'Estradiol Patch',
            type: MedicationType.patch,
            dose: 50,
            unit: 'mcg',
            frequency: 'Twice weekly',
          ));
          refNotifier.addMedication(Medication(
            name: 'Progesterone',
            type: MedicationType.pill,
            dose: 100,
            unit: 'mg',
            frequency: 'Bedtime',
          ));
        }
      });
    }

    final progress = _getLoggingProgress(medications);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_selectedIndex),
                child: _buildSelectedTab(progress, medications),
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

