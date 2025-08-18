import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Import your actual file here
// import 'package:your_app/cashier_dashboard.dart';

// For this test, I'll include the widget class here
// Remove this when you import from your actual file
class CashierDashboard extends StatelessWidget {
  const CashierDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cashier Dashboard')),
      body: const Center(child: Text('Welcome, Cashier!')),
    );
  }
}

void main() {
  group('CashierDashboard Tests', () {
    testWidgets('should render correctly with all required widgets', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: CashierDashboard(),
        ),
      );

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(Center), findsOneWidget);
    });

    testWidgets('should display correct app bar title', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: CashierDashboard(),
        ),
      );

      // Assert
      expect(find.text('Cashier Dashboard'), findsOneWidget);
      
      // Verify the title is in the AppBar
      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);
      
      final AppBar appBar = tester.widget(appBarFinder);
      final Text titleWidget = appBar.title as Text;
      expect(titleWidget.data, equals('Cashier Dashboard'));
    });

    testWidgets('should display welcome message', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: CashierDashboard(),
        ),
      );

      // Assert
      expect(find.text('Welcome, Cashier!'), findsOneWidget);
    });

    testWidgets('should center the welcome message', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: CashierDashboard(),
        ),
      );

      // Assert
      final centerFinder = find.byType(Center);
      expect(centerFinder, findsOneWidget);
      
      final Center centerWidget = tester.widget(centerFinder);
      final Text childText = centerWidget.child as Text;
      expect(childText.data, equals('Welcome, Cashier!'));
    });

    testWidgets('should have correct widget hierarchy', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: CashierDashboard(),
        ),
      );

      // Assert - Check widget tree structure
      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsOneWidget);
      
      // Verify AppBar is child of Scaffold
      final scaffold = tester.widget<Scaffold>(scaffoldFinder);
      expect(scaffold.appBar, isA<AppBar>());
      expect(scaffold.body, isA<Center>());
    });

    testWidgets('should handle theme changes correctly', (WidgetTester tester) async {
      // Test with light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const CashierDashboard(),
        ),
      );

      expect(find.byType(CashierDashboard), findsOneWidget);
      expect(find.text('Cashier Dashboard'), findsOneWidget);
      expect(find.text('Welcome, Cashier!'), findsOneWidget);

      // Test with dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const CashierDashboard(),
        ),
      );

      expect(find.byType(CashierDashboard), findsOneWidget);
      expect(find.text('Cashier Dashboard'), findsOneWidget);
      expect(find.text('Welcome, Cashier!'), findsOneWidget);
    });

    testWidgets('should be accessible', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: CashierDashboard(),
        ),
      );

      // Assert - Check for accessibility
      final titleFinder = find.text('Cashier Dashboard');
      final welcomeFinder = find.text('Welcome, Cashier!');
      
      expect(titleFinder, findsOneWidget);
      expect(welcomeFinder, findsOneWidget);
      
      // Verify widgets can be tapped (basic interaction test)
      await tester.tap(find.byType(CashierDashboard));
      await tester.pump();
      
      // Should still render correctly after interaction
      expect(find.byType(CashierDashboard), findsOneWidget);
    });

    testWidgets('should maintain state after rebuild', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: CashierDashboard(),
        ),
      );

      // Trigger a rebuild
      await tester.pumpWidget(
        const MaterialApp(
          home: CashierDashboard(),
        ),
      );

      // Assert - Widget should still render correctly
      expect(find.byType(CashierDashboard), findsOneWidget);
      expect(find.text('Cashier Dashboard'), findsOneWidget);
      expect(find.text('Welcome, Cashier!'), findsOneWidget);
    });
  });

  group('CashierDashboard Widget Properties Tests', () {
    test('should have correct key parameter', () {
      // Arrange
      const key = Key('test_key');
      
      // Act
      const widget = CashierDashboard(key: key);
      
      // Assert
      expect(widget.key, equals(key));
    });

    test('should be a StatelessWidget', () {
      // Arrange & Act
      const widget = CashierDashboard();
      
      // Assert
      expect(widget, isA<StatelessWidget>());
    });

    test('should have const constructor', () {
      // This test verifies that the constructor is const
      // which is important for performance
      
      // Act & Assert - Should compile without issues
      const widget1 = CashierDashboard();
      const widget2 = CashierDashboard();
      
      // Both should be valid const widgets
      expect(widget1, isA<CashierDashboard>());
      expect(widget2, isA<CashierDashboard>());
    });
  });
}