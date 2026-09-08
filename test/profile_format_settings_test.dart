import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eunora/core/utils/date_formatter.dart';
import 'package:eunora/core/utils/time_formatter.dart';
import 'package:eunora/features/profile/presentation/pages/profile_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Date & Time Formatter Utilities', () {
    test('AppDateFormatter formats correctly across all modes', () {
      final testDate = DateTime(2026, 9, 24, 15, 30);

      expect(
        AppDateFormatter.formatDate(testDate, mode: AppDateFormatMode.dayMonthYear),
        '24/09/2026',
      );
      expect(
        AppDateFormatter.formatDate(testDate, mode: AppDateFormatMode.monthDayYear),
        '09/24/2026',
      );
      expect(
        AppDateFormatter.formatDate(testDate, mode: AppDateFormatMode.yearMonthDay),
        '2026-09-24',
      );
      expect(
        AppDateFormatter.formatDate(testDate, mode: AppDateFormatMode.dayMonthNameYear),
        '24 Sep 2026',
      );
      expect(
        AppDateFormatter.formatDate(testDate, mode: AppDateFormatMode.monthNameDayYear),
        'Sep 24, 2026',
      );
    });

    test('AppDateFormatter persistence works with SharedPreferences', () async {
      await AppDateFormatter.setMode(AppDateFormatMode.yearMonthDay);
      expect(AppDateFormatter.defaultMode, AppDateFormatMode.yearMonthDay);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppDateFormatter.prefKey), 'yearMonthDay');

      AppDateFormatter.defaultMode = AppDateFormatMode.dayMonthYear;
      await AppDateFormatter.initFromPrefs();
      expect(AppDateFormatter.defaultMode, AppDateFormatMode.yearMonthDay);
    });

    test('AppTimeFormatter persistence works with SharedPreferences', () async {
      await AppTimeFormatter.setMode(TimeFormatMode.twentyFourHour);
      expect(AppTimeFormatter.defaultMode, TimeFormatMode.twentyFourHour);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppTimeFormatter.prefKey), 'twentyFourHour');

      AppTimeFormatter.defaultMode = TimeFormatMode.twelveHour;
      await AppTimeFormatter.initFromPrefs();
      expect(AppTimeFormatter.defaultMode, TimeFormatMode.twentyFourHour);
    });
  });

  group('ProfilePage Date & Time Format Settings', () {
    testWidgets('renders Display & Format section with Date and Time format rows', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfilePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Display & Format'),
        500,
        scrollable: find.byType(Scrollable).first,
      );

      // Verify Display & Format header
      expect(find.text('Display & Format'), findsOneWidget);

      // Verify Date Format row & Time Format row
      expect(find.text('Date Format'), findsOneWidget);
      expect(find.text('Time Format'), findsOneWidget);
    });

    testWidgets('tapping Date Format opens modal and allows changing format', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfilePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Date Format'),
        500,
        scrollable: find.byType(Scrollable).first,
      );

      // Tap on Date Format row
      await tester.tap(find.text('Date Format'));
      await tester.pumpAndSettle();

      // Verify bottom sheet title and options
      expect(find.text('Choose how dates are displayed throughout the app.'), findsOneWidget);
      expect(find.text('YYYY-MM-DD'), findsOneWidget);
      expect(find.text('MM/DD/YYYY'), findsOneWidget);

      // Select YYYY-MM-DD
      await tester.tap(find.text('YYYY-MM-DD'));
      await tester.pumpAndSettle();

      // Verify preference was updated in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppDateFormatter.prefKey), 'yearMonthDay');
    });

    testWidgets('tapping Time Format opens modal and allows changing format', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfilePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Time Format'),
        500,
        scrollable: find.byType(Scrollable).first,
      );

      // Tap on Time Format row
      await tester.tap(find.text('Time Format'));
      await tester.pumpAndSettle();

      // Verify bottom sheet title and options
      expect(find.text('Choose how time is formatted for medication and logs.'), findsOneWidget);
      expect(find.text('24-hour'), findsOneWidget);
      expect(find.text('12-hour (AM/PM)'), findsOneWidget);

      // Select 24-hour
      await tester.tap(find.text('24-hour'));
      await tester.pumpAndSettle();

      // Verify preference was updated in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppTimeFormatter.prefKey), 'twentyFourHour');
    });
  });
}
