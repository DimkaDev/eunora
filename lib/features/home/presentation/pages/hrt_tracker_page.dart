import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/onboarding/presentation/providers/medications_provider.dart';
import 'package:eunora/features/onboarding/domain/models/medication.dart';
import 'package:eunora/features/home/presentation/widgets/calendar_hrt_edit_sheet.dart';

class HrtTrackerPage extends ConsumerStatefulWidget {
  const HrtTrackerPage({super.key});

  @override
  ConsumerState<HrtTrackerPage> createState() => _HrtTrackerPageState();
}

class _HrtTrackerPageState extends ConsumerState<HrtTrackerPage> {
  // Navigation / Calendar states
  int _selectedMonthOffset = 0; // 0 = March 2026, 1 = April 2026, 2 = May 2026
  int _selectedDay = 19;

  final List<String> _months = ['March 2026', 'April 2026', 'May 2026'];

  // Logging states for today (March 19)
  final Map<String, bool> _takenStatus = {};
  final Map<String, String> _takenTime = {};

  @override
  void initState() {
    super.initState();
    // Default initial logs
    _takenStatus['Estradiol'] = true;
    _takenTime['Estradiol'] = '08:30';
    _takenStatus['Utrogestan'] = false;
    _takenTime['Utrogestan'] = '21:00';
  }

  void _previousMonth() {
    if (_selectedMonthOffset > 0) {
      setState(() {
        _selectedMonthOffset--;
        _selectedDay = 1;
      });
    }
  }

  void _nextMonth() {
    if (_selectedMonthOffset < _months.length - 1) {
      setState(() {
        _selectedMonthOffset++;
        _selectedDay = 1;
      });
    }
  }

  void _selectDay(int day) {
    setState(() {
      _selectedDay = day;
    });
  }

  void _showHrtLoggingSheet(List<Medication> medications) {
    // Construct the List<Map<String, String>> that CalendarHrtEditSheet expects
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

  void _addMockMedications() {
    final refNotifier = ref.read(medicationsProvider.notifier);
    
    final estradiol = Medication(
      name: 'Estradiol',
      type: MedicationType.patch,
      dose: 50,
      unit: 'mcg',
      frequency: 'Twice weekly',
    );
    final utrogestan = Medication(
      name: 'Utrogestan',
      type: MedicationType.pill,
      dose: 100,
      unit: 'mg',
      frequency: 'Bedtime',
    );

    refNotifier.addMedication(estradiol);
    refNotifier.addMedication(utrogestan);

    setState(() {
      _takenStatus['Estradiol'] = true;
      _takenTime['Estradiol'] = '08:30';
      _takenStatus['Utrogestan'] = false;
      _takenTime['Utrogestan'] = '21:00';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added mock HRT medications protocol!',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF67594E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearMedications() {
    final refNotifier = ref.read(medicationsProvider.notifier);
    final meds = ref.read(medicationsProvider).medications;
    for (final med in meds) {
      refNotifier.removeMedication(med.id);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cleared all medications.',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF8C3A25),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final medicationsState = ref.watch(medicationsProvider);
    final medications = medicationsState.medications;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      body: medications.isEmpty 
          ? _buildEmptyState() 
          : _buildDashboard(medications),
    );
  }

  // --- EMPTY STATE VIEW ---
  Widget _buildEmptyState() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glow Backdrop & Illustration
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFEDDDF5).withOpacity(0.5),
                          const Color(0xFFFEF8F6).withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFFE7E1DF),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.medication,
                      color: AppTheme.primary,
                      size: 64,
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9B7A9),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 28,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD8C9E0),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              
              // Welcoming Message
              Text(
                'Your HRT journey starts here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSerif(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tracking your HRT helps Eunora find patterns in your cycle wellness.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              // Add First Medication Button
              ElevatedButton.icon(
                onPressed: _addMockMedications,
                icon: const Icon(Icons.add, size: 22),
                label: Text(
                  'Add Your First Medication',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: AppTheme.primary.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 16),
              
              // Manual configuration option
              TextButton(
                onPressed: () => context.push('/add-medication'),
                child: Text(
                  'Configure manually',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- DASHBOARD VIEW ---
  Widget _buildDashboard(List<Medication> medications) {
    final currentMonth = _months[_selectedMonthOffset];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HRT Tracker',
              style: GoogleFonts.notoSerif(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Track your medications and see dose impact on symptoms.',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Today's Dose Section
            _buildTodayDoseSection(medications),
            const SizedBox(height: 28),

            // Monthly Schedule Section
            _buildMonthlyScheduleSection(currentMonth),
            const SizedBox(height: 24),

            // Adherence Section
            _buildAdherenceCard(),
            const SizedBox(height: 32),

            // Quick tester reset option (Helper for reviewers)
            Center(
              child: TextButton.icon(
                onPressed: _clearMedications,
                icon: const Icon(Icons.refresh, size: 16, color: Color(0xFF8C3A25)),
                label: Text(
                  'Reset to Empty State',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: const Color(0xFF8C3A25),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF7F5F0),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Month',
                style: GoogleFonts.notoSerif(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: List.generate(_months.length, (index) {
                  final isSelected = _selectedMonthOffset == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMonthOffset = index;
                          _selectedDay = 1;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppTheme.primary : const Color(0xFFE7E5E4),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _months[index].toUpperCase(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppTheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodayDoseSection(List<Medication> medications) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => _showHrtLoggingSheet(medications),
              child: Text(
                "TODAY'S DOSE",
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppTheme.primary,
                ),
              ),
            ),
            Text(
              "Wednesday, Mar 19",
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: const Color(0xFF9B8B7E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...medications.map((med) {
          final isTaken = _takenStatus[med.name] ?? false;
          final time = _takenTime[med.name] ?? '';
          final icon = med.type == MedicationType.patch 
              ? Icons.water_drop 
              : Icons.medication;
          final iconColor = med.type == MedicationType.patch 
              ? const Color(0xFFE8A89B) 
              : const Color(0xFFD8C9E0);
          final iconBg = iconColor.withOpacity(0.12);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: const Color(0xFFEAE6E0)),
            ),
            child: Row(
              children: [
                // Icon
                GestureDetector(
                  onTap: () => _showHrtLoggingSheet(medications),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                ),
                const SizedBox(width: 14),

                // Name & details
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showHrtLoggingSheet(medications),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          med.name,
                          style: GoogleFonts.notoSerif(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${med.dose.toStringAsFixed(0)} ${med.unit} ${med.type.displayName.toLowerCase()} • Since Mar 2026',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: const Color(0xFF9B8B7E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (isTaken)
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Color(0xFF2D5A3E),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Taken at $time',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  color: const Color(0xFF2D5A3E),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            'Not logged yet',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: const Color(0xFF9B8B7E),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Custom toggle switch
                GestureDetector(
                  onTap: () {
                    setState(() {
                      final current = _takenStatus[med.name] ?? false;
                      _takenStatus[med.name] = !current;
                      if (!current) {
                        final now = TimeOfDay.now();
                        final h = now.hour.toString().padLeft(2, '0');
                        final m = now.minute.toString().padLeft(2, '0');
                        _takenTime[med.name] = '$h:$m';
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 24,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isTaken ? AppTheme.primary : const Color(0xFFEAE6E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: isTaken ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMonthlyScheduleSection(String currentMonth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with Month Navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "MONTHLY SCHEDULE",
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppTheme.primary,
                  ),
                ),
                Text(
                  "Tap dates to view or log past doses",
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: const Color(0xFF9B8B7E),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _previousMonth,
                  icon: const Icon(Icons.chevron_left, size: 20),
                  color: const Color(0xFF9B8B7E),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showMonthPicker,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentMonth,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.primary),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right, size: 20),
                  color: const Color(0xFF9B8B7E),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Calendar Container
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: const Color(0xFFEAE6E0)),
          ),
          child: Column(
            children: [
              // Days of week header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                  return SizedBox(
                    width: 32,
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF9B8B7E),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Calendar Days Grid
              _buildCalendarDaysGrid(),
              
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFF2EDEA), height: 1),
              const SizedBox(height: 16),

              // Activity Log Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ACTIVITY LOG',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppTheme.primary,
                    ),
                  ),
                  Row(
                    children: [
                      _buildLogTag('Meds', const Color(0xFFD8C9E0).withOpacity(0.3)),
                      const SizedBox(width: 6),
                      _buildLogTag('Dose \u2191', const Color(0xFFE8A89B).withOpacity(0.2)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Activity log records based on the month
              _buildActivityLogsForMonth(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _buildCalendarDaysGrid() {
    final List<Widget> dayWidgets = [];

    // Let's generate days for March 2026 (starts on Sunday)
    // 0 = March 2026, 1 = April 2026, 2 = May 2026
    int totalDays = 31;
    int startOffset = 0; // offset days at the beginning of the week

    if (_selectedMonthOffset == 0) {
      // March 2026 starts on Sunday (6 offset days if Monday is first column)
      startOffset = 6;
      totalDays = 31;
    } else if (_selectedMonthOffset == 1) {
      // April 2026 starts on Wednesday (2 offset days)
      startOffset = 2;
      totalDays = 30;
    } else {
      // May 2026 starts on Friday (4 offset days)
      startOffset = 4;
      totalDays = 31;
    }

    // Offset cells (overflow from previous month)
    for (int i = 0; i < startOffset; i++) {
      dayWidgets.add(const SizedBox(width: 32, height: 32));
    }

    // Month days
    for (int day = 1; day <= totalDays; day++) {
      final isSelected = _selectedDay == day;
      final isToday = _selectedMonthOffset == 0 && day == 19;
      final isDoseChange = _selectedMonthOffset == 0 && day == 15;

      dayWidgets.add(
        GestureDetector(
          onTap: () => _selectDay(day),
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: isToday && isSelected
                  ? const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    )
                  : isDoseChange
                      ? BoxDecoration(
                          color: const Color(0xFFE8A89B).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE8A89B).withOpacity(0.4)),
                        )
                      : isSelected
                          ? BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.primary, width: 1.5),
                            )
                          : null,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: (isSelected || isToday || isDoseChange) 
                          ? FontWeight.bold 
                          : FontWeight.w500,
                      color: isToday && isSelected
                          ? Colors.white
                          : isDoseChange
                              ? AppTheme.primary
                              : (day > 19 && _selectedMonthOffset == 0)
                                  ? const Color(0xFF9B8B7E).withOpacity(0.4)
                                  : AppTheme.onSurface,
                    ),
                  ),
                  if (day == 1 && _selectedMonthOffset == 0)
                    Container(
                      margin: const EdgeInsets.only(top: 1),
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: Color(0xFF9B8B7E),
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (isDoseChange)
                    const Icon(
                      Icons.north,
                      size: 8,
                      color: Color(0xFFE8A89B),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final rowsCount = (dayWidgets.length / 7).ceil();
    return Column(
      children: List.generate(rowsCount, (rowIndex) {
        final start = rowIndex * 7;
        final end = (start + 7 < dayWidgets.length) ? start + 7 : dayWidgets.length;
        final rowWidgets = dayWidgets.sublist(start, end);
        
        // Add spacers if the last row is shorter than 7 elements
        while (rowWidgets.length < 7) {
          rowWidgets.add(const SizedBox(width: 32, height: 32));
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: rowWidgets.map((w) => Expanded(child: w)).toList(),
          ),
        );
      }),
    );
  }

  Widget _buildActivityLogsForMonth() {
    if (_selectedMonthOffset == 0) {
      // March 2026 Logs
      final isEstradiolLogged = _takenStatus['Estradiol'] ?? false;
      final isUtrogestanLogged = _takenStatus['Utrogestan'] ?? false;
      int loggedCount = 0;
      if (isEstradiolLogged) loggedCount++;
      if (isUtrogestanLogged) loggedCount++;

      return Column(
        children: [
          _buildActivityRow(
            color: AppTheme.primary,
            title: 'Today: Wednesday, Mar 19',
            description: '2 medications scheduled. $loggedCount logged. Symptoms: Mild headache.',
            isActive: _selectedDay == 19,
          ),
          const SizedBox(height: 16),
          _buildActivityRow(
            color: const Color(0xFFE8A89B),
            title: 'Friday, Mar 15',
            description: 'Dose change: Estradiol increased to 75 mcg.',
            isActive: _selectedDay == 15,
          ),
          const SizedBox(height: 16),
          _buildActivityRow(
            color: const Color(0xFF9B8B7E).withOpacity(0.4),
            title: 'Sunday, Mar 1',
            description: 'Started initial HRT protocol.',
            isActive: _selectedDay == 1,
          ),
        ],
      );
    } else {
      // Future/other months: Empty log message
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'No active logs for this month.',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: const Color(0xFF9B8B7E),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildActivityRow({
    required Color color,
    required String title,
    required String description,
    required bool isActive,
  }) {
    return Container(
      padding: EdgeInsets.all(isActive ? 12 : 0),
      decoration: isActive
          ? BoxDecoration(
              color: const Color(0xFFF2EDEA).withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEAE6E0)),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isActive ? AppTheme.primary : AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: const Color(0xFF78716C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdherenceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0E8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFF2D5A3E).withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.trending_up,
              color: Color(0xFF2D5A3E),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adherence this month: 92%',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "You're staying consistent! Keep it up.",
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: const Color(0xFF2D5A3E).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.analytics_outlined,
            color: const Color(0xFF2D5A3E).withOpacity(0.3),
            size: 22,
          ),
        ],
      ),
    );
  }
}
