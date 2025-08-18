import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:pos_system/features/stockkeeper/products/add_item_page.dart';
import 'package:pos_system/features/stockkeeper/stockkeeper_inventory.dart';
import 'package:pos_system/widget/stock_keeper_inventory/dashboard_summary_grid.dart';
import 'package:pos_system/widget/stock_keeper_inventory/search_and_filter_section.dart';

void main() {
  group('StockKeeperInventory', () {
    testWidgets('renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: StockKeeperInventory()));

      expect(find.text('Inventory Management'), findsOneWidget);
      expect(find.byType(DashboardSummaryGrid), findsOneWidget);
      expect(find.byType(SearchAndFilterSection), findsOneWidget);
    });

    testWidgets('displays products in grid', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: StockKeeperInventory()));

      await tester.pump();

      expect(find.text('Cadbury Dairy Milk'), findsOneWidget);
      expect(find.text('Maliban Cream Crackers'), findsOneWidget);
    });

    testWidgets('filters products by search', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: StockKeeperInventory()));

      await tester.enterText(find.byType(TextField), 'Cadbury');
      await tester.pump();

      expect(find.text('Cadbury Dairy Milk'), findsOneWidget);
      expect(find.text('Maliban Cream Crackers'), findsNothing);
    });

    testWidgets('shows add product dialog when FAB is pressed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: StockKeeperInventory()));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(AddItemPage), findsOneWidget);
    });

    testWidgets('shows export dialog when export button is pressed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: StockKeeperInventory()));

      await tester.tap(find.byIcon(Feather.download));
      await tester.pumpAndSettle();

      expect(find.text('Export Inventory'), findsOneWidget);
      expect(find.text('Export CSV'), findsOneWidget);
    });

    testWidgets('shows no products message when filtered list is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: StockKeeperInventory()));

      await tester.enterText(find.byType(TextField), 'Non-existent product');
      await tester.pump();

      expect(find.text('No products found'), findsOneWidget);

      // Check for the search icon specifically within the "No products found" section using the Key
      expect(find.byKey(Key('no-products-search-icon')), findsOneWidget);
    });
  });
}
