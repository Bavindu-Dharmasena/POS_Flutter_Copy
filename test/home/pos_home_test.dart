import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos_system/features/auth/login_page.dart';
import 'package:pos_system/features/home/pos_home.dart';

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRoute());
  });

  group('POSHomePage', () {
    testWidgets('shows title and footer', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: POSHomePage()));

      expect(find.text('POS SYSTEM'), findsOneWidget);
      expect(find.text('Powered by AASA IT'), findsOneWidget);
    });

    testWidgets('renders four role cards with correct labels', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: POSHomePage()));

      expect(find.text('StockKeeper'), findsOneWidget);
      expect(find.text('Manage Stock'), findsOneWidget);

      expect(find.text('Cashier'), findsOneWidget);
      expect(find.text('Quick Billing'), findsOneWidget);

      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('User Management'), findsOneWidget);

      expect(find.text('Manager'), findsOneWidget);
      expect(find.text('Oversee Sales'), findsOneWidget);

      expect(find.byType(RoleCard), findsNWidgets(4));
    });

    testWidgets(
      'tapping a role card navigates to LoginPage with correct role',
      (WidgetTester tester) async {
        final observer = MockNavigatorObserver();

        await tester.pumpWidget(
          MaterialApp(
            home: const POSHomePage(),
            navigatorObservers: [observer],
          ),
        );

        await tester.tap(find.widgetWithText(RoleCard, 'StockKeeper'));
        await tester.pumpAndSettle();

        verify(() => observer.didPush(any(), any())).called(greaterThan(0));

        final loginPageFinder = find.byType(LoginPage);
        expect(loginPageFinder, findsOneWidget);

        final loginPageWidget = tester.widget<LoginPage>(loginPageFinder);
        expect(loginPageWidget.role, equals('StockKeeper'));
      },
    );

    testWidgets('background color and layout basics', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: POSHomePage()));

      expect(find.byType(Scaffold), findsOneWidget);

      expect(find.byType(Card), findsNWidgets(4));

      expect(find.byIcon(Icons.inventory_2), findsOneWidget);
    });
  });
}

class FakeRoute extends Fake implements Route<dynamic> {}
