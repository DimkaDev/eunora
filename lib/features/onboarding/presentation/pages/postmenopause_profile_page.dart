import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/onboarding/presentation/widgets/onboarding_header.dart';
import 'package:eunora/features/onboarding/presentation/widgets/profile_radio_card.dart';

class PostmenopauseProfilePage extends StatefulWidget {
  const PostmenopauseProfilePage({super.key});

  @override
  State<PostmenopauseProfilePage> createState() => _PostmenopauseProfilePageState();
}

class _PostmenopauseProfilePageState extends State<PostmenopauseProfilePage> {
  String? _menopauseDuration;
  String? _hrtStatus;
  String? _hrtYears;
  final Set<String> _goals = {};
  DateTime? _nextAppointment;

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
                  'Postmenopause Info',
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
              'Postmenopause is the stage of life after menopause has occurred. Understanding how many years you are postmenopause and if you are using HRT helps Eunora monitor your longevity and bone health insights.',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF4D453F),
                height: 1.5,
              ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                OnboardingHeader(
                  currentStep: 1,
                  title: 'Health Profile',
                  subtitle: 'POSTMENOPAUSE',
                  onSkip: _showInfoDialog,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitleSection(),
                        const SizedBox(height: 32),
                        _buildDurationSection(),
                        const SizedBox(height: 24),
                        _buildHRTSection(),
                        const SizedBox(height: 24),
                        _buildGoalsSection(),
                        const SizedBox(height: 24),
                        _buildAppointmentSection(),
                        const SizedBox(height: 32),
                        Center(
                          child: Opacity(
                            opacity: 0.5,
                            child: Icon(Icons.spa_outlined, size: 120, color: AppTheme.primary.withOpacity(0.3)),
                          ),
                        ),
                        const SizedBox(height: 160), // Space for footer
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildStickyFooter(context),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Postmenopause Profile',
          style: GoogleFonts.notoSerif(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1D1B1A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Postmenopause doesn\'t mean the conversation is over. Many symptoms persist for years, and we\'re here to help you navigate this transition with grace.',
          style: GoogleFonts.manrope(
            fontSize: 16,
            color: const Color(0xFF1D1B1A).withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How long ago did you go through menopause?',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D1B1A),
            ),
          ),
          const SizedBox(height: 20),
          ProfileRadioCard(
            title: '1-2 years ago',
            isSelected: _menopauseDuration == '1_2',
            onTap: () => setState(() => _menopauseDuration = '1_2'),
          ),
          ProfileRadioCard(
            title: '3-5 years ago',
            isSelected: _menopauseDuration == '3_5',
            onTap: () => setState(() => _menopauseDuration = '3_5'),
          ),
          ProfileRadioCard(
            title: '5-10 years ago',
            isSelected: _menopauseDuration == '5_10',
            onTap: () => setState(() => _menopauseDuration = '5_10'),
          ),
          ProfileRadioCard(
            title: 'More than 10 years ago',
            isSelected: _menopauseDuration == 'over_10',
            onTap: () => setState(() => _menopauseDuration = 'over_10'),
          ),
        ],
      ),
    );
  }

  Widget _buildHRTSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you on long-term HRT?',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D1B1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tracking long-term HRT helps us understand your resilience journey.',
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: const Color(0xFF1D1B1A).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          ProfileRadioCard(
            title: 'Yes - still on HRT',
            isSelected: _hrtStatus == 'yes',
            onTap: () => setState(() => _hrtStatus = 'yes'),
          ),
          if (_hrtStatus == 'yes') ...[
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF7F4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HOW LONG HAVE YOU BEEN ON HRT?',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: const Color(0xFF6C6074),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _hrtYears,
                    items: ['Since 2018', 'Since 2019', 'Since 2020', 'Since 2021', 'Since 2022', 'Since 2023']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => _hrtYears = val),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFF2EDEA)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFF2EDEA)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          ProfileRadioCard(
            title: 'No - stopped HRT',
            isSelected: _hrtStatus == 'stopped',
            onTap: () => setState(() => _hrtStatus = 'stopped'),
          ),
          ProfileRadioCard(
            title: 'Stopped HRT recently (last 1-2 years)',
            isSelected: _hrtStatus == 'recently_stopped',
            onTap: () => setState(() => _hrtStatus = 'recently_stopped'),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsSection() {
    final List<String> goalsList = [
      'Track ongoing symptoms',
      'Monitor my HRT effectiveness',
      'Prepare for my annual review',
      'Better understand my patterns',
      'Share data with my doctor'
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F3EF).withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What brings you to Eunora?',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D1B1A),
            ),
          ),
          const SizedBox(height: 20),
          ...goalsList.map((goal) => _buildGoalItem(goal)),
        ],
      ),
    );
  }

  Widget _buildGoalItem(String title) {
    final bool isSelected = _goals.contains(title);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _goals.remove(title);
          } else {
            _goals.add(title);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFD0C4BC),
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
              ),
              child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 15,
                color: const Color(0xFF1D1B1A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'When is your next doctor\'s appointment?',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D1B1A),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              );
              if (picked != null) setState(() => _nextAppointment = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF7F4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF2EDEA)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _nextAppointment == null 
                      ? 'Select date' 
                      : '${_nextAppointment!.day} ${_getMonthName(_nextAppointment!.month)} ${_nextAppointment!.year}',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      color: _nextAppointment == null ? Colors.grey : const Color(0xFF1D1B1A),
                    ),
                  ),
                  const Icon(Icons.calendar_today_outlined, color: AppTheme.primary, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We can prepare a report for your visit',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: const Color(0xFF1D1B1A).withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyFooter(BuildContext context) {
    final bool isReady = _menopauseDuration != null && _hrtStatus != null;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 10,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFFEF8F6).withOpacity(0),
                  const Color(0xFFFEF8F6),
                ],
              ),
            ),
          ),
          Container(
            color: const Color(0xFFFEF8F6),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: isReady ? () => context.push('/medications') : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF67594E),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
