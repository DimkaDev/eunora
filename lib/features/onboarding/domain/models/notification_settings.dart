class NotificationSettings {
  final bool hrtReminder;
  final bool eveningLogReminder;
  final bool weeklyDigest;
  final bool changeAlerts;
  final bool healthTips;
  final bool quietHours;
  final int hrtTimeHour;
  final int hrtTimeMinute;
  final int eveningLogTimeHour;
  final int eveningLogTimeMinute;
  final String healthTipsFrequency;
  final String notificationType;

  NotificationSettings({
    this.hrtReminder = true,
    this.eveningLogReminder = true,
    this.weeklyDigest = false,
    this.changeAlerts = true,
    this.healthTips = true,
    this.quietHours = false,
    this.hrtTimeHour = 8,
    this.hrtTimeMinute = 0,
    this.eveningLogTimeHour = 20,
    this.eveningLogTimeMinute = 0,
    this.healthTipsFrequency = 'Weekly',
    this.notificationType = 'Push notifications on device',
  });

  Map<String, dynamic> toMap() {
    return {
      'hrtReminder': hrtReminder,
      'eveningLogReminder': eveningLogReminder,
      'weeklyDigest': weeklyDigest,
      'changeAlerts': changeAlerts,
      'healthTips': healthTips,
      'quietHours': quietHours,
      'hrtTimeHour': hrtTimeHour,
      'hrtTimeMinute': hrtTimeMinute,
      'eveningLogTimeHour': eveningLogTimeHour,
      'eveningLogTimeMinute': eveningLogTimeMinute,
      'healthTipsFrequency': healthTipsFrequency,
      'notificationType': notificationType,
    };
  }

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      hrtReminder: map['hrtReminder'] as bool? ?? true,
      eveningLogReminder: map['eveningLogReminder'] as bool? ?? true,
      weeklyDigest: map['weeklyDigest'] as bool? ?? false,
      changeAlerts: map['changeAlerts'] as bool? ?? true,
      healthTips: map['healthTips'] as bool? ?? true,
      quietHours: map['quietHours'] as bool? ?? false,
      hrtTimeHour: map['hrtTimeHour'] as int? ?? 8,
      hrtTimeMinute: map['hrtTimeMinute'] as int? ?? 0,
      eveningLogTimeHour: map['eveningLogTimeHour'] as int? ?? 20,
      eveningLogTimeMinute: map['eveningLogTimeMinute'] as int? ?? 0,
      healthTipsFrequency: map['healthTipsFrequency'] as String? ?? 'Weekly',
      notificationType: map['notificationType'] as String? ?? 'Push notifications on device',
    );
  }

  NotificationSettings copyWith({
    bool? hrtReminder,
    bool? eveningLogReminder,
    bool? weeklyDigest,
    bool? changeAlerts,
    bool? healthTips,
    bool? quietHours,
    int? hrtTimeHour,
    int? hrtTimeMinute,
    int? eveningLogTimeHour,
    int? eveningLogTimeMinute,
    String? healthTipsFrequency,
    String? notificationType,
  }) {
    return NotificationSettings(
      hrtReminder: hrtReminder ?? this.hrtReminder,
      eveningLogReminder: eveningLogReminder ?? this.eveningLogReminder,
      weeklyDigest: weeklyDigest ?? this.weeklyDigest,
      changeAlerts: changeAlerts ?? this.changeAlerts,
      healthTips: healthTips ?? this.healthTips,
      quietHours: quietHours ?? this.quietHours,
      hrtTimeHour: hrtTimeHour ?? this.hrtTimeHour,
      hrtTimeMinute: hrtTimeMinute ?? this.hrtTimeMinute,
      eveningLogTimeHour: eveningLogTimeHour ?? this.eveningLogTimeHour,
      eveningLogTimeMinute: eveningLogTimeMinute ?? this.eveningLogTimeMinute,
      healthTipsFrequency: healthTipsFrequency ?? this.healthTipsFrequency,
      notificationType: notificationType ?? this.notificationType,
    );
  }
}
