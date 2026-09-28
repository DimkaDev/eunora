import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eunora/features/onboarding/presentation/pages/product_tour_page.dart';
import 'package:eunora/features/onboarding/presentation/providers/product_tour_provider.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget() {
    return const ProviderScope(
      child: MaterialApp(
        home: ProductTourPage(),
      ),
    );
  }

  group('ProductTourPage Widget Tests', () {
    testWidgets('renders first screen with header, skip button and Daily Logging card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Top bar
      expect(find.text('EUNORA TOUR'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      // First step: Daily Symptom Logging
      expect(find.text('1 of 5'), findsOneWidget);
      expect(find.text('QUICK JOURNAL'), findsOneWidget);
      expect(find.text('Daily Symptom Logging'), findsOneWidget);
      expect(find.text('Hot Flashes'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('advances through all 5 screens with Next button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 1
      expect(find.text('1 of 5'), findsOneWidget);
      expect(find.text('Daily Symptom Logging'), findsOneWidget);

      // Tap Next -> Step 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('2 of 5'), findsOneWidget);
      expect(find.text('Calendar & Weekly Trends'), findsOneWidget);

      // Tap Next -> Step 3
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('3 of 5'), findsOneWidget);
      expect(find.text('What Affects You?'), findsOneWidget);

      // Tap Next -> Step 4
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('4 of 5'), findsOneWidget);
      expect(find.text('Smart HRT Journey'), findsOneWidget);

      // Tap Next -> Step 5 (Last Screen)
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('5 of 5'), findsOneWidget);
      expect(find.text('Menopause Passport'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('productTourControllerProvider marks tour completed in SharedPreferences', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(productTourControllerProvider.notifier);
      expect(container.read(productTourControllerProvider), isFalse);

      await notifier.markTourCompleted();
      expect(container.read(productTourControllerProvider), isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('has_seen_product_tour_guest'), isTrue);
    });
  });
}
