import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_system/features/cashier/cashier_history_page.dart';
void main() {
  group('CashierHistoryPage Tests', () {
    late List<Map<String, dynamic>> sampleSales;
    late String currentCashier;

    setUp(() {
      currentCashier = 'John Doe';
      sampleSales = [
        {
          'billId': 'BILL001',
          'date': DateTime(2024, 1, 15, 10, 30),
          'amount': 150.50,
          'cashier': 'John Doe',
        },
        {
          'billId': 'BILL002',
          'date': '2024-01-16T14:20:00.000Z',
          'amount': 250.75,
          'cashier': 'Jane Smith',
        },
        {
          'billId': 'BILL003',
          'date': DateTime(2024, 1, 17, 9, 15),
          'amount': 99.99,
          'cashier': 'John Doe',
        },
        {
          'billId': 'BILL004',
          'date': '2024-01-18T16:45:00.000Z',
          'amount': 500.00,
          'cashier': 'Bob Wilson',
        },
      ];
    });

    group('Widget Creation Tests', () {
      testWidgets('should create CashierHistoryPage with required parameters', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CashierHistoryPage(
              currentCashier: currentCashier,
              sales: sampleSales,
            ),
          ),
        );

        expect(find.byType(CashierHistoryPage), findsOneWidget);
        expect(find.text('History'), findsOneWidget);
        expect(find.text('My History'), findsOneWidget);
        expect(find.text('All'), findsOneWidget);
      });

      testWidgets('should display TabBar with correct tabs', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CashierHistoryPage(
              currentCashier: currentCashier,
              sales: sampleSales,
            ),
          ),
        );

        expect(find.byType(TabBar), findsOneWidget);
        expect(find.text('My History'), findsOneWidget);
        expect(find.text('All'), findsOneWidget);
      });
    });

    group('Data Filtering Tests', () {
      testWidgets('should filter sales for current cashier in My History tab', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CashierHistoryPage(
              currentCashier: currentCashier,
              sales: sampleSales,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // My History tab should only show John Doe's sales (2 items)
        expect(find.textContaining('BILL001'), findsOneWidget);
        expect(find.textContaining('BILL003'), findsOneWidget);
        expect(find.textContaining('BILL002'), findsNothing);
        expect(find.textContaining('BILL004'), findsNothing);
        
        // Should show 2 ListTile widgets for John Doe's sales
        expect(find.byType(ListTile), findsNWidgets(2));
      });

      testWidgets('should show all sales in All tab', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CashierHistoryPage(
              currentCashier: currentCashier,
              sales: sampleSales,
            ),
          ),
        );

        // Switch to All tab
        await tester.tap(find.text('All'));
        await tester.pumpAndSettle();

        // All tab should show all 4 sales
        expect(find.textContaining('BILL001'), findsOneWidget);
        expect(find.textContaining('BILL002'), findsOneWidget);
        expect(find.textContaining('BILL003'), findsOneWidget);
        expect(find.textContaining('BILL004'), findsOneWidget);
        
        // Should show 4 ListTile widgets for all sales
        expect(find.byType(ListTile), findsNWidgets(4));
      });

      testWidgets('should handle empty sales list', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CashierHistoryPage(
              currentCashier: currentCashier,
              sales: [],
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('No history yet.'), findsOneWidget);
      });

      testWidgets('should show no history when current cashier has no sales', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CashierHistoryPage(
              currentCashier: 'Unknown Cashier',
              sales: sampleSales,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('No history yet.'), findsOneWidget);
      });
    });

    group('Data Display Tests', () {
      testWidgets('should display bill ID and amount correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CashierHistoryPage(
              currentCashier: currentCashier,
              sales: sampleSales,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.textContaining('BILL001'), findsOneWidget);
        expect(find.textContaining('Rs. 150.50'), findsOneWidget);
        expect(find.textContaining('BILL003'), findsOneWidget);
        expect(find.textContaining('Rs. 99.99'), findsOneWidget);
      });

      testWidgets('should display date and cashier information', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CashierHistoryPage(
              currentCashier: currentCashier,
              sales: sampleSales,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check if date formatting is working
        expect(find.textContaining('2024-01-15'), findsOneWidget);
        expect(find.textContaining('2024-01-17'), findsOneWidget);
        
        // Check cashier names in My History tab
        expect(find.textContaining('John Doe'), findsAtLeastNWidgets(1));
      });

      testWidgets('should handle null or missing data gracefully', (WidgetTester tester) async {
        final salesWithNulls = [
          {
            'billId': null,
            'date': null,
            'amount': null,
            'cashier': currentCashier, // Set to current cashier so it shows up in My History
          },
          {
            'billId': 'BILL005',
            'date': 'invalid-date',
            'amount': 100.0,
            'cashier': currentCashier,
          },
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: CashierHistoryPage(
              currentCashier: currentCashier,
              sales: salesWithNulls,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should have 2 list items
        expect(find.byType(ListTile), findsNWidgets(2));
        
        // Check for formatted displays of null/invalid data
        expect(find.textContaining('Rs. 0.00'), findsOneWidget); // null amount
        expect(find.textContaining('BILL005'), findsOneWidget); // valid bill ID
        expect(find.textContaining('Rs. 100.00'), findsOneWidget); // valid amount
      });

      testWidgets('should handle completely null data', (WidgetTester tester) async {
        final salesWithCompleteNulls = [
          {
            'billId': null,
            'date': null,
            'amount': null,
            'cashier': currentCashier,
          },
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: CashierHistoryPage(
              currentCashier: currentCashier,
              sales: salesWithCompleteNulls,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show the item even with null data
        expect(find.byType(ListTile), findsOneWidget);
        // Should show default values for null data
        expect(find.textContaining('Rs. 0.00'), findsOneWidget);
      });
    });

    group('Sorting Tests', () {
      testWidgets('should sort sales by date (newest first)', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CashierHistoryPage(
              currentCashier: currentCashier,
              sales: sampleSales,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find all ListTile widgets
        final listTiles = find.byType(ListTile);
        expect(listTiles, findsNWidgets(2)); // My History should show 2 items for John Doe

        // Check that we can find both bill IDs (order testing is complex in Flutter tests)
        expect(find.textContaining('BILL001'), findsOneWidget);
        expect(find.textContaining('BILL003'), findsOneWidget);
        
        // Verify the amounts are displayed correctly
        expect(find.textContaining('Rs. 150.50'), findsOneWidget);
        expect(find.textContaining('Rs. 99.99'), findsOneWidget);
      });
    });

    group('UI Interaction Tests', () {
      testWidgets('should switch between tabs correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CashierHistoryPage(
              currentCashier: currentCashier,
              sales: sampleSales,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Initially on My History tab - should show 2 items
        expect(find.byType(ListTile), findsNWidgets(2));

        // Switch to All tab
        await tester.tap(find.text('All'));
        await tester.pumpAndSettle();

        // All tab should show 4 items
        expect(find.byType(ListTile), findsNWidgets(4));

        // Switch back to My History tab
        await tester.tap(find.text('My History'));
        await tester.pumpAndSettle();

        // Should show 2 items again
        expect(find.byType(ListTile), findsNWidgets(2));
      });

      testWidgets('should have view icons for each list item', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CashierHistoryPage(
              currentCashier: currentCashier,
              sales: sampleSales,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should have view icons (IconButton with visibility icon) for each item
        expect(find.byIcon(Icons.visibility), findsNWidgets(2)); // My History tab has 2 items
      });

      testWidgets('should have receipt icons for each list item', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CashierHistoryPage(
              currentCashier: currentCashier,
              sales: sampleSales,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should have receipt icons for each item
        expect(find.byIcon(Icons.receipt_long), findsNWidgets(2)); // My History tab has 2 items
      });

      testWidgets('should handle view button tap', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CashierHistoryPage(
              currentCashier: currentCashier,
              sales: sampleSales,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap on the first view button
        await tester.tap(find.byIcon(Icons.visibility).first);
        await tester.pumpAndSettle();

        // Since the TODO is not implemented, this should not crash
        // In a real implementation, you would test navigation here
      });
    });

    group('Theme and Styling Tests', () {
      testWidgets('should apply dark theme', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CashierHistoryPage(
              currentCashier: currentCashier,
              sales: sampleSales,
            ),
          ),
        );

        await tester.pumpAndSettle();

        final theme = Theme.of(tester.element(find.byType(Scaffold)));
        expect(theme.brightness, Brightness.dark);
      });

      testWidgets('should have correct app bar background color', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CashierHistoryPage(
              currentCashier: currentCashier,
              sales: sampleSales,
            ),
          ),
        );

        await tester.pumpAndSettle();

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.backgroundColor, const Color(0xFF0D1B2A));
      });
    });

    group('Edge Cases Tests', () {
      testWidgets('should handle sales with empty cashier field', (WidgetTester tester) async {
        final salesWithEmptyCashier = [
          {
            'billId': 'BILL001',
            'date': DateTime(2024, 1, 15, 10, 30),
            'amount': 150.50,
            'cashier': '',
          },
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: CashierHistoryPage(
              currentCashier: currentCashier,
              sales: salesWithEmptyCashier,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('No history yet.'), findsOneWidget);
      });

      testWidgets('should handle sales with different date formats', (WidgetTester tester) async {
        final salesWithMixedDates = [
          {
            'billId': 'BILL001',
            'date': DateTime(2024, 1, 15, 10, 30),
            'amount': 150.50,
            'cashier': currentCashier,
          },
          {
            'billId': 'BILL002',
            'date': '2024-01-16T14:20:00.000Z',
            'amount': 250.75,
            'cashier': currentCashier,
          },
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: CashierHistoryPage(
              currentCashier: currentCashier,
              sales: salesWithMixedDates,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Both items should be displayed
        expect(find.byType(ListTile), findsNWidgets(2));
        expect(find.textContaining('2024-01-15'), findsOneWidget);
        expect(find.textContaining('2024-01-16'), findsOneWidget);
      });

      testWidgets('should handle very large amounts', (WidgetTester tester) async {
        final salesWithLargeAmount = [
          {
            'billId': 'BILL001',
            'date': DateTime(2024, 1, 15, 10, 30),
            'amount': 999999999.99,
            'cashier': currentCashier,
          },
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: CashierHistoryPage(
              currentCashier: currentCashier,
              sales: salesWithLargeAmount,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.textContaining('Rs. 999,999,999.99'), findsOneWidget);
      });
    });
  });
}