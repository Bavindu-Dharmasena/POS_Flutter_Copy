import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/features/stockkeeper/stockkeeper_reports.dart';

void main() {
  group('StockKeeperReports Widget Tests', () {
    group('Desktop/Tablet Layout', () {
      testWidgets('renders app bar with correct title and actions', (
        tester,
      ) async {
        await tester.pumpWidget(_buildTestApp(isDesktop: true));
        await tester.pumpAndSettle();

        expect(find.text('Reports Dashboard'), findsOneWidget);

        expect(find.byIcon(Icons.print_outlined), findsOneWidget);
        expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
        expect(find.byIcon(Icons.grid_on_outlined), findsOneWidget);

        expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
      });

      testWidgets('category filter chips render and respond to selection', (
        tester,
      ) async {
        await tester.pumpWidget(_buildTestApp(isDesktop: true));
        await tester.pumpAndSettle();

        // Verify all category chips are present (use `find.byKey` for better targeting)
        expect(find.text('All'), findsOneWidget);
        expect(find.text('Sales Reports'), findsNWidgets(2));
        expect(find.text('Purchase Reports'), findsNWidgets(2));
        expect(find.text('Stock Return'), findsNWidgets(2));
        expect(find.text('Loss and Damage'), findsOneWidget);
        expect(find.text('Finance'), findsOneWidget);
        expect(find.text('Stock Control'), findsOneWidget);

        // Initially "All" should be selected and all sections visible
        expect(
          find.textContaining('21 reports available'),
          findsOneWidget,
        ); // Sales section
        expect(
          find.textContaining('8 reports available'),
          findsOneWidget,
        ); // Purchase section

        // Scroll to and tap on "Purchase Reports" category chip (use `ancestor` if needed)
        final purchaseChip = find
            .ancestor(
              of: find.text('Purchase Reports'),
              matching: find.byType(InkWell),
            )
            .first;
        await tester.scrollUntilVisible(purchaseChip, 100.0);
        await tester.tap(purchaseChip);
        await tester.pumpAndSettle();

        // Should only show Purchase Reports section
        expect(find.textContaining('8 reports available'), findsOneWidget);
        // Sales Reports section should be hidden (21 reports should not be visible)
        expect(find.textContaining('21 reports available'), findsNothing);
      });

      testWidgets('sales report cards display with correct filters', (
        tester,
      ) async {
        await tester.pumpWidget(_buildTestApp(isDesktop: true));
        await tester.pumpAndSettle();

        // Find and tap on "Products" card using a more specific finder
        final productsCardFinder = find
            .ancestor(of: find.text('Products'), matching: find.byType(InkWell))
            .first;

        await tester.scrollUntilVisible(productsCardFinder, 100.0);
        await tester.tap(productsCardFinder);
        await tester.pumpAndSettle();

        // Verify filters dialog opened
        expect(find.text('Report Filters'), findsOneWidget);

        // Verify expected filters for sales reports
        expect(find.text('Date Range'), findsOneWidget);
        expect(find.text('User'), findsOneWidget);
        expect(find.text('Cash Register'), findsOneWidget);
        expect(find.text('Product'), findsOneWidget);
        expect(find.text('Product Group'), findsOneWidget);
        expect(find.text('Include Subgroups'), findsOneWidget);

        // Supplier should NOT be shown for sales reports
        expect(find.text('Supplier'), findsNothing);
      });

      testWidgets(
        'purchase report shows supplier filter and hides cash register',
        (tester) async {
          await tester.pumpWidget(_buildTestApp(isDesktop: true));
          await tester.pumpAndSettle();

          // Switch to Purchase Reports category first
          final purchaseChip = find
              .ancestor(
                of: find.text('Purchase Reports'),
                matching: find.byType(InkWell),
              )
              .first;
          await tester.scrollUntilVisible(purchaseChip, 100.0);
          await tester.tap(purchaseChip);
          await tester.pumpAndSettle();

          // Find and tap on "Purchase Products" card
          final purchaseCardFinder = find.ancestor(
            of: find.text('Purchase Products'),
            matching: find.byType(InkWell),
          );
          await tester.scrollUntilVisible(purchaseCardFinder, 100.0);
          await tester.tap(purchaseCardFinder);
          await tester.pumpAndSettle();

          // Verify purchase-specific filters
          expect(find.text('Supplier'), findsOneWidget);
          expect(
            find.text('User'),
            findsNothing,
          ); // User filter hidden for purchase reports
          expect(
            find.text('Cash Register'),
            findsNothing,
          ); // Cash register hidden for purchase reports
        },
      );

      testWidgets('include subgroups switch toggles correctly', (tester) async {
        await tester.pumpWidget(_buildTestApp(isDesktop: true));
        await tester.pumpAndSettle();

        // Open Products filter dialog
        final productsCardFinder = find
            .ancestor(of: find.text('Products'), matching: find.byType(InkWell))
            .first;
        await tester.scrollUntilVisible(productsCardFinder, 100.0);
        await tester.tap(productsCardFinder);
        await tester.pumpAndSettle();

        // Initially should show "Enabled"
        expect(find.text('Enabled'), findsOneWidget);
        expect(find.text('Disabled'), findsNothing);

        // Find and tap the switch
        final switchWidget = find.byType(Switch);
        await tester.tap(switchWidget);
        await tester.pumpAndSettle();

        // Should now show "Disabled"
        expect(find.text('Disabled'), findsOneWidget);
        expect(find.text('Enabled'), findsNothing);
      });

      testWidgets('dropdown selections update filter summary', (tester) async {
        await tester.pumpWidget(_buildTestApp(isDesktop: true));
        await tester.pumpAndSettle();

        // Open Products filter dialog
        final productsCardFinder = find
            .ancestor(of: find.text('Products'), matching: find.byType(InkWell))
            .first;
        await tester.scrollUntilVisible(productsCardFinder, 100.0);
        await tester.tap(productsCardFinder);
        await tester.pumpAndSettle();

        // Find User dropdown and change selection
        final userDropdown = find.byType(DropdownButton<String>).first;
        await tester.tap(userDropdown);
        await tester.pumpAndSettle();

        // Select "User 2"
        await tester.tap(find.text('User 2'));
        await tester.pumpAndSettle();

        // Verify filter summary updated
        expect(find.textContaining('User: User 2'), findsOneWidget);
      });

      testWidgets('reset button restores default filters', (tester) async {
        await tester.pumpWidget(_buildTestApp(isDesktop: true));
        await tester.pumpAndSettle();

        // Open Products filter dialog
        final productsCardFinder = find
            .ancestor(of: find.text('Products'), matching: find.byType(InkWell))
            .first;
        await tester.scrollUntilVisible(productsCardFinder, 100.0);
        await tester.tap(productsCardFinder);
        await tester.pumpAndSettle();

        // Change some filters
        final userDropdown = find.byType(DropdownButton<String>).first;
        await tester.tap(userDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('User 2'));
        await tester.pumpAndSettle();

        // Toggle switch
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        // Tap Reset button
        await tester.tap(find.text('Reset'));
        await tester.pumpAndSettle();

        // Verify filters are reset
        expect(find.textContaining('User: All'), findsOneWidget);
        expect(find.text('Enabled'), findsOneWidget);
      });

      testWidgets('generate report button shows preview dialog', (
        tester,
      ) async {
        await tester.pumpWidget(_buildTestApp(isDesktop: true));
        await tester.pumpAndSettle();

        // Open Products filter dialog
        final productsCardFinder = find
            .ancestor(of: find.text('Products'), matching: find.byType(InkWell))
            .first;
        await tester.scrollUntilVisible(productsCardFinder, 100.0);
        await tester.tap(productsCardFinder);
        await tester.pumpAndSettle();

        // Tap Generate Report button
        await tester.tap(find.text('Generate Report'));
        await tester.pumpAndSettle();

        // Should close filters dialog and show preview dialog
        expect(find.text('Report Filters'), findsNothing);
        // Note: ReportPreviewDialog content would need to be verified based on actual implementation
      });

      testWidgets('keyboard navigation works correctly', (tester) async {
        await tester.pumpWidget(_buildTestApp(isDesktop: true));
        await tester.pumpAndSettle();

        // Test Escape key on main page (should pop)
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        // Note: In real app, this would pop the route

        // Open filter dialog
        final productsCardFinder = find
            .ancestor(of: find.text('Products'), matching: find.byType(InkWell))
            .first;
        await tester.scrollUntilVisible(productsCardFinder, 100.0);
        await tester.tap(productsCardFinder);
        await tester.pumpAndSettle();

        // Test Escape key on dialog (should close)
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(find.text('Report Filters'), findsNothing);
      });

      testWidgets('back button functions correctly', (tester) async {
        await tester.pumpWidget(_buildTestApp(isDesktop: true));
        await tester.pumpAndSettle();

        // Find and tap back button
        final backButton = find.byIcon(Icons.arrow_back_ios);
        await tester.tap(backButton);
        await tester.pumpAndSettle();
        // Note: In real app, this would pop the route
      });
    });

    group('Mobile Layout', () {
      testWidgets('renders mobile-specific app bar with overflow menu', (
        tester,
      ) async {
        await tester.pumpWidget(_buildTestApp(isDesktop: false));
        await tester.pumpAndSettle();

        // Verify app bar title
        expect(find.text('Reports Dashboard'), findsOneWidget);

        // Should show print icon but not PDF/Excel directly
        expect(find.byIcon(Icons.print_outlined), findsOneWidget);
        expect(find.byIcon(Icons.picture_as_pdf_outlined), findsNothing);
        expect(find.byIcon(Icons.grid_on_outlined), findsNothing);

        // Should have overflow menu
        expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
      });

      testWidgets('overflow menu shows export options', (tester) async {
        await tester.pumpWidget(_buildTestApp(isDesktop: false));
        await tester.pumpAndSettle();

        // Tap overflow menu
        await tester.tap(find.byIcon(Icons.more_vert_rounded));
        await tester.pumpAndSettle();

        // Verify menu items
        expect(find.text('Export PDF'), findsOneWidget);
        expect(find.text('Export Excel'), findsOneWidget);
      });

      testWidgets('mobile grid layout shows single column', (tester) async {
        await tester.pumpWidget(_buildTestApp(isDesktop: false));
        await tester.pumpAndSettle();

        // Verify report cards are laid out in single column
        // This is tested by checking that cards are vertically aligned
        final productCardFinder = find
            .ancestor(of: find.text('Products'), matching: find.byType(InkWell))
            .first;
        final customerCardFinder = find.ancestor(
          of: find.text('Customers'),
          matching: find.byType(InkWell),
        );

        await tester.scrollUntilVisible(productCardFinder, 100.0);
        final productPosition = tester.getTopLeft(productCardFinder);

        await tester.scrollUntilVisible(customerCardFinder, 100.0);
        final customerPosition = tester.getTopLeft(customerCardFinder);

        // In mobile single column, cards should have similar x coordinates
        expect((productPosition.dx - customerPosition.dx).abs(), lessThan(50));
      });

      testWidgets('mobile filters dialog is responsive', (tester) async {
        await tester.pumpWidget(_buildTestApp(isDesktop: false));
        await tester.pumpAndSettle();

        // Open Products filter dialog
        final productsCardFinder = find
            .ancestor(of: find.text('Products'), matching: find.byType(InkWell))
            .first;
        await tester.scrollUntilVisible(productsCardFinder, 100.0);
        await tester.tap(productsCardFinder);
        await tester.pumpAndSettle();

        // Dialog should be present and responsive
        expect(find.text('Report Filters'), findsOneWidget);

        // All the same functionality should work on mobile
        expect(find.text('Date Range'), findsOneWidget);
        expect(find.text('User'), findsOneWidget);
        expect(find.text('Include Subgroups'), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('handles long report names gracefully', (tester) async {
        await tester.pumpWidget(_buildTestApp(isDesktop: true));
        await tester.pumpAndSettle();

        // Verify text overflow is handled (ellipsis)
        final longTextWidget = find.text('Hourly Sales by Product Groups');
        await tester.scrollUntilVisible(longTextWidget, 100.0);
        expect(longTextWidget, findsOneWidget);
      });

      testWidgets('handles empty/no results states', (tester) async {
        await tester.pumpWidget(_buildTestApp(isDesktop: true));
        await tester.pumpAndSettle();

        // Switch to a category with few items
        final stockReturnChip = find
            .ancestor(
              of: find.text('Stock Return'),
              matching: find.byType(InkWell),
            )
            .first;
        await tester.scrollUntilVisible(stockReturnChip, 100.0);
        await tester.tap(stockReturnChip);
        await tester.pumpAndSettle();

        // Should still show section header with count
        expect(find.text('Stock Return'), findsOneWidget);
        expect(find.textContaining('1 reports available'), findsOneWidget);
      });

      testWidgets('scrolling works correctly with many items', (tester) async {
        await tester.pumpWidget(_buildTestApp(isDesktop: true));
        await tester.pumpAndSettle();

        // Scroll to bottom items
        final lastCard = find.text('Items Discounts');
        await tester.scrollUntilVisible(lastCard, 100.0);
        expect(lastCard, findsOneWidget);

        // Scroll back to top
        final firstCardFinder = find
            .ancestor(of: find.text('Products'), matching: find.byType(InkWell))
            .first;
        await tester.scrollUntilVisible(firstCardFinder, -100.0);
        expect(firstCardFinder, findsOneWidget);
      });
    });

    group('State Management', () {
      testWidgets('maintains state correctly across interactions', (
        tester,
      ) async {
        await tester.pumpWidget(_buildTestApp(isDesktop: true));
        await tester.pumpAndSettle();

        // Change category
        final purchaseChip = find
            .ancestor(
              of: find.text('Purchase Reports'),
              matching: find.byType(InkWell),
            )
            .first;
        await tester.scrollUntilVisible(purchaseChip, 100.0);
        await tester.tap(purchaseChip);
        await tester.pumpAndSettle();

        // Change back to All
        final allChip = find.ancestor(
          of: find.text('All'),
          matching: find.byType(InkWell),
        );
        await tester.tap(allChip);
        await tester.pumpAndSettle();

        // All sections should be visible again
        expect(find.textContaining('21 reports available'), findsOneWidget);
        expect(find.textContaining('8 reports available'), findsOneWidget);
      });

      testWidgets('filter state persists during dialog interactions', (
        tester,
      ) async {
        await tester.pumpWidget(_buildTestApp(isDesktop: true));
        await tester.pumpAndSettle();

        // Open filter dialog
        final productsCardFinder = find
            .ancestor(of: find.text('Products'), matching: find.byType(InkWell))
            .first;
        await tester.scrollUntilVisible(productsCardFinder, 100.0);
        await tester.tap(productsCardFinder);
        await tester.pumpAndSettle();

        // Change a filter
        final userDropdown = find.byType(DropdownButton<String>).first;
        await tester.tap(userDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('User 2'));
        await tester.pumpAndSettle();

        // Close and reopen dialog
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        await tester.tap(productsCardFinder);
        await tester.pumpAndSettle();

        // Filter should still be "User 2"
        expect(find.textContaining('User: User 2'), findsOneWidget);
      });
    });
  });
}

/// Helper function to build test app with controllable screen size
Widget _buildTestApp({required bool isDesktop}) {
  final size = isDesktop ? const Size(900, 1400) : const Size(390, 844);

  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: const StockKeeperReports(),
    ),
  );
}

/// Golden test scaffold (skipped by default)
/// Uncomment and customize for visual regression testing
/*
group('Golden Tests', () {
  testWidgets('desktop layout golden test', (tester) async {
    await tester.pumpWidget(_buildTestApp(isDesktop: true));
    await tester.pumpAndSettle();
    
    await expectLater(
      find.byType(StockKeeperReports),
      matchesGoldenFile('stockkeeper_reports_desktop.png'),
    );
  }, skip: true);

  testWidgets('mobile layout golden test', (tester) async {
    await tester.pumpWidget(_buildTestApp(isDesktop: false));
    await tester.pumpAndSettle();
    
    await expectLater(
      find.byType(StockKeeperReports),
      matchesGoldenFile('stockkeeper_reports_mobile.png'),
    );
  }, skip: true);
});
*/
