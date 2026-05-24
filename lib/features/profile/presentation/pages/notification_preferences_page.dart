import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/utils/animation_system.dart';
import 'package:eunora/features/profile/presentation/widgets/notification_permission_dialog.dart';

class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  State<NotificationPreferencesPage> createState() => _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState extends State<NotificationPreferencesPage> {
  // Switch states
  bool _hrtReminder = true;
  bool _eveningLogReminder = true;
  bool _weeklyDigest = false;
  bool _changeAlerts = true;
  bool _healthTips = true;
  bool _quietHours = false;

  // Selected times
  TimeOfDay _hrtTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _eveningLogTime = const TimeOfDay(hour: 20, minute: 0);

  // Frequency
  String _healthTipsFrequency = 'Weekly';

  // Delivery type selection
  String _notificationType = 'Push notifications on device';

  Future<void> _selectHrtTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _hrtTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _hrtTime) {
      setState(() {
        _hrtTime = picked;
      });
    }
  }

  Future<void> _selectEveningTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _eveningLogTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _eveningLogTime) {
      setState(() {
        _eveningLogTime = picked;
      });
    }
  }

  void _showTestNotification() {
    // Show the custom permission dialog overlay first
    showDialog(
      context: context,
      builder: (context) => const NotificationPermissionDialog(),
    ).then((granted) {
      if (granted == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.primary,
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Eunora HRT Reminder',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'It is time to take your Estradiol dose.',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.notoSerif(
                color: AppTheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Customize reminders and alerts',
              style: GoogleFonts.manrope(
                color: AppTheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section 1: Take Your HRT
            _buildSettingsContainer(
              children: [
                _buildHeaderWithSwitch(
                  title: 'Take Your HRT',
                  subtitle: 'Daily reminder to take your medication',
                  value: _hrtReminder,
                  onChanged: (val) => setState(() => _hrtReminder = val),
                ),
                if (_hrtReminder) ...[
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _selectHrtTime(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDDDF5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Reminder time: ${_hrtTime.format(context)}',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4D4355),
                            ),
                          ),
                          const Icon(
                            Icons.schedule,
                            color: Color(0xFF4D4355),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Section 2: Evening Log Reminder
            _buildSettingsContainer(
              children: [
                _buildHeaderWithSwitch(
                  title: 'Evening Log Reminder',
                  subtitle: 'Daily reminder to log your symptoms',
                  value: _eveningLogReminder,
                  onChanged: (val) => setState(() => _eveningLogReminder = val),
                ),
                if (_eveningLogReminder) ...[
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _selectEveningTime(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDDDF5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Reminder time: ${_eveningLogTime.format(context)}',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4D4355),
                            ),
                          ),
                          const Icon(
                            Icons.edit_calendar,
                            color: Color(0xFF4D4355),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Section 3: Weekly Digest
            _buildSettingsContainer(
              children: [
                _buildHeaderWithSwitch(
                  title: 'Weekly Digest',
                  subtitle: 'Email summary of your week every Sunday',
                  value: _weeklyDigest,
                  onChanged: (val) => setState(() => _weeklyDigest = val),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 4: Significant Change Alerts
            _buildSettingsContainer(
              isBorderLeft: true,
              children: [
                _buildHeaderWithSwitch(
                  title: 'Significant Change Alerts',
                  subtitle: 'Notify me when symptoms change significantly',
                  value: _changeAlerts,
                  onChanged: (val) => setState(() => _changeAlerts = val),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.primary, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'E.g., if severity doubles on a single day',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.outline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 5: Health Tips & Updates
            _buildSettingsContainer(
              children: [
                _buildHeaderWithSwitch(
                  title: 'Health Tips & Updates',
                  subtitle: 'Get regular educational resources',
                  value: _healthTips,
                  onChanged: (val) => setState(() => _healthTips = val),
                ),
                if (_healthTips) ...[
                  const SizedBox(height: 12),
                  const Divider(color: AppTheme.surfaceContainer, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Frequency',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.outline,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Change frequency state
                          setState(() {
                            _healthTipsFrequency =
                                _healthTipsFrequency == 'Weekly' ? 'Daily' : 'Weekly';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _healthTipsFrequency.toUpperCase(),
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.expand_more, size: 14, color: AppTheme.primary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Section 6: Quiet Hours
            _buildSettingsContainer(
              children: [
                _buildHeaderWithSwitch(
                  title: 'Quiet Hours',
                  subtitle: 'Silence alerts during designated sleeping times',
                  value: _quietHours,
                  onChanged: (val) => setState(() => _quietHours = val),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 7: Notification Style
            _buildSettingsContainer(
              children: [
                Text(
                  'Notification Type',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                _buildRadioOption('In-app notifications only'),
                const SizedBox(height: 12),
                _buildRadioOption('Push notifications on device'),
                const SizedBox(height: 12),
                _buildRadioOption('Email only'),
              ],
            ),
            const SizedBox(height: 32),

            // Test button area
            Column(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primary,
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppTheme.primary, width: 2),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _showTestNotification,
                  child: Text(
                    'Send Test Notification',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Test your notification settings',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsContainer({required List<Widget> children, bool isBorderLeft = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: isBorderLeft
            ? const Border(
                left: BorderSide(
                  color: AppTheme.tertiaryFixed,
                  width: 4,
                ),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: AppTheme.onSurface.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildHeaderWithSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
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
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: AppTheme.outline,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        AnimatedSwitch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primary,
        ),
      ],
    );
  }

  Widget _buildRadioOption(String optionName) {
    final isSelected = _notificationType == optionName;
    return Bounceable(
      onTap: () {
        setState(() {
          _notificationType = optionName;
        });
      },
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppTheme.primary : AppTheme.outlineVariant,
                width: isSelected ? 5 : 1,
              ),
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              optionName,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppTheme.onSurface : AppTheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
