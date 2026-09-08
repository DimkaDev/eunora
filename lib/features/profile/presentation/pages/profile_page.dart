import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eunora/features/onboarding/presentation/providers/menopause_stage_provider.dart';
import 'package:eunora/features/onboarding/presentation/widgets/profile_radio_card.dart';
import 'package:eunora/features/onboarding/presentation/providers/onboarding_profile_provider.dart';
import 'package:eunora/core/utils/date_formatter.dart';
import 'package:eunora/core/utils/time_formatter.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  // Toggle states
  bool _dailyReminder = true;
  bool _weeklyDigest = false;
  bool _alerts = true;
  bool _privacyMode = false;
  bool _appleHealth = true;
  bool _googleFit = false;

  // Journey state (can be updated)
  String _stage = 'Early Menopause';
  int _age = 51;
  String _yearsInStage = '~2 years';

  // Format preferences
  AppDateFormatMode _dateFormatMode = AppDateFormatMode.dayMonthYear;
  TimeFormatMode _timeFormatMode = TimeFormatMode.twelveHour;

  @override
  void initState() {
    super.initState();
    _loadAllPreferences();
  }

  Future<void> _loadAllPreferences() async {
    await _loadJourneyData();
    await _loadFormatPreferences();
  }

  Future<void> _loadFormatPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(AppDateFormatter.prefKey);
    if (savedDate != null) {
      for (final mode in AppDateFormatMode.values) {
        if (mode.name == savedDate) {
          _dateFormatMode = mode;
          AppDateFormatter.defaultMode = mode;
          break;
        }
      }
    }
    final savedTime = prefs.getString(AppTimeFormatter.prefKey);
    if (savedTime != null) {
      for (final mode in TimeFormatMode.values) {
        if (mode.name == savedTime) {
          _timeFormatMode = mode;
          AppTimeFormatter.defaultMode = mode;
          break;
        }
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _updateDateFormat(AppDateFormatMode mode) async {
    setState(() {
      _dateFormatMode = mode;
    });
    await AppDateFormatter.setMode(mode);
    ref.read(dateFormatConfigProvider.notifier).state = DateFormatConfig(mode: mode);
  }

  Future<void> _updateTimeFormat(TimeFormatMode mode) async {
    setState(() {
      _timeFormatMode = mode;
    });
    await AppTimeFormatter.setMode(mode);
    ref.read(timeFormatConfigProvider.notifier).state = TimeFormatConfig(mode: mode);
  }

  User? get _currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadJourneyData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = _currentUser;
    final uid = user?.uid ?? 'anon';
    if (mounted) {
      setState(() {
        _stage = prefs.getString('journey_stage_$uid') ?? 'Early Menopause';
        _age = prefs.getInt('journey_age_$uid') ?? 51;
        _yearsInStage = prefs.getString('journey_years_in_stage_$uid') ?? '~2 years';
      });
    }
  }

  Future<void> _saveJourneyData(String stage, int age, String yearsInStage) async {
    final prefs = await SharedPreferences.getInstance();
    final user = _currentUser;
    final uid = user?.uid ?? 'anon';
    await prefs.setString('journey_stage_$uid', stage);
    await prefs.setInt('journey_age_$uid', age);
    await prefs.setString('journey_years_in_stage_$uid', yearsInStage);
    if (mounted) {
      setState(() {
        _stage = stage;
        _age = age;
        _yearsInStage = yearsInStage;
      });
    }
  }

  void _showUpdateSituationWizard() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UpdateSituationWizard(
        currentStage: _stage,
        currentAge: _age,
        currentYearsInStage: _yearsInStage,
        onSave: (stage, age, yearsInStage) {
          _saveJourneyData(stage, age, yearsInStage);
        },
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        title: Text(
          'Delete Account',
          style: GoogleFonts.notoSerif(
            color: AppTheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete your account? This action is permanent and all your health data will be deleted.',
          style: GoogleFonts.manrope(color: AppTheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(color: AppTheme.outline),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              // Route to onboarding or signin page
              context.go('/onboarding');
            },
            child: Text(
              'Delete',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        title: Text(
          'Sign Out',
          style: GoogleFonts.notoSerif(
            color: AppTheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out from Eunora?',
          style: GoogleFonts.manrope(color: AppTheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(color: AppTheme.outline),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await GoogleSignIn.instance.signOut();
              } catch (_) {}
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                context.go('/signin');
              }
            },
            child: Text(
              'Sign Out',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(onboardingProfileProvider);
    final firebaseUser = _currentUser;

    String displayName = 'Sarah Johnson';
    if (userProfile != null && userProfile.email.isNotEmpty) {
      final emailName = userProfile.email.split('@').first;
      if (emailName.isNotEmpty) {
        displayName = emailName[0].toUpperCase() + emailName.substring(1);
      }
    } else if (firebaseUser != null && firebaseUser.email != null && firebaseUser.email!.isNotEmpty) {
      final emailName = firebaseUser.email!.split('@').first;
      if (emailName.isNotEmpty) {
        displayName = emailName[0].toUpperCase() + emailName.substring(1);
      }
    }

    String initials = 'SJ';
    if (displayName.isNotEmpty) {
      final parts = displayName.trim().split(RegExp(r'\s+'));
      if (parts.length > 1) {
        initials = (parts[0][0] + parts[1][0]).toUpperCase();
      } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
        initials = parts[0][0].toUpperCase();
      }
    }

    final displayEmail = userProfile?.email ?? firebaseUser?.email ?? 'sarah@email.com';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface.withOpacity(0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Profile',
          style: GoogleFonts.notoSerif(
            color: AppTheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section 1: Profile Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.onSurface.withOpacity(0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFEDDDF5),
                          AppTheme.primaryFixed,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: GoogleFonts.notoSerif(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    style: GoogleFonts.notoSerif(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayEmail,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  InkWell(
                    onTap: () {
                      // Navigate or mock edit
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit Profile triggered')),
                      );
                    },
                    borderRadius: BorderRadius.circular(9999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.primaryContainer],
                        ),
                        borderRadius: BorderRadius.circular(9999),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        'Edit Profile',
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Premium Upgrade Banner Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary,
                    AppTheme.primaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'GO PREMIUM',
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unlock Full Insights & Reports',
                    style: GoogleFonts.notoSerif(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get AI trigger correlations, PDF reports for your doctor, and unlimited symptom logging.',
                    style: GoogleFonts.manrope(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primary,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => context.push('/premium-upgrade'),
                    child: Text(
                      'Start 7-Day Free Trial',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Section 1.6: Account Status / Plan Type Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.onSurface.withOpacity(0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Row 1: Plan Type
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Plan Type',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF78716C), // stone-600
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.tertiaryFixed, // secondary-container color equivalent
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            'PREMIUM',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary, // on-secondary-container color
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.surfaceContainerLow),
                  // Row 2: Next Billing
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Next Billing',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF78716C),
                          ),
                        ),
                        Text(
                          'March 19, 2025',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.surfaceContainerLow),
                  // Row 3: Joined
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Joined',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF78716C),
                          ),
                        ),
                        Text(
                          'January 15, 2024',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Manage Subscription Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999), // rounded-full
                      ),
                      elevation: 2,
                      shadowColor: AppTheme.primary.withOpacity(0.1),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Manage Subscription triggered')),
                      );
                    },
                    child: Text(
                      'Manage Subscription',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Section 2: Menopause Journey
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Menopause Journey',
                  style: GoogleFonts.notoSerif(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: _showUpdateSituationWizard,
                  child: Text(
                    'Update',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.onSurface.withOpacity(0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildJourneyRow('Stage', _stage),
                  const Divider(height: 1, color: AppTheme.surfaceContainerLow, indent: 24, endIndent: 24),
                  _buildJourneyRow('Age', _age.toString()),
                  const Divider(height: 1, color: AppTheme.surfaceContainerLow, indent: 24, endIndent: 24),
                  _buildJourneyRow('Years in Stage', _yearsInStage),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Section 2.5: Hormonal Situation Section
            Text(
              'Hormonal Situation',
              style: GoogleFonts.notoSerif(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.onSurface.withOpacity(0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDDDF5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.spa_outlined,
                          color: AppTheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Stage',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              _stage,
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Timeframe',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              _yearsInStage,
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      elevation: 2,
                      shadowColor: AppTheme.primary.withOpacity(0.1),
                    ),
                    onPressed: _showUpdateSituationWizard,
                    child: Text(
                      'Update Situation Profile',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: BorderSide(color: AppTheme.primary.withOpacity(0.5)),
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                    onPressed: () {
                      context.push('/frequent-symptoms-settings');
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.tune_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'My Frequent Symptoms',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Section 3: Notifications Card
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.notoSerif(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primary),
                  onPressed: () => context.push('/notification-preferences'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.onSurface.withOpacity(0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSwitchRow(
                    'Daily Reminder',
                    'Receive a gentle nudge for your daily journal entry.',
                    _dailyReminder,
                    (val) => setState(() => _dailyReminder = val),
                  ),
                  const SizedBox(height: 24),
                  _buildSwitchRow(
                    'Weekly Digest',
                    'Summarized insights delivered every Monday.',
                    _weeklyDigest,
                    (val) => setState(() => _weeklyDigest = val),
                  ),
                  const SizedBox(height: 24),
                  _buildSwitchRow(
                    'Alerts',
                    'Critical updates about your health trends.',
                    _alerts,
                    (val) => setState(() => _alerts = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Section 3.5: Display & Format
            Text(
              'Display & Format',
              style: GoogleFonts.notoSerif(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.onSurface.withOpacity(0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildValueNavigationRow(
                    icon: Icons.calendar_month_outlined,
                    title: 'Date Format',
                    value: '${_dateFormatMode.label} (${AppDateFormatter.formatDate(DateTime.now(), mode: _dateFormatMode)})',
                    onTap: _showDateFormatPicker,
                  ),
                  const Divider(height: 1, color: AppTheme.surfaceContainerLow, indent: 24, endIndent: 24),
                  _buildValueNavigationRow(
                    icon: Icons.schedule_outlined,
                    title: 'Time Format',
                    value: '${_timeFormatMode.label} (${_timeFormatMode.sample})',
                    onTap: _showTimeFormatPicker,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Section 4: Data & Privacy
            Text(
              'Data & Privacy',
              style: GoogleFonts.notoSerif(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.onSurface.withOpacity(0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Data Backup',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.verified, color: AppTheme.primary, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Secure',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.surfaceContainerLow, indent: 24, endIndent: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Privacy Mode',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        Switch(
                          value: _privacyMode,
                          activeColor: Colors.white,
                          activeTrackColor: AppTheme.primary,
                          inactiveTrackColor: AppTheme.surfaceContainerHighest,
                          onChanged: (val) => setState(() => _privacyMode = val),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.surfaceContainerLow, indent: 24, endIndent: 24),
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Starting data download (CSV export)...')),
                      );
                    },
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Download Your Data',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                          const Icon(Icons.download, color: AppTheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Section 5: Integrations
            Text(
              'Integrations',
              style: GoogleFonts.notoSerif(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.onSurface.withOpacity(0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.health_and_safety, color: AppTheme.primary, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Apple Health',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _appleHealth,
                        activeColor: Colors.white,
                        activeTrackColor: AppTheme.primary,
                        inactiveTrackColor: AppTheme.surfaceContainerHighest,
                        onChanged: (val) => setState(() => _appleHealth = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.fitness_center, color: AppTheme.primary, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Google Fit',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _googleFit,
                        activeColor: Colors.white,
                        activeTrackColor: AppTheme.primary,
                        inactiveTrackColor: AppTheme.surfaceContainerHighest,
                        onChanged: (val) => setState(() => _googleFit = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceContainer,
                      foregroundColor: AppTheme.onSurface,
                      shadowColor: Colors.transparent,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link Doctor Account triggered')),
                      );
                    },
                    icon: const Icon(Icons.add_link, size: 20),
                    label: Text(
                      'Link Doctor Account',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Section 6: Support & Legal
            Text(
              'Support & Legal',
              style: GoogleFonts.notoSerif(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.onSurface.withOpacity(0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildNavigationRow('FAQ', () => context.push('/help-center')),
                  const Divider(height: 1, color: AppTheme.surfaceContainerLow, indent: 20, endIndent: 20),
                  _buildNavigationRow('Contact Support', () => context.push('/help-center')),
                  const Divider(height: 1, color: AppTheme.surfaceContainerLow, indent: 20, endIndent: 20),
                  _buildNavigationRow('Blog & Resources', () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Blog & Resources coming soon!')),
                    );
                  }),
                  const Divider(height: 1, color: AppTheme.surfaceContainerLow, indent: 20, endIndent: 20),
                  _buildNavigationRow('Privacy Policy', () => context.push('/privacy-policy')),
                  const Divider(height: 1, color: AppTheme.surfaceContainerLow, indent: 20, endIndent: 20),
                  _buildNavigationRow('Terms of Service', () => context.push('/terms')),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Section 6.5: Danger Zone (Delete Account)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.06),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppTheme.error.withOpacity(0.15),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: AppTheme.error,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delete Account',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.error,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Permanently delete your account and all associated data. This action is irreversible.',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                height: 1.4,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.error, width: 1.5),
                      backgroundColor: AppTheme.surfaceContainerLowest,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                    onPressed: _showDeleteAccountDialog,
                    child: Text(
                      'Delete Account',
                      style: GoogleFonts.manrope(
                        color: AppTheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Section 7: App Info
            Column(
              children: [
                Text(
                  'Version 2.4.1 (Build 108)',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Made with ❤️ for women',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Sign Out Button
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.outlineVariant, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
              onPressed: _showSignOutDialog,
              child: Text(
                'SIGN OUT',
                style: GoogleFonts.manrope(
                  color: AppTheme.error,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Switch(
          value: value,
          activeColor: Colors.white,
          activeTrackColor: AppTheme.primary,
          inactiveTrackColor: AppTheme.surfaceContainerHighest,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildNavigationRow(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildValueNavigationRow({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  void _showDateFormatPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF8F6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Date Format',
                    style: GoogleFonts.notoSerif(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose how dates are displayed throughout the app.',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...AppDateFormatMode.values.map((mode) {
                    final isSelected = _dateFormatMode == mode;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          _updateDateFormat(mode);
                          setSheetState(() {});
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryFixed.withOpacity(0.4) : AppTheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppTheme.primary : AppTheme.surfaceContainerLow,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mode.label,
                                    style: GoogleFonts.manrope(
                                      fontSize: 15,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    AppDateFormatter.formatDate(DateTime.now(), mode: mode),
                                    style: GoogleFonts.manrope(
                                      fontSize: 13,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: isSelected ? AppTheme.primary : AppTheme.outlineVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTimeFormatPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF8F6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Time Format',
                    style: GoogleFonts.notoSerif(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose how time is formatted for medication and logs.',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...TimeFormatMode.values.map((mode) {
                    final isSelected = _timeFormatMode == mode;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          _updateTimeFormat(mode);
                          setSheetState(() {});
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryFixed.withOpacity(0.4) : AppTheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppTheme.primary : AppTheme.surfaceContainerLow,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mode.label,
                                    style: GoogleFonts.manrope(
                                      fontSize: 15,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    mode.sample,
                                    style: GoogleFonts.manrope(
                                      fontSize: 13,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: isSelected ? AppTheme.primary : AppTheme.outlineVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class UpdateSituationWizard extends StatefulWidget {
  final String currentStage;
  final int currentAge;
  final String currentYearsInStage;
  final Function(String stage, int age, String yearsInStage) onSave;

  const UpdateSituationWizard({
    super.key,
    required this.currentStage,
    required this.currentAge,
    required this.currentYearsInStage,
    required this.onSave,
  });

  @override
  State<UpdateSituationWizard> createState() => _UpdateSituationWizardState();
}

class _UpdateSituationWizardState extends State<UpdateSituationWizard> {
  int _step = 0; // 0: Select Stage, 1: Enter Details
  MenopauseStage? _selectedStage;

  // Form states
  String? _q1Value; // Irregular duration, Last period duration, etc.
  late final TextEditingController _ageController;

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(text: widget.currentAge.toString());
    _selectedStage = _mapStageStringToEnum(widget.currentStage);
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  MenopauseStage? _mapStageStringToEnum(String stage) {
    final lowerStage = stage.toLowerCase();
    if (lowerStage.contains('irregular') || lowerStage.contains('peri')) {
      return MenopauseStage.irregular;
    } else if (lowerStage.contains('12 months') || (lowerStage.contains('menopause') && !lowerStage.contains('post') && !lowerStage.contains('surgical'))) {
      return MenopauseStage.noPeriod12Months;
    } else if (lowerStage.contains('post')) {
      return MenopauseStage.postmenopause;
    } else if (lowerStage.contains('surgical')) {
      return MenopauseStage.surgical;
    } else if (lowerStage.contains('pcos')) {
      return MenopauseStage.pcos;
    }
    return MenopauseStage.irregular; // default
  }

  String _mapStageEnumToString(MenopauseStage stage) {
    switch (stage) {
      case MenopauseStage.irregular:
        return 'Perimenopause';
      case MenopauseStage.noPeriod12Months:
        return 'Menopause';
      case MenopauseStage.postmenopause:
        return 'Postmenopause';
      case MenopauseStage.surgical:
        return 'Surgical Menopause';
      case MenopauseStage.pcos:
        return 'PCOS & Hormonal';
    }
  }

  String _mapQ1ValueToDisplay(MenopauseStage stage, String? q1Val) {
    if (q1Val == null) return 'Not specified';
    switch (stage) {
      case MenopauseStage.irregular:
        switch (q1Val) {
          case 'less_than_6': return 'Less than 6 months';
          case '6_to_12': return '6 months to 1 year';
          case 'over_1_year': return 'Over 1 year';
          default: return 'Not sure';
        }
      case MenopauseStage.noPeriod12Months:
        switch (q1Val) {
          case '1_year': return 'Around 1 year ago';
          case '1_2_years': return '1-2 years ago';
          case '2_5_years': return '2-5 years ago';
          default: return 'More than 5 years ago';
        }
      case MenopauseStage.postmenopause:
        switch (q1Val) {
          case 'less_2': return 'Less than 2 years';
          case '2_5': return '2-5 years';
          case 'over_5': return 'More than 5 years';
          default: return 'Not sure';
        }
      case MenopauseStage.surgical:
        switch (q1Val) {
          case 'less_6m': return 'Within the last 6 months';
          case '6m_2y': return '6 months to 2 years ago';
          default: return 'More than 2 years ago';
        }
      case MenopauseStage.pcos:
        switch (q1Val) {
          case 'recent': return 'Recently diagnosed';
          case '1_5y': return '1-5 years';
          default: return 'More than 5 years';
        }
    }
  }

  void _save() {
    final stageName = _mapStageEnumToString(_selectedStage!);
    final age = int.tryParse(_ageController.text.trim()) ?? widget.currentAge;
    final yearsInStage = _mapQ1ValueToDisplay(_selectedStage!, _q1Value);

    widget.onSave(stageName, age, yearsInStage);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hormonal situation updated successfully!'),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFFEF8F6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (_step > 0)
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF67594E)),
                        onPressed: () => setState(() => _step = 0),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF2EDE9),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: 8),
                    Text(
                      _step == 0 ? 'Update Stage' : 'Stage Details',
                      style: GoogleFonts.notoSerif(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF67594E),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF67594E)),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF2EDE9),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF2EDE9)),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _step == 0 ? _buildStep0() : _buildStep1(),
            ),
          ),
          
          Container(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 40 + MediaQuery.of(context).viewInsets.bottom),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF8F6),
              border: Border(top: BorderSide(color: Color(0xFFF2EDE9))),
            ),
            child: _step == 0
                ? ElevatedButton(
                    onPressed: _selectedStage != null ? () => setState(() => _step = 1) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF817266),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
                    child: Text(
                      'CONTINUE',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _step = 0),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF817266), width: 1.5),
                            minimumSize: const Size(0, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: Text(
                            'BACK',
                            style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: const Color(0xFF817266), letterSpacing: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _q1Value != null ? _save : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF817266),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            elevation: 0,
                          ),
                          child: Text(
                            'SAVE CHANGES',
                            style: GoogleFonts.manrope(fontWeight: FontWeight.bold, letterSpacing: 1.5),
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

  Widget _buildStep0() {
    final stages = [
      _StageItem(
        stage: MenopauseStage.irregular,
        title: 'Irregular periods',
        subtitle: 'My periods have become irregular (Perimenopause)',
        icon: Icons.autorenew,
      ),
      _StageItem(
        stage: MenopauseStage.noPeriod12Months,
        title: 'No period for 12+ months',
        subtitle: 'The clinical marker of menopause transition',
        icon: Icons.pause_circle_outline,
      ),
      _StageItem(
        stage: MenopauseStage.postmenopause,
        title: 'Postmenopause',
        subtitle: 'Long-term physiological stabilization achieved',
        icon: Icons.check_circle_outline,
      ),
      _StageItem(
        stage: MenopauseStage.surgical,
        title: 'Surgical menopause',
        subtitle: 'Non-linear transition due to surgical intervention',
        icon: Icons.medical_services_outlined,
      ),
      _StageItem(
        stage: MenopauseStage.pcos,
        title: 'PCOS & Hormonal Condition',
        subtitle: 'Special PCOS or other complex hormonal condition',
        icon: Icons.hub_outlined,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select your current stage',
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1D1B1A).withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 16),
        ...stages.map((item) {
          final isSelected = _selectedStage == item.stage;
          return ProfileRadioCard(
            title: item.title,
            subtitle: item.subtitle,
            isSelected: isSelected,
            onTap: () => setState(() => _selectedStage = item.stage),
          );
        }),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuestionsForStage(_selectedStage!),
        const SizedBox(height: 32),
        const Divider(color: Color(0xFFF2EDE9)),
        const SizedBox(height: 24),
        Text(
          'Confirm your Age',
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1D1B1A),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'e.g. 51',
            hintStyle: TextStyle(color: const Color(0xFF4D453F).withOpacity(0.4)),
            filled: true,
            fillColor: const Color(0xFFF2EDE9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildQuestionsForStage(MenopauseStage stage) {
    switch (stage) {
      case MenopauseStage.irregular:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How long have your periods been irregular?',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1D1B1A),
              ),
            ),
            const SizedBox(height: 16),
            ProfileRadioCard(
              title: 'Less than 6 months',
              isSelected: _q1Value == 'less_than_6',
              onTap: () => setState(() => _q1Value = 'less_than_6'),
            ),
            ProfileRadioCard(
              title: '6 months to 1 year',
              isSelected: _q1Value == '6_to_12',
              onTap: () => setState(() => _q1Value = '6_to_12'),
            ),
            ProfileRadioCard(
              title: 'Over 1 year',
              isSelected: _q1Value == 'over_1_year',
              onTap: () => setState(() => _q1Value = 'over_1_year'),
            ),
            ProfileRadioCard(
              title: "I'm not sure",
              isSelected: _q1Value == 'unsure',
              onTap: () => setState(() => _q1Value = 'unsure'),
            ),
          ],
        );
      case MenopauseStage.noPeriod12Months:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How long ago was your last period?',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1D1B1A),
              ),
            ),
            const SizedBox(height: 16),
            ProfileRadioCard(
              title: 'Around 1 year ago',
              isSelected: _q1Value == '1_year',
              onTap: () => setState(() => _q1Value = '1_year'),
            ),
            ProfileRadioCard(
              title: '1-2 years ago',
              isSelected: _q1Value == '1_2_years',
              onTap: () => setState(() => _q1Value = '1_2_years'),
            ),
            ProfileRadioCard(
              title: '2-5 years ago',
              isSelected: _q1Value == '2_5_years',
              onTap: () => setState(() => _q1Value = '2_5_years'),
            ),
            ProfileRadioCard(
              title: 'More than 5 years ago',
              isSelected: _q1Value == 'over_5_years',
              onTap: () => setState(() => _q1Value = 'over_5_years'),
            ),
          ],
        );
      case MenopauseStage.postmenopause:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How long have you been in postmenopause?',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1D1B1A),
              ),
            ),
            const SizedBox(height: 16),
            ProfileRadioCard(
              title: 'Less than 2 years',
              isSelected: _q1Value == 'less_2',
              onTap: () => setState(() => _q1Value = 'less_2'),
            ),
            ProfileRadioCard(
              title: '2-5 years',
              isSelected: _q1Value == '2_5',
              onTap: () => setState(() => _q1Value = '2_5'),
            ),
            ProfileRadioCard(
              title: 'More than 5 years',
              isSelected: _q1Value == 'over_5',
              onTap: () => setState(() => _q1Value = 'over_5'),
            ),
            ProfileRadioCard(
              title: "I'm not sure",
              isSelected: _q1Value == 'unsure',
              onTap: () => setState(() => _q1Value = 'unsure'),
            ),
          ],
        );
      case MenopauseStage.surgical:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'When did you have surgery?',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1D1B1A),
              ),
            ),
            const SizedBox(height: 16),
            ProfileRadioCard(
              title: 'Within the last 6 months',
              isSelected: _q1Value == 'less_6m',
              onTap: () => setState(() => _q1Value = 'less_6m'),
            ),
            ProfileRadioCard(
              title: '6 months to 2 years ago',
              isSelected: _q1Value == '6m_2y',
              onTap: () => setState(() => _q1Value = '6m_2y'),
            ),
            ProfileRadioCard(
              title: 'More than 2 years ago',
              isSelected: _q1Value == 'over_2y',
              onTap: () => setState(() => _q1Value = 'over_2y'),
            ),
          ],
        );
      case MenopauseStage.pcos:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How long have you had this condition?',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1D1B1A),
              ),
            ),
            const SizedBox(height: 16),
            ProfileRadioCard(
              title: 'Recently diagnosed',
              isSelected: _q1Value == 'recent',
              onTap: () => setState(() => _q1Value = 'recent'),
            ),
            ProfileRadioCard(
              title: '1-5 years',
              isSelected: _q1Value == '1_5y',
              onTap: () => setState(() => _q1Value = '1_5y'),
            ),
            ProfileRadioCard(
              title: 'More than 5 years',
              isSelected: _q1Value == 'over_5y',
              onTap: () => setState(() => _q1Value = 'over_5y'),
            ),
          ],
        );
    }
  }
}

class _StageItem {
  final MenopauseStage stage;
  final String title;
  final String subtitle;
  final IconData icon;

  _StageItem({
    required this.stage,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
