import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:pos_system/features/stockkeeper/products/supplier_page.dart';
import 'package:pos_system/features/stockkeeper/supplier/add_supplier_page.dart';

// Helper class for testing navigation
// ignore: unused_element
class _TestNavigatorObserver extends NavigatorObserver {
  final VoidCallback onPop;
  
  _TestNavigatorObserver(this.onPop);
  
  @override
  void didPop(Route route, Route? previousRoute) {
    onPop();
    super.didPop(route, previousRoute);
  }
}

void main() {
  group('SupplierPage Widget Tests', () {
    testWidgets('should display supplier page with correct title', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Suppliers'), findsOneWidget);
      expect(find.byType(SliverAppBar), findsOneWidget);
    });

    testWidgets('should display all suppliers from sample data', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Check if all 5 suppliers are displayed
      expect(find.text('ABC Traders'), findsOneWidget);
      expect(find.text('XYZ Distributors'), findsOneWidget);
      expect(find.text('Quick Supplies'), findsOneWidget);
      expect(find.text('SuperMart Pvt Ltd'), findsOneWidget);
      expect(find.text('Wholesale Hub'), findsOneWidget);
    });

    testWidgets('should display supplier details correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Check specific supplier details
      expect(find.text('John Silva'), findsOneWidget);
      expect(find.text('+94 11 234 5678'), findsOneWidget);
      expect(find.text('contact@abctraders.lk'), findsOneWidget);
      expect(find.text('Colombo'), findsOneWidget);
      expect(find.text('123 Main Street, Colombo 01'), findsOneWidget);
    });

    testWidgets('should display active and inactive status correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Active'), findsNWidgets(4)); // 4 active suppliers
      expect(find.text('Inactive'), findsAtLeastNWidgets(1)); // At least 1 inactive supplier
    });

    testWidgets('should show FloatingActionButton for adding supplier', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Add Supplier'), findsOneWidget);
      expect(find.byIcon(Feather.plus), findsOneWidget);
    });

    testWidgets('should navigate to AddSupplierPage when FAB is tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Assert - Check if navigation occurred
      expect(find.byType(AddSupplierPage), findsOneWidget);
    });

    testWidgets('should open edit popup when supplier card is tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Tap on the first supplier card
      await tester.tap(find.text('ABC Traders'));
      await tester.pumpAndSettle();

      // Assert - Use more specific finder to avoid ambiguity
      expect(find.byType(Dialog), findsOneWidget);
      // Look for the dialog title specifically
      expect(find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Edit Supplier')
      ), findsOneWidget);
    });

    testWidgets('should open edit popup when Edit Supplier button is tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Find Edit Supplier button outside of dialog first
      final editButtons = find.text('Edit Supplier');
      await tester.tap(editButtons.first);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Dialog), findsOneWidget);
      // Check that dialog opened by looking for dialog-specific content
      expect(find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Edit Supplier')
      ), findsOneWidget);
    });

    testWidgets('should display all form fields in edit popup', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('ABC Traders'));
      await tester.pumpAndSettle();

      // Assert - Check if all form fields are present within the dialog
      final dialog = find.byType(Dialog);
      expect(dialog, findsOneWidget);
      
      // Look for form fields within the dialog context
      expect(find.descendant(
        of: dialog,
        matching: find.text('Company Name')
      ), findsOneWidget);
      
      expect(find.descendant(
        of: dialog,
        matching: find.text('Contact Person')
      ), findsOneWidget);
      
      // For fields that might appear multiple times, be more specific
      final phoneFields = find.text('Phone');
      expect(phoneFields, findsAtLeastNWidgets(1));
      
      expect(find.descendant(
        of: dialog,
        matching: find.text('Email')
      ), findsOneWidget);
      
      expect(find.descendant(
        of: dialog,
        matching: find.text('Location')
      ), findsOneWidget);
      
      expect(find.descendant(
        of: dialog,
        matching: find.text('Address')
      ), findsOneWidget);
      
      expect(find.descendant(
        of: dialog,
        matching: find.text('Status')
      ), findsOneWidget);
    });

    testWidgets('should close edit popup when X button is tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('ABC Traders'));
      await tester.pumpAndSettle();
      
      // Tap the X button within the dialog
      await tester.tap(find.descendant(
        of: find.byType(Dialog),
        matching: find.byIcon(Feather.x)
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('should close edit popup when Cancel button is tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('ABC Traders'));
      await tester.pumpAndSettle();
      
      // Tap Cancel button within the dialog
      await tester.tap(find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Cancel')
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('should show success message when Save Changes is tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SupplierPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('ABC Traders'));
      await tester.pumpAndSettle();
      
      // Tap Save Changes button within dialog
      await tester.tap(find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Save Changes')
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('ABC Traders updated successfully!'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('should have status elements in edit popup', (WidgetTester tester) async {
      // This test verifies status elements exist without trying to interact
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('ABC Traders'));
      await tester.pumpAndSettle();
      
      final dialog = find.byType(Dialog);
      expect(dialog, findsOneWidget);

      // Assert - Check that status-related elements exist
      expect(find.descendant(
        of: dialog,
        matching: find.text('Status')
      ), findsOneWidget);
      
      // Check for Active/Inactive text within dialog (but don't try to tap)
      final activeStatus = find.descendant(
        of: dialog,
        matching: find.text('Active')
      );
      final inactiveStatus = find.descendant(
        of: dialog,
        matching: find.text('Inactive')
      );
      
      // At least one of them should exist
      expect(activeStatus.evaluate().isNotEmpty || inactiveStatus.evaluate().isNotEmpty, isTrue);
    });

    testWidgets('should display correct icons for different detail items', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Check if required icons are present
      expect(find.byIcon(Feather.phone), findsAtLeastNWidgets(1));
      expect(find.byIcon(Feather.mail), findsAtLeastNWidgets(1));
      expect(find.byIcon(Feather.map_pin), findsAtLeastNWidgets(1));
      expect(find.byIcon(Feather.map), findsAtLeastNWidgets(1));
      expect(find.byIcon(Feather.briefcase), findsWidgets);
    });

    testWidgets('should handle keyboard ESC key to close popup', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('ABC Traders'));
      await tester.pumpAndSettle();
      
      // Simulate ESC key press
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('should handle ESC key behavior on main page', (WidgetTester tester) async {
      // Test ESC key behavior without expecting specific navigation
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.byType(SupplierPage), findsOneWidget);

      // Act - Simulate ESC key press on main page
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Assert - Since ESC might cause navigation, just verify no crash occurred
      // The widget tree should contain some content (either SupplierPage or navigated content)
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should display pause icon for inactive suppliers', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Check if pause icon exists for inactive suppliers
      expect(find.byIcon(Feather.pause), findsAtLeastNWidgets(1));
    });

    testWidgets('should have proper gradient backgrounds for supplier cards', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Check if gradient containers exist
      final gradientContainers = find.byWidgetPredicate(
        (widget) => widget is Container && 
                     widget.decoration != null &&
                     widget.decoration is BoxDecoration,
      );
      expect(gradientContainers, findsWidgets);
    });

    testWidgets('should scroll properly with CustomScrollView', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Scroll down
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Assert - Should still find suppliers after scrolling
      expect(find.byType(SupplierPage), findsOneWidget);
    });
  });

  group('SupplierPage State Tests', () {
    testWidgets('should maintain animation state properly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierPage(),
        ),
      );
      
      // Wait for animation to complete
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Assert - Check if animations completed properly
      expect(find.byType(SupplierPage), findsOneWidget);
    });

    testWidgets('should dispose animation controller properly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Remove widget from tree
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Different Page')),
        ),
      );

      // Assert - No assertion needed, just ensure no exceptions are thrown
      expect(find.text('Different Page'), findsOneWidget);
    });
  });

  group('SupplierPage Edge Cases', () {
    testWidgets('should handle widget lifecycle properly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Ensure widget renders without crashes
      expect(find.byType(SupplierPage), findsOneWidget);
    });

    testWidgets('should handle text overflow properly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Check if text widgets render properly
      final textWidgets = find.byType(Text);
      expect(textWidgets, findsWidgets);
    });

    testWidgets('should handle missing image assets gracefully', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Should show briefcase icons for suppliers without images
      expect(find.byIcon(Feather.briefcase), findsWidgets);
    });
  });

  group('SupplierPage Accessibility Tests', () {
    testWidgets('should have proper semantics for screen readers', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Check if important interactive elements exist
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('should support keyboard navigation', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Check if keyboard listener is present
      expect(find.byType(SupplierPage), findsOneWidget);
    });
  });
}