import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/onboarding_header.dart';
import 'package:eunora/features/onboarding/domain/models/notification_settings.dart';
import 'package:eunora/features/onboarding/presentation/providers/menopause_stage_provider.dart';
import 'package:eunora/features/onboarding/presentation/providers/symptoms_provider.dart';
import 'package:eunora/features/onboarding/presentation/providers/medications_provider.dart';
import 'package:eunora/features/onboarding/presentation/providers/triggers_provider.dart';
import 'package:eunora/features/onboarding/presentation/providers/other_medications_provider.dart';
import 'package:eunora/features/onboarding/presentation/providers/onboarding_profile_provider.dart';
import 'package:eunora/core/utils/animation_system.dart';
import 'package:eunora/core/services/notification_service.dart';
import 'package:eunora/features/profile/presentation/widgets/notification_permission_dialog.dart';

class ActiveSetupPage extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  const ActiveSetupPage({super.key, this.onBack});

  @override
  ConsumerState<ActiveSetupPage> createState() => _ActiveSetupPageState();
}

class _ActiveSetupPageState extends ConsumerState<ActiveSetupPage> {
  TimeOfDay _hrtTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _logTime = const TimeOfDay(hour: 20, minute: 0);
  bool _hrtReminderEnabled = true;
  bool _eveningLogReminderEnabled = true;
  final List<Map<String, dynamic>> _customReminders = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(onboardingProfileProvider);
      if (profile != null) {
        setState(() {
          _hrtTime = TimeOfDay(
            hour: profile.notificationSettings.hrtTimeHour,
            minute: profile.notificationSettings.hrtTimeMinute,
          );
          _logTime = TimeOfDay(
            hour: profile.notificationSettings.eveningLogTimeHour,
            minute: profile.notificationSettings.eveningLogTimeMinute,
          );
          _hrtReminderEnabled = profile.notificationSettings.hrtReminder;
          _eveningLogReminderEnabled = profile.notificationSettings.eveningLogReminder;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF8F6), // background
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                OnboardingHeader(
                  currentStep: 9,
                  subtitle: 'REMINDERS',
                  onBack: widget.onBack,
                  onSkip: () => _showInfoDialog(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    child: Column(
                      children: [
                        _buildIntro(),
                        const SizedBox(height: 32),
                        _buildReminderCard(
                          title: 'Take your HRT',
                          subtitle: 'Primary Morning Dose',
                          emoji: '🌿',
                          bgColor: const Color(0xFFE5F3F4),
                          time: _hrtTime,
                          isEnabled: _hrtReminderEnabled,
                          onToggle: (val) => setState(() => _hrtReminderEnabled = val),
                          onTimeChanged: (newTime) => setState(() => _hrtTime = newTime),
                        ),
                        const SizedBox(height: 16),
                        _buildReminderCard(
                          title: 'Log your day',
                          subtitle: 'Evening Wind Down',
                          emoji: '🌙',
                          bgColor: const Color(0xFFEDE8F4),
                          time: _logTime,
                          isEnabled: _eveningLogReminderEnabled,
                          onToggle: (val) => setState(() => _eveningLogReminderEnabled = val),
                          onTimeChanged: (newTime) => setState(() => _logTime = newTime),
                        ),
                        ..._customReminders.map((reminder) {
                          final int index = _customReminders.indexOf(reminder);
                          return Column(
                            children: [
                              const SizedBox(height: 16),
                              _buildReminderCard(
                                title: reminder['title'] as String,
                                subtitle: 'Custom Daily Reminder',
                                emoji: reminder['emoji'] as String,
                                bgColor: const Color(0xFFF2EDE9),
                                time: reminder['time'] as TimeOfDay,
                                isEnabled: reminder['isEnabled'] as bool,
                                onToggle: (val) {
                                  setState(() {
                                    _customReminders[index]['isEnabled'] = val;
                                  });
                                },
                                onTimeChanged: (newTime) {
                                  setState(() {
                                    _customReminders[index]['time'] = newTime;
                                  });
                                },
                              ),
                            ],
                          );
                        }).toList(),
                        const SizedBox(height: 16),
                        _buildAddButton(),
                        const SizedBox(height: 24),
                        const Text(
                          'You can further customize these settings in your Profile later.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4D453F),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 160), // Footer space
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

  Widget _buildIntro() {
    return Column(
      children: [
        const Text(
          'Your Active Setup',
          style: TextStyle(
            fontFamily: 'Noto Serif',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D1B1A),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD0C4BC).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Color(0xFF655A6E), size: 16),
              SizedBox(width: 8),
              Text(
                'Daily routine: 2 active reminders',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4D453F),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Fine-tune your schedule below. These times are optimized for your biology but remain fully adjustable.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF4D453F),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildReminderCard({
    required String title,
    required String subtitle,
    required String emoji,
    required Color bgColor,
    required TimeOfDay time,
    required bool isEnabled,
    required ValueChanged<bool> onToggle,
    required Function(TimeOfDay) onTimeChanged,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isEnabled ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D1B1A),
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4D453F),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                AnimatedSwitch(
                  value: isEnabled,
                  onChanged: onToggle,
                  activeColor: const Color(0xFF817266),
                ),
              ],
            ),
            const SizedBox(height: 16),
            IgnorePointer(
              ignoring: !isEnabled,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F5F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTimeStepperButton(Icons.remove, () {
                      final newTime = _adjustTime(time, -30);
                      onTimeChanged(newTime);
                    }),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: time,
                        );
                        if (picked != null) onTimeChanged(picked);
                      },
                      child: Column(
                        children: [
                          Text(
                            _formatTime(time),
                            style: const TextStyle(
                              fontFamily: 'Noto Serif',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF655A6E),
                            ),
                          ),
                          Text(
                            time.period == DayPeriod.am ? 'AM' : 'PM',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF655A6E).withOpacity(0.6),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildTimeStepperButton(Icons.add, () {
                      final newTime = _adjustTime(time, 30);
                      onTimeChanged(newTime);
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeStepperButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF655A6E), size: 20),
      ),
    );
  }

  Widget _buildAddButton() {
    return InkWell(
      onTap: _showAddReminderSheet,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF7F756E).withOpacity(0.3),
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF4D453F).withOpacity(0.4),
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: const Icon(Icons.add, color: Color(0xFF4D453F), size: 20),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add New Reminder',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4D453F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddReminderSheet() {
    final titleController = TextEditingController();
    TimeOfDay selectedTime = const TimeOfDay(hour: 12, minute: 0);
    String selectedEmoji = '⏰';
    final emojis = ['⏰', '💊', '💧', '🍎', '🏃‍♀️', '🧘‍♀️', '🛌', '🌿', '🌙'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 40 + MediaQuery.of(context).viewInsets.bottom),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF8F6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add Daily Reminder',
                        style: GoogleFonts.notoSerif(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1D1B1A),
                        ),
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
                  const SizedBox(height: 24),
                  const Text(
                    'Reminder Title',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1D1B1A)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'e.g., Take Vitamin D, Drink water',
                      hintStyle: TextStyle(color: const Color(0xFF4D453F).withOpacity(0.4)),
                      filled: true,
                      fillColor: const Color(0xFFF2EDE9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Choose Emoji',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1D1B1A)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: emojis.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final emoji = emojis[index];
                        final isSelected = selectedEmoji == emoji;
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedEmoji = emoji),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF817266) : const Color(0xFFF2EDE9),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(emoji, style: const TextStyle(fontSize: 20)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Time',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1D1B1A)),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setModalState(() => selectedTime = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2EDE9),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(selectedTime),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1D1B1A)),
                          ),
                          Row(
                            children: [
                              Text(
                                selectedTime.period == DayPeriod.am ? 'AM' : 'PM',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4D453F)),
                              ),
                              const Icon(Icons.arrow_drop_down, color: Color(0xFF4D453F)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      final title = titleController.text.trim();
                      if (title.isNotEmpty) {
                        setState(() {
                          _customReminders.add({
                            'id': DateTime.now().millisecondsSinceEpoch % 100000,
                            'title': title,
                            'time': selectedTime,
                            'emoji': selectedEmoji,
                            'isEnabled': true,
                          });
                        });
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF817266),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'ADD REMINDER',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStickyFooter(BuildContext context) {
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
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      // Check if permission is already granted.
                      bool alreadyGranted = false;
                      try {
                        alreadyGranted = await NotificationService.instance.isPermissionGranted();
                      } catch (e) {
                        debugPrint("Error checking notification permission: $e");
                      }

                      if (!alreadyGranted) {
                        // First request permission via the custom dialog if not already granted.
                        final granted = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const NotificationPermissionDialog(),
                        );

                        if (granted == true) {
                          try {
                            await NotificationService.instance.requestPermission();
                          } catch (e) {
                            debugPrint("Error requesting notification permission: $e");
                          }
                        }
                      }

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('onboarding_completed_${user.uid}', true);

                      // Retrieve onboarding data from providers
                      final stageState = ref.read(menopauseStageProvider);
                      final selectedStage = stageState.selectedStage ?? MenopauseStage.irregular;

                      final symptomsState = ref.read(symptomsProvider);
                      final activeMeds = ref.read(medicationsProvider).medications;
                      final otherMeds = ref.read(otherMedicationsProvider).medications;

                      final settings = NotificationSettings(
                        hrtReminder: _hrtReminderEnabled,
                        eveningLogReminder: _eveningLogReminderEnabled,
                        hrtTimeHour: _hrtTime.hour,
                        hrtTimeMinute: _hrtTime.minute,
                        eveningLogTimeHour: _logTime.hour,
                        eveningLogTimeMinute: _logTime.minute,
                      );

                      ref.read(onboardingProfileProvider.notifier).updateProfile((p) => p.copyWith(
                        menopauseStage: selectedStage,
                        selectedStageSymptoms: symptomsState.loggedSymptoms.map((l) => l.symptom.id).toList(),
                        selectedTriggers: ref.read(triggersProvider).activeTriggerIds,
                        medications: activeMeds,
                        otherMedications: otherMeds,
                        notificationSettings: settings,
                      ));

                      // Apply to scheduler
                      final firstMedName = activeMeds.isNotEmpty ? activeMeds.first.name : null;
                      try {
                        await NotificationService.instance.applySettings(settings, medicationName: firstMedName);
                      } catch (e) {
                        debugPrint("Error applying notification settings: $e");
                      }

                      // Schedule custom reminders
                      for (final rem in _customReminders) {
                        try {
                          if (rem['isEnabled'] as bool) {
                            await NotificationService.instance.scheduleCustomReminder(
                              id: rem['id'] as int,
                              title: rem['title'] as String,
                              time: rem['time'] as TimeOfDay,
                            );
                          } else {
                            await NotificationService.instance.cancelById(rem['id'] as int);
                          }
                        } catch (e) {
                          debugPrint("Error scheduling custom reminder: $e");
                        }
                      }

                      try {
                        await ref.read(onboardingProfileProvider.notifier).saveToFirestore();
                      } catch (e) {
                        debugPrint("Error saving user profile to firestore: $e");
                      }
                    }
                    if (context.mounted) {
                      context.go('/product-tour');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF67594E),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Save & Start Tracking',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Your data is private, secure, and never sold. 🔒',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF4D453F).withOpacity(0.6),
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

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  TimeOfDay _adjustTime(TimeOfDay time, int minutes) {
    final totalMinutes = time.hour * 60 + time.minute + minutes;
    final normalizedMinutes = (totalMinutes + 24 * 60) % (24 * 60);
    return TimeOfDay(hour: normalizedMinutes ~/ 60, minute: normalizedMinutes % 60);
  }

  void _showInfoDialog(BuildContext context) {
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
                  'Daily Tracking setup',
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
              'You are setting up notification schedules to consistently track and improve your wellness journey.',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF4D453F),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoRow(
              icon: Icons.notifications,
              title: 'Gentle Reminders',
              desc: 'Reminders help you build a daily check-in habit without feeling overwhelmed.',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.query_stats,
              title: 'Data-Driven Insights',
              desc: 'Consistent logs allow Eunora\'s AI to deliver high-quality, personalized health reports.',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.done_all,
              title: 'Almost Finished',
              desc: 'Setting up these preferences completes your onboarding health profile.',
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
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFF1D1B1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: const Color(0xFF4D453F),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
