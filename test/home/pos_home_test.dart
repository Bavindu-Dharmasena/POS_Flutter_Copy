// File: test/home/pos_home_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart' as f show DiagnosticPropertiesBuilder;
import 'package:pos_system/features/home/pos_home.dart';


/// Records pushed routes so we can assert navigation occurred.
class RecordingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    super.didPush(route, previousRoute);
  }
}

void main() {
  Widget _app(Widget home) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: home,
    );
  }

  group('POSHomePage - Rendering', () {
    testWidgets('renders shop title, 4 role cards, and footer',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(const POSHomePage()));

      // Title
      expect(find.text('Tharu Shop'), findsOneWidget);

      // Footer text
      expect(find.text('Powered by AASA IT'), findsOneWidget);

      // Roles (Text)
      expect(find.text('StockKeeper'), findsOneWidget);
      expect(find.text('Cashier'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Manager'), findsOneWidget);

      // Icons (sanity)
      expect(find.byIcon(Icons.inventory_2), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long), findsOneWidget);
      expect(find.byIcon(Icons.admin_panel_settings), findsOneWidget);
      expect(find.byIcon(Icons.supervisor_account), findsOneWidget);
    });

    testWidgets('role cards use expected flat colors',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(const POSHomePage()));

      Future<void> expectCardColor(String title, Color expected) async {
        final titleFinder = find.text(title);
        expect(titleFinder, findsOneWidget);

        final cardFinder = find.ancestor(
          of: titleFinder,
          matching: find.byType(Card),
        );
        expect(cardFinder, findsOneWidget);

        final Card card = tester.widget<Card>(cardFinder);
        expect(card.color, expected);
      }

      await expectCardColor('StockKeeper', Colors.orange);
      await expectCardColor('Cashier', Colors.green);
      await expectCardColor('Admin', Colors.red);
      await expectCardColor('Manager', Colors.blue);
    });

    testWidgets('no overflow at large textScaleFactor',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: MediaQuery(
            data: const MediaQueryData(textScaleFactor: 2.6),
            child: const POSHomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Key content still present.
      expect(find.text('Tharu Shop'), findsOneWidget);
      expect(find.text('Powered by AASA IT'), findsOneWidget);
    });
  });

  group('RoleCard - Interaction & Navigation', () {
    testWidgets('each RoleCard is tappable (InkWell with onTap)',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(const POSHomePage()));

      final inkwells = find.byType(InkWell);
      expect(inkwells, findsNWidgets(4));

      for (final element in inkwells.evaluate()) {
        final ink = element.widget as InkWell;
        expect(ink.onTap, isNotNull);
      }
    });

    testWidgets('tapping StockKeeper pushes a new route',
        (WidgetTester tester) async {
      final observer = RecordingNavigatorObserver();

      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const POSHomePage(),
        navigatorObservers: [observer],
      ));

      await tester.tap(find.text('StockKeeper'));
      await tester.pumpAndSettle();

      expect(observer.pushedRoutes.length, greaterThanOrEqualTo(1));

    });

    testWidgets('tapping every role pushes a route (and returns)',
        (WidgetTester tester) async {
      final observer = RecordingNavigatorObserver();

      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const POSHomePage(),
        navigatorObservers: [observer],
      ));

      Future<void> tapAndBack(String title) async {
        await tester.tap(find.text(title));
        await tester.pumpAndSettle();
        // Back to home to proceed with next tap
        // If there's something to pop, pageBack succeeds.
        try {
          await tester.pageBack();
          await tester.pumpAndSettle();
        } catch (_) {
          // If cannot go back, ignore (shouldn't happen with this widget).
        }
      }

      await tapAndBack('StockKeeper');
      await tapAndBack('Cashier');
      await tapAndBack('Admin');
      await tapAndBack('Manager');

      expect(observer.pushedRoutes.length, greaterThanOrEqualTo(4));
    });
  });

  group('RoleCard - Diagnostics', () {
    test('debugFillProperties exposes title/subtitle/icon/color', () {
      const role = RoleCard(
        title: 'Tester',
        subtitle: 'Diagnostics',
        icon: Icons.bug_report,
        color: Colors.purple,
      );

      // Use aliased type to avoid "/*1*/ vs /*2*/" identity mismatch.
      final f.DiagnosticPropertiesBuilder builder =
          f.DiagnosticPropertiesBuilder();

      role.debugFillProperties(builder);

      final description =
          builder.properties.map((p) => p.toDescription()).join(' | ');

      expect(description, contains('title: "Tester"'));
      expect(description, contains('subtitle: "Diagnostics"'));
      expect(description, contains('IconData(U+')); // generic IconData print
      expect(description, contains('Color(0xff9c27b0)')); // Colors.purple
    });
  });

  group('Layout Sanity', () {
    testWidgets('tiles are 150x150 and include FittedBox',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(const POSHomePage()));

      // Find the InkWell that wraps the "StockKeeper" tile.
      final inkwell = find.ancestor(
        of: find.text('StockKeeper'),
        matching: find.byType(InkWell),
      );
      expect(inkwell, findsOneWidget);

      // Its ancestor SizedBox should include a 150x150 box (top of RoleCard).
      final sizedBoxes = find.ancestor(
        of: inkwell,
        matching: find.byType(SizedBox),
      );
      expect(sizedBoxes, findsWidgets);

      bool found150 = false;
      for (final e in sizedBoxes.evaluate()) {
        final sb = e.widget as SizedBox;
        if (sb.width == 150 && sb.height == 150) {
          found150 = true;
          break;
        }
      }
      expect(found150, isTrue);

      // A FittedBox per tile to shrink content if needed.
      expect(find.byType(FittedBox), findsNWidgets(4));
    });
  });
}
