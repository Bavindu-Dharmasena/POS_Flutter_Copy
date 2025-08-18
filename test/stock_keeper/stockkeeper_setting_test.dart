
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pos_system/features/stockkeeper/settings/settings_provider.dart';
import 'package:pos_system/features/stockkeeper/settings/stockkeeper_setting.dart';

void main() {
  group('StockKeeperSetting Widget Tests', () {
    late SettingsController settingsController;
    Widget buildTestableWidget(SettingsController controller) {
      return MaterialApp(
        home: ChangeNotifierProvider<SettingsController>.value(
          value: controller,
          child: const StockKeeperSetting(),
        ),
      );
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'isDarkMode': false,
        'fontSize': 16.0,
      });
      settingsController = SettingsController();
    });
    testWidgets('Loaded state shows settings UI', (tester) async {
      await tester.pumpWidget(buildTestableWidget(settingsController));
      await tester.pumpAndSettle();

      expect(find.text('System Settings'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);

      expect(find.byType(Card), findsNWidgets(2));

      expect(find.byKey(const Key('darkModeSwitch')), findsOneWidget);
      expect(find.byKey(const Key('fontSizeSlider')), findsOneWidget);
    });

    testWidgets('Dark mode switch toggles correctly', (tester) async {
      await tester.pumpWidget(buildTestableWidget(settingsController));
      await tester.pumpAndSettle();

      final switchFinder = find.byKey(const Key('darkModeSwitch'));
      expect(switchFinder, findsOneWidget);

      expect(settingsController.isDarkMode, isFalse);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(settingsController.isDarkMode, isTrue);
    });

    testWidgets('Font size slider updates correctly', (tester) async {
      await tester.pumpWidget(buildTestableWidget(settingsController));
      await tester.pumpAndSettle();

      final initialFontSize = settingsController.fontSize;

      final sliderFinder = find.byKey(const Key('fontSizeSlider'));
      expect(sliderFinder, findsOneWidget);

      await tester.drag(sliderFinder, const Offset(120, 0));
      await tester.pumpAndSettle();

      expect(settingsController.fontSize, isNot(equals(initialFontSize)));
      expect(settingsController.fontSize, greaterThan(initialFontSize));
    });

    testWidgets('Reset button resets settings', (tester) async {
      
      settingsController.setDark(true);
      settingsController.setFontSize(20);

      await tester.pumpWidget(buildTestableWidget(settingsController));
      await tester.pumpAndSettle();

      final resetButton = find.byKey(const Key('resetButton'));
      expect(resetButton, findsOneWidget);

      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      expect(settingsController.isDarkMode, isFalse);
      expect(settingsController.fontSize, equals(16.0));
    });

    testWidgets('Apply & Close button pops navigation', (tester) async {
      Widget testAppPushing(SettingsController controller) {
        return MaterialApp(
          home: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ChangeNotifierProvider<SettingsController>.value(
                          value: controller,
                          child: const StockKeeperSetting(),
                        ),
                  ),
                );
              });
              return const Scaffold(body: SizedBox());
            },
          ),
        );
      }

      await tester.pumpWidget(testAppPushing(settingsController));
      await tester.pumpAndSettle(); 

      expect(find.text('System Settings'), findsOneWidget);

      final applyCloseButton = find.byKey(const Key('applyCloseButton'));
      expect(applyCloseButton, findsOneWidget);

      await tester.tap(applyCloseButton);
      await tester.pumpAndSettle();

      expect(find.text('System Settings'), findsNothing);
    });

    testWidgets('Preview block shows correct font sizes', (tester) async {
      const testFontSize = 18.0;
      settingsController.setFontSize(testFontSize);

      await tester.pumpWidget(buildTestableWidget(settingsController));
      await tester.pumpAndSettle();

      final headingFinder = find.text('Preview Heading');
      expect(headingFinder, findsOneWidget);

      final headingText = tester.widget<Text>(headingFinder);
      expect(headingText.style?.fontSize, equals(testFontSize + 6));

      final bodyFinder = find.textContaining('This is how your text will look');
      final bodyText = tester.widget<Text>(bodyFinder);
      expect(bodyText.style?.fontSize, equals(testFontSize));

      final secondaryFinder = find.text('Secondary text looks like this.');
      final secondaryText = tester.widget<Text>(secondaryFinder);
      expect(secondaryText.style?.fontSize, equals(testFontSize - 2));
    });
  });
}
