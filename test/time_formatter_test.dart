import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/core/utils/time_formatter.dart';

void main() {
  group('AppTimeFormatter Unit Tests', () {
    test('parseTimeOfDay correctly parses 12-hour AM/PM formats', () {
      final t1 = AppTimeFormatter.parseTimeOfDay('10:17 PM');
      expect(t1.hour, 22);
      expect(t1.minute, 17);

      final t2 = AppTimeFormatter.parseTimeOfDay('10:17 AM');
      expect(t2.hour, 10);
      expect(t2.minute, 17);

      final t3 = AppTimeFormatter.parseTimeOfDay('12:00 AM');
      expect(t3.hour, 0);
      expect(t3.minute, 0);

      final t4 = AppTimeFormatter.parseTimeOfDay('12:30 PM');
      expect(t4.hour, 12);
      expect(t4.minute, 30);

      final t5 = AppTimeFormatter.parseTimeOfDay('8:05 pm');
      expect(t5.hour, 20);
      expect(t5.minute, 5);
    });

    test('parseTimeOfDay correctly parses 24-hour formats', () {
      final t1 = AppTimeFormatter.parseTimeOfDay('22:17');
      expect(t1.hour, 22);
      expect(t1.minute, 17);

      final t2 = AppTimeFormatter.parseTimeOfDay('08:30');
      expect(t2.hour, 8);
      expect(t2.minute, 30);

      final t3 = AppTimeFormatter.parseTimeOfDay('00:00');
      expect(t3.hour, 0);
      expect(t3.minute, 0);
    });

    test('extractTimeFromStatus correctly extracts and formats time', () {
      expect(AppTimeFormatter.extractTimeFromStatus('Taken 10:17 PM'), '10:17 PM');
      expect(AppTimeFormatter.extractTimeFromStatus('Taken 22:17'), '10:17 PM');
      expect(AppTimeFormatter.extractTimeFromStatus('Taken 08:30'), '08:30 AM');
      expect(AppTimeFormatter.extractTimeFromStatus('Taken 08:30 AM'), '08:30 AM');
      expect(AppTimeFormatter.extractTimeFromStatus('Not taken', defaultFallback: '08:00 AM'), '08:00 AM');
    });

    test('formatTimeOfDay produces standardized 12-hour and 24-hour strings', () {
      const evening = TimeOfDay(hour: 22, minute: 17);
      const morning = TimeOfDay(hour: 8, minute: 5);

      expect(AppTimeFormatter.formatTimeOfDay(evening, mode: TimeFormatMode.twelveHour), '10:17 PM');
      expect(AppTimeFormatter.formatTimeOfDay(morning, mode: TimeFormatMode.twelveHour), '08:05 AM');

      expect(AppTimeFormatter.formatTimeOfDay(evening, mode: TimeFormatMode.twentyFourHour), '22:17');
      expect(AppTimeFormatter.formatTimeOfDay(morning, mode: TimeFormatMode.twentyFourHour), '08:05');
    });

    test('formatTimeString standardizes any time string', () {
      expect(AppTimeFormatter.formatTimeString('22:17'), '10:17 PM');
      expect(AppTimeFormatter.formatTimeString('10:17 PM'), '10:17 PM');
      expect(AppTimeFormatter.formatTimeString('8:30'), '08:30 AM');
      expect(AppTimeFormatter.formatTimeString('08:30 AM'), '08:30 AM');
      expect(AppTimeFormatter.formatTimeString(''), '');
    });
  });
}
