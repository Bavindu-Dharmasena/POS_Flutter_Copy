import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:pos_system/features/stockkeeper/settings/settings_provider.dart';
import 'package:pos_system/features/stockkeeper/stockkeeper_home.dart';

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class TestSettingsController extends SettingsController {
  TestSettingsController();
}

Widget _wrapWithApp({
  required Widget child,
  NavigatorObserver? observer,
  Size? surfaceSize,
}) {
  final app = ChangeNotifierProvider<SettingsController>.value(
    value: TestSettingsController(),
    child: MaterialApp(
      home: child,
      navigatorObservers: [if (observer != null) observer],
    ),
  );

  if (surfaceSize == null) return app;

  return MediaQuery(
    data: const MediaQueryData(),
    child: LayoutBuilder(
      builder: (context, _) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: surfaceSize.width,
            height: surfaceSize.height,
            child: app,
          ),
        );
      },
    ),
  );
}

Future<void> _tapTile(WidgetTester tester, String title) async {
  final titleFinder = find.text(title);
  expect(titleFinder, findsWidgets);
  await tester.tap(titleFinder.first);
  await tester.pumpAndSettle();
}

Future<void> _ensureTextVisible(
  WidgetTester tester,
  String text, {
  int maxDrags = 12,
  double dragDelta = -300,
}) async {
  final target = find.text(text);
  if (target.evaluate().isNotEmpty) return;

  final scrollable = find.byType(Scrollable);
  if (scrollable.evaluate().isEmpty) {
    return;
  }

  for (var i = 0; i < maxDrags; i++) {
    if (target.evaluate().isNotEmpty) return;
    await tester.drag(scrollable.first, Offset(0, dragDelta));
    await tester.pumpAndSettle();
  }
  for (var i = 0; i < maxDrags; i++) {
    if (target.evaluate().isNotEmpty) return;
    await tester.drag(scrollable.first, Offset(0, -dragDelta));
    await tester.pumpAndSettle();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeRoute());
  });

  group('StockKeeperHome', () {
    testWidgets('renders all primary tiles', (tester) async {
      const size = Size(430, 900);

      await tester.pumpWidget(
        _wrapWithApp(child: const StockKeeperHome(), surfaceSize: size),
      );
      await tester.pumpAndSettle();

      const titles = [
        'Dashboard',
        'Products',
        'Inventory',
        'Reports',
        'Cashier',
        'Settings',
      ];

      for (final t in titles) {
        await _ensureTextVisible(tester, t);
        expect(find.text(t), findsWidgets, reason: 'Missing title "$t"');
      }
      await _ensureTextVisible(tester, 'Overview & Analytics');
      expect(find.text('Overview & Analytics'), findsOneWidget);

      await _ensureTextVisible(tester, 'Billing & Payments');
      expect(find.text('Billing & Payments'), findsOneWidget);
    });

    testWidgets('tap on a tile pushes a new route (navigation works)', (
      tester,
    ) async {
      final observer = MockNavigatorObserver();

      await tester.pumpWidget(
        _wrapWithApp(
          child: const StockKeeperHome(),
          observer: observer,
          surfaceSize: const Size(430, 900),
        ),
      );
      await tester.pumpAndSettle();

      clearInteractions(observer);

      await _tapTile(tester, 'Products');

      verify(
        () => observer.didPush(any(that: isA<PageRoute<dynamic>>()), any()),
      ).called(1);
    });

    testWidgets(
      'keyboard: Home then Enter activates first tile (pushes route)',
      (tester) async {
        final observer = MockNavigatorObserver();

        await tester.pumpWidget(
          _wrapWithApp(
            child: const StockKeeperHome(),
            observer: observer,
            surfaceSize: const Size(1024, 800),
          ),
        );
        await tester.pumpAndSettle();

        clearInteractions(observer);

        await tester.sendKeyEvent(LogicalKeyboardKey.home);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        verify(
          () => observer.didPush(any(that: isA<PageRoute<dynamic>>()), any()),
        ).called(1);
      },
    );

    testWidgets('drag-and-drop reorders tiles (verify positional change)', (
      tester,
    ) async {
      const size = Size(600, 900);

      await tester.pumpWidget(
        _wrapWithApp(child: const StockKeeperHome(), surfaceSize: size),
      );
      await tester.pumpAndSettle();

      final dashboardPosBefore = tester.getTopLeft(
        find.text('Dashboard').first,
      );
      final productsPosBefore = tester.getTopLeft(find.text('Products').first);

      final productsCenter = tester.getCenter(find.text('Products').first);
      final dashboardCenter = tester.getCenter(find.text('Dashboard').first);

      final gesture = await tester.startGesture(productsCenter);

      await gesture.moveTo(Offset(dashboardCenter.dx, dashboardCenter.dy));
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.up();
      await tester.pumpAndSettle();

      final dashboardPosAfter = tester.getTopLeft(find.text('Dashboard').first);
      final productsPosAfter = tester.getTopLeft(find.text('Products').first);

      final productsIsAboveOrLeft =
          (productsPosAfter.dy < dashboardPosAfter.dy) ||
          (productsPosAfter.dy == dashboardPosAfter.dy &&
              productsPosAfter.dx <= dashboardPosAfter.dx);

      expect(
        productsIsAboveOrLeft,
        isTrue,
        reason:
            'Products tile should be positioned before Dashboard after reorder.\n'
            'Before: Dashboard=$dashboardPosBefore, Products=$productsPosBefore\n'
            'After : Dashboard=$dashboardPosAfter, Products=$productsPosAfter',
      );
    });
  });
}

class FakeRoute extends Fake implements Route<dynamic> {}
