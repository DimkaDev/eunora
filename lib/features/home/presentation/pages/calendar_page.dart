import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/home/presentation/widgets/calendar_symptom_edit_sheet.dart';
import 'package:eunora/features/home/presentation/widgets/calendar_trigger_edit_sheet.dart';
import 'package:eunora/features/home/presentation/widgets/calendar_hrt_edit_sheet.dart';

class MockDailyLog {
  List<String> symptoms;
  final String sleepInfo;
  final String moodInfo;
  List<Map<String, String>> hrt;
  List<String> triggers;
  int itemsCount;

  MockDailyLog({
    required this.symptoms,
    required this.sleepInfo,
    required this.moodInfo,
    required this.hrt,
    required this.triggers,
    required this.itemsCount,
  });
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  // Navigation states
  int _selectedMonthOffset = 1; // 0 = March 2026, 1 = April 2026, 2 = May 2026
  int _selectedDay = 13; // Selected day of month
  bool _legendExpanded = false;

  final List<String> _months = ['March 2026', 'April 2026', 'May 2026'];
  final List<String> _prevLabels = ['Feb', 'Mar', 'Apr'];
  final List<String> _nextLabels = ['Apr', 'May', 'Jun'];

  // Mock Database for April 2026
  late final Map<int, MockDailyLog> _aprilLogs;

  @override
  void initState() {
    super.initState();
    _aprilLogs = {
      7: MockDailyLog(
        symptoms: ['Hot flashes · 2/5', 'Anxiety · 1/5'],
        sleepInfo: '7 hours · quality 4/5',
        moodInfo: 'Good · 4/5',
        hrt: [
          {'name': 'Estradiol', 'details': '50 mcg · Patch', 'status': 'Taken 08:30', 'isTaken': 'true'},
          {'name': 'Utrogestan', 'details': '100 mg · Tablet', 'status': 'Taken 21:00', 'isTaken': 'true'},
        ],
        triggers: ['Stress'],
        itemsCount: 4,
      ),
      8: MockDailyLog(
        symptoms: ['Hot flashes · 3/5', 'Fatigue · 2/5'],
        sleepInfo: '6.5 hours · quality 3/5',
        moodInfo: 'Okay · 3/5',
        hrt: [
          {'name': 'Estradiol', 'details': '50 mcg · Patch', 'status': 'Taken 08:45', 'isTaken': 'true'},
          {'name': 'Utrogestan', 'details': '100 mg · Tablet', 'status': 'Not taken', 'isTaken': 'false'},
        ],
        triggers: ['Red wine', 'Poor sleep'],
        itemsCount: 4,
      ),
      9: MockDailyLog(
        symptoms: ['Fatigue · 4/5', 'Anxiety · 3/5'],
        sleepInfo: '5.5 hours · quality 2/5',
        moodInfo: 'Anxious · 2/5',
        hrt: [
          {'name': 'Estradiol', 'details': '50 mcg · Patch', 'status': 'Taken 08:00', 'isTaken': 'true'},
          {'name': 'Utrogestan', 'details': '100 mg · Tablet', 'status': 'Taken 20:30', 'isTaken': 'true'},
        ],
        triggers: ['Poor sleep', 'Stress'],
        itemsCount: 4,
      ),
      10: MockDailyLog(
        symptoms: ['Hot flashes · 4/5', 'Anxiety · 4/5', 'Fatigue · 3/5'],
        sleepInfo: '6 hours · quality 3/5',
        moodInfo: 'Okay · 3/5',
        hrt: [
          {'name': 'Estradiol', 'details': '75 mcg · Patch', 'status': 'Taken 08:15', 'isTaken': 'true'},
          {'name': 'Utrogestan', 'details': '100 mg · Tablet', 'status': 'Not taken', 'isTaken': 'false'},
        ],
        triggers: ['Red wine', 'Stress', 'Poor sleep'],
        itemsCount: 4,
      ),
      11: MockDailyLog(
        symptoms: ['Hot flashes · 5/5', 'Anxiety · 3/5'],
        sleepInfo: '5 hours · quality 2/5',
        moodInfo: 'Low · 2/5',
        hrt: [
          {'name': 'Estradiol', 'details': '50 mcg · Patch', 'status': 'Taken 09:00', 'isTaken': 'true'},
          {'name': 'Utrogestan', 'details': '100 mg · Tablet', 'status': 'Taken 21:15', 'isTaken': 'true'},
        ],
        triggers: ['Stress'],
        itemsCount: 4,
      ),
      12: MockDailyLog(
        symptoms: ['Fatigue · 2/5'],
        sleepInfo: '8 hours · quality 5/5',
        moodInfo: 'Great · 5/5',
        hrt: [
          {'name': 'Estradiol', 'details': '50 mcg · Patch', 'status': 'Taken 08:30', 'isTaken': 'true'},
          {'name': 'Utrogestan', 'details': '100 mg · Tablet', 'status': 'Not taken', 'isTaken': 'false'},
        ],
        triggers: [],
        itemsCount: 3,
      ),
      13: MockDailyLog(
        symptoms: ['Hot flashes · 4/5', 'Anxiety · 3/5', 'Fatigue · 3/5'],
        sleepInfo: '6 hours · quality 3/5',
        moodInfo: 'Good · 4/5',
        hrt: [
          {'name': 'Estradiol', 'details': '75 mcg · Patch', 'status': 'Taken 08:15', 'isTaken': 'true'},
          {'name': 'Utrogestan', 'details': '100 mg · Tablet', 'status': 'Not taken', 'isTaken': 'false'},
        ],
        triggers: ['Stress', 'Red wine', 'Poor sleep'],
        itemsCount: 4,
      ),
    };
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
    if (_selectedMonthOffset < 2) {
      setState(() {
        _selectedMonthOffset++;
        _selectedDay = 1;
      });
    }
  }

  void _selectDay(int day) {
    if (day > 0 && day <= 30) {
      setState(() {
        _selectedDay = day;
      });
    }
  }

  void _showSymptomEditSheet(MockDailyLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => CalendarSymptomEditSheet(
          initialSymptoms: List<String>.from(log.symptoms),
          onSave: (updated) {
            setState(() {
              log.symptoms = updated;
              log.itemsCount = updated.length + log.hrt.length;
            });
          },
        ),
      ),
    );
  }

  void _showTriggerEditSheet(MockDailyLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => CalendarTriggerEditSheet(
          initialTriggers: List<String>.from(log.triggers),
          onSave: (updated) {
            setState(() {
              log.triggers = updated;
            });
          },
        ),
      ),
    );
  }

  void _showHrtEditSheet(MockDailyLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => CalendarHrtEditSheet(
          initialHrt: log.hrt.map((e) => Map<String, String>.from(e)).toList(),
          onSave: (updated) {
            setState(() {
              log.hrt.clear();
              log.hrt.addAll(updated);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isApril = _selectedMonthOffset == 1;
    final activeLog = isApril ? _aprilLogs[_selectedDay] : null;

    return Container(
      color: AppTheme.background,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMonthNavigation(),
                  const SizedBox(height: 16),
                  _buildCalendarCard(isApril),
                  const SizedBox(height: 24),
                  if (!isApril)
                    _buildEmptyState()
                  else if (activeLog == null)
                    _buildUnloggedState()
                  else
                    _buildLoggedDetailsState(activeLog),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF8F6).withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.menu, color: Colors.grey[700]),
                const SizedBox(width: 12),
                Text(
                  'Eunora',
                  style: GoogleFonts.notoSerif(
                    fontSize: 22,
                    fontWeight: FontWeight.normal,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCbE0Oy8C6RtCTRmMNSUO1AD8jh6lHoqHsAAOULs3UCLZcD4F0r6Ogp56jOilWIE09b_c36iZZaqYycJc7vdS2K_C-DSka3Hw3U0NgrVKR8HHocqghBV07CruKv4E__3CnX7-VpGUAkE1y_MTRufVUkLVK94SmDhIglXLR6FBXl6kvj93X825YlrwAbJEL5wu2kI4XbdEQo7A29EUo0yvyh4O4Lcks_qUrxJx29qnHG18GvadYDlCs5MIaOqYKanz4xepfpPEav874',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: _selectedMonthOffset > 0 ? _previousMonth : null,
          child: Opacity(
            opacity: _selectedMonthOffset > 0 ? 1.0 : 0.4,
            child: Row(
              children: [
                const Icon(Icons.chevron_left, size: 20, color: AppTheme.primary),
                const SizedBox(width: 4),
                Text(
                  _prevLabels[_selectedMonthOffset],
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.outline,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            _months[_selectedMonthOffset].toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
              letterSpacing: 1.5,
            ),
          ),
        ),
        GestureDetector(
          onTap: _selectedMonthOffset < 2 ? _nextMonth : null,
          child: Opacity(
            opacity: _selectedMonthOffset < 2 ? 1.0 : 0.4,
            child: Row(
              children: [
                Text(
                  _nextLabels[_selectedMonthOffset],
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.outline,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 20, color: AppTheme.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarCard(bool isApril) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[300]!.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'].map((day) {
              return Expanded(
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary.withValues(alpha: 0.6),
                    letterSpacing: 1.2,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          _buildDaysGrid(isApril),
        ],
      ),
    );
  }

  Widget _buildDaysGrid(bool isApril) {
    // Determine offset days (April 1st is Wednesday -> 2 offset days, Mon & Tue)
    // 30 days in April, let's keep it simple
    final totalDays = 30;
    final List<Widget> dayWidgets = [];

    // Prior Month Overflow (e.g. 30, 31)
    dayWidgets.add(_buildOverflowDay('30'));
    dayWidgets.add(_buildOverflowDay('31'));

    for (int day = 1; day <= totalDays; day++) {
      final isSelected = isApril && _selectedDay == day;
      final hasData = isApril && _aprilLogs.containsKey(day);

      // Mild (1-3), Moderate (4-6), Severe (7-10) color codes matching legend
      Color? backgroundIntensity;
      if (isApril && hasData) {
        if (day == 7 || day == 12) {
          // Mild (light purple)
          backgroundIntensity = const Color(0xFFEDDDF5).withValues(alpha: 0.4);
        } else if (day == 8 || day == 9 || day == 13) {
          // Moderate (medium purple)
          backgroundIntensity = const Color(0xFFEDDDF5).withValues(alpha: 0.8);
        } else if (day == 10 || day == 11) {
          // Severe (magenta / tertiary)
          backgroundIntensity = const Color(0xFFF9B7A9).withValues(alpha: 0.6);
        }
      }

      dayWidgets.add(
        _buildCalendarDay(
          day: day,
          isSelected: isSelected,
          hasData: hasData,
          backgroundColor: backgroundIntensity,
          onTap: () => _selectDay(day),
        ),
      );
    }

    // Grid layout with 7 items per row
    final rowsCount = (dayWidgets.length / 7).ceil();
    return Column(
      children: List.generate(rowsCount, (rowIndex) {
        final start = rowIndex * 7;
        final end = (start + 7 < dayWidgets.length) ? start + 7 : dayWidgets.length;
        final rowWidgets = dayWidgets.sublist(start, end);
        return Row(
          children: rowWidgets.map((w) => Expanded(child: AspectRatio(aspectRatio: 1, child: w))).toList(),
        );
      }),
    );
  }

  Widget _buildOverflowDay(String text) {
    return Center(
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w300,
          color: const Color(0xFFD8D0C8),
        ),
      ),
    );
  }

  Widget _buildCalendarDay({
    required int day,
    required bool isSelected,
    required bool hasData,
    required Color? backgroundColor,
    required VoidCallback onTap,
  }) {
    if (isSelected) {
      if (hasData) {
        // Today Selected (Solid circle)
        return GestureDetector(
          onTap: onTap,
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        // Unlogged day selected (Outline circle + Ring shadow)
        return GestureDetector(
          onTap: onTap,
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primary, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    spreadRadius: 2,
                    blurRadius: 4,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
            ),
          ),
        );
      }
    }

    // Default unselected days
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: hasData ? FontWeight.bold : FontWeight.w400,
                  color: hasData ? AppTheme.onSurface : const Color(0xFFB0A89E),
                ),
              ),
              if (hasData && backgroundColor == null) ...[
                const SizedBox(height: 1),
                Container(
                  width: 3,
                  height: 3,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- STATE 1: EMPTY STATE ---
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_calendar,
              color: AppTheme.outline,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No logs for this month yet.',
            style: GoogleFonts.notoSerif(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tracking daily helps you discover patterns in your wellness.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/daily-logging'),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Start Today\'s Log'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- STATE 2: UNLOGGED STATE ---
  Widget _buildUnloggedState() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Log: April $_selectedDay',
                    style: GoogleFonts.notoSerif(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'SELECTED',
                      style: GoogleFonts.manrope(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.event_busy,
                        color: AppTheme.outline,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No data recorded for this day.',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: () => context.push('/daily-logging'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'LOG RETROACTIVELY',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() => _selectedDay = 13),
                          child: Text(
                            'BACK TO TODAY',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                              letterSpacing: 1.2,
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
        ),
        const SizedBox(height: 24),
        _buildWeeklyTrendsCard(),
        const SizedBox(height: 24),
        _buildInsightsBanner(),
        const SizedBox(height: 16),
        _buildLegendAccordion(),
      ],
    );
  }

  Widget _buildWeeklyTrendsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Trends',
            style: GoogleFonts.notoSerif(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildTrendRow(
            title: 'Symptom Intensity',
            value: 'Avg 4.2',
            change: '↓ 12%',
            isGood: true,
            sparklineHeights: [0.4, 0.6, 0.8, 0.3, 0.5, 0.45, 0.0],
          ),
          const Divider(height: 24, color: Color(0xFFF2EDEA)),
          _buildTrendRow(
            title: 'Sleep Quality',
            value: '6.5 hrs',
            change: '↓ 4%',
            isGood: false,
            sparklineHeights: [0.7, 0.65, 0.9, 0.55, 0.6, 0.4, 0.0],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendRow({
    required String title,
    required String value,
    required String change,
    required bool isGood,
    required List<double> sparklineHeights,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.outline,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    value,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    change,
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isGood ? Colors.green[600] : Colors.red[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
          _buildSparkline(sparklineHeights),
        ],
      ),
    );
  }

  Widget _buildSparkline(List<double> heights) {
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(heights.length, (index) {
          final h = heights[index];
          // Sparkline highlights active column (index 5)
          final isHighlighted = index == 5;
          return Container(
            width: 4,
            height: 24 * h,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: h == 0
                  ? Colors.transparent
                  : (isHighlighted ? AppTheme.primary : const Color(0xFFD0C1D8)),
              borderRadius: BorderRadius.circular(1),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInsightsBanner() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: const BorderSide(color: AppTheme.tertiaryFixed, width: 4),
          top: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.2)),
          right: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.2)),
          bottom: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.2)),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology_alt,
                color: Color(0xFF814F45),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Personalized Insights',
                style: GoogleFonts.notoSerif(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your hot flashes correlate with caffeine intake recorded 4 hours prior. Consider switching to herbal tea after 12 PM.',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppTheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE7E1DF)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Actionable takeaway',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.outline,
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Text('LEARN MORE'),
                label: const Icon(Icons.open_in_new, size: 14),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF814F45),
                  padding: EdgeInsets.zero,
                  textStyle: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendAccordion() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _legendExpanded = !_legendExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.outline, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'SEVERITY LEGEND',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.outline,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _legendExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.outline,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          if (_legendExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(height: 1, color: Color(0xFFD0C4BC)),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      _buildLegendItem(Colors.white, 'No Data', hasBorder: true),
                      _buildLegendItem(const Color(0xFFEDDDF5).withValues(alpha: 0.4), 'Mild (1-3)'),
                      _buildLegendItem(const Color(0xFFEDDDF5).withValues(alpha: 0.8), 'Moderate (4-6)'),
                      _buildLegendItem(const Color(0xFFF9B7A9).withValues(alpha: 0.6), 'Severe (7-10)'),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text, {bool hasBorder = false}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: hasBorder
                ? Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.5))
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppTheme.outline,
          ),
        ),
      ],
    );
  }

  // --- STATE 3: LOGGED STATE ---
  Widget _buildLoggedDetailsState(MockDailyLog log) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sunday, April $_selectedDay',
                style: GoogleFonts.notoSerif(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${log.itemsCount} items logged',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        _buildLoggedSymptomsCard(log),
        const SizedBox(height: 20),
        _buildLoggedHrtCard(log),
        const SizedBox(height: 20),
        _buildLoggedTriggersCard(log),
        const SizedBox(height: 20),
        _buildPremiumPatternsCard(),
        const SizedBox(height: 20),
        _buildTrendsChartCard(),
      ],
    );
  }

  Widget _buildLoggedSymptomsCard(MockDailyLog log) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Symptoms',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showSymptomEditSheet(log),
                child: Row(
                  children: [
                    Text(
                      'Edit',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: AppTheme.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: log.symptoms.map((s) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDDDF5).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD0C1D8)),
                ),
                child: Text(
                  s,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6C6074),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF2EDEA)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bedtime, color: Colors.grey, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Sleep',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
              Text(
                log.sleepInfo,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mood',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
              Text(
                log.moodInfo,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedHrtCard(MockDailyLog log) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFA8D5BA),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'HRT',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showHrtEditSheet(log),
                child: Row(
                  children: [
                    Text(
                      'Edit',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: AppTheme.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: log.hrt.map((h) {
              final isTaken = h['isTaken'] == 'true';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h['name']!,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          h['details']!,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isTaken ? const Color(0xFFE8F5ED) : const Color(0xFFFFF1ED),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        h['status']!.toUpperCase(),
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isTaken ? const Color(0xFF2D5A3E) : const Color(0xFF8C3A25),
                          letterSpacing: 0.8,
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

  Widget _buildLoggedTriggersCard(MockDailyLog log) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8A89B),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Triggers',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showTriggerEditSheet(log),
                child: Row(
                  children: [
                    Text(
                      'Edit',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: AppTheme.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (log.triggers.isEmpty)
            Text(
              'No triggers recorded today.',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppTheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: log.triggers.map((t) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.tertiaryFixed.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    t,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF814F45),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumPatternsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 154,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Patterns',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDDDF5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock, size: 12, color: Color(0xFF6C6074)),
                            const SizedBox(width: 4),
                            Text(
                              'PREMIUM',
                              style: GoogleFonts.manrope(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF6C6074),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Red wine (evening)',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              Text(
                                '→ Hot flashes +4.2 next day',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '79% correlation',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Correlation meter bar
                        Container(
                          width: 8,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppTheme.outlineVariant.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: 64 * 0.79,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Insights are based on your personal historical data over the last 90 days.',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsChartCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly trends',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(
                      '30d',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 14, color: AppTheme.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'HOT FLASH FREQUENCY — LAST 7 DAYS',
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurfaceVariant,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          // Curved Path Custom Painter
          SizedBox(
            height: 90,
            width: double.infinity,
            child: CustomPaint(
              painter: FrequencyCurvePainter(),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
              return Text(
                day.toUpperCase(),
                style: GoogleFonts.manrope(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF2EDEA)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SLEEP QUALITY',
                      style: GoogleFonts.manrope(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildTrendBar(0.6),
                        _buildTrendBar(0.8),
                        _buildTrendBar(0.4),
                        _buildTrendBar(1.0),
                        _buildTrendBar(0.6),
                        _buildTrendBar(0.8),
                        _buildTrendBar(0.6),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MOOD',
                      style: GoogleFonts.manrope(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildTrendBar(0.8, color: const Color(0xFFA8D5BA).withValues(alpha: 0.6)),
                        _buildTrendBar(1.0, color: const Color(0xFFA8D5BA).withValues(alpha: 0.6)),
                        _buildTrendBar(0.6, color: const Color(0xFFA8D5BA).withValues(alpha: 0.6)),
                        _buildTrendBar(0.8, color: const Color(0xFFA8D5BA).withValues(alpha: 0.6)),
                        _buildTrendBar(1.0, color: const Color(0xFFA8D5BA).withValues(alpha: 0.6)),
                        _buildTrendBar(0.6, color: const Color(0xFFA8D5BA).withValues(alpha: 0.6)),
                        _buildTrendBar(0.8, color: const Color(0xFFA8D5BA).withValues(alpha: 0.6)),
                      ],
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

  Widget _buildTrendBar(double factor, {Color color = const Color(0xFFEDDDF5)}) {
    return Expanded(
      child: Container(
        height: 48 * factor,
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(2),
            topRight: Radius.circular(2),
          ),
        ),
      ),
    );
  }
}

class FrequencyCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // We map relative coordinates (0-100 x, 0-40 y) to actual size.width and size.height
    double getX(double p) => p * size.width / 100;
    double getY(double p) => p * size.height / 40;

    path.moveTo(getX(0), getY(35));
    path.quadraticBezierTo(getX(7.5), getY(32.5), getX(15), getY(30));
    path.quadraticBezierTo(getX(20), getY(34), getX(25), getY(38));
    path.quadraticBezierTo(getX(32.5), getY(24), getX(40), getY(10));
    path.quadraticBezierTo(getX(47.5), getY(17.5), getX(55), getY(25));
    path.quadraticBezierTo(getX(62.5), getY(15), getX(70), getY(5));
    path.quadraticBezierTo(getX(77.5), getY(10), getX(85), getY(15));
    path.quadraticBezierTo(getX(92.5), getY(13.5), getX(100), getY(12));

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
