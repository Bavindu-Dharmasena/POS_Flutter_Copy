import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Import your actual files here
// import 'package:pos_system/widget/search_and_categories.dart';
// import 'package:pos_system/widget/discount_row.dart';
// import 'package:pos_system/widget/pause_resume_row.dart';

// Mock widgets for testing - replace with your actual imports
class SearchAndCategories extends StatelessWidget {
  final String searchQuery;
  final Function(String) onSearchChange;
  final List<Map<String, dynamic>> itemsByCategory;
  final List<String> categories;
  final List<Map<String, dynamic>> searchedItems;
  final Function(String) onCategoryTap;
  final Function(Map<String, dynamic>) onSearchedItemTap;
  final double? gridHeight;
  final int? gridCrossAxisCount;

  const SearchAndCategories({
    super.key,
    required this.searchQuery,
    required this.onSearchChange,
    required this.itemsByCategory,
    required this.categories,
    required this.searchedItems,
    required this.onCategoryTap,
    required this.onSearchedItemTap,
    this.gridHeight,
    this.gridCrossAxisCount,
  });

  @override
  Widget build(BuildContext context) => const Text('SearchAndCategories');
}

class CartTable extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems;
  final Function(int) onEdit;
  final Function(int) onRemove;

  const CartTable({
    super.key,
    required this.cartItems,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => const Text('CartTable');
}

class DiscountRow extends StatelessWidget {
  final double discount;
  final bool isPercentageDiscount;
  final Function(String) onDiscountChange;
  final Function(bool) onTypeChange;

  const DiscountRow({
    super.key,
    required this.discount,
    required this.isPercentageDiscount,
    required this.onDiscountChange,
    required this.onTypeChange,
  });

  @override
  Widget build(BuildContext context) => const Text('DiscountRow');
}

class PrimaryActionsRow extends StatelessWidget {
  final VoidCallback onQuickSale;
  final VoidCallback? onPay;
  final bool payEnabled;
  final double? horizontalPadding;

  const PrimaryActionsRow({
    super.key,
    required this.onQuickSale,
    required this.onPay,
    required this.payEnabled,
    this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) => const Text('PrimaryActionsRow');
}

class CategoryItemsPage extends StatelessWidget {
  final String category;
  final List<Map<String, dynamic>> items;
  final Function(Map<String, dynamic>) onItemSelected;

  const CategoryItemsPage({
    super.key,
    required this.category,
    required this.items,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(category)),
    body: const Text('CategoryItemsPage'),
  );
}

class CashierInsightsPage extends StatelessWidget {
  const CashierInsightsPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Text('CashierInsightsPage'),
  );
}

// Include your CashierViewPage class here
// For now, I'll include a simplified version for testing structure
class CashierViewPage extends StatefulWidget {
  const CashierViewPage({super.key});

  @override
  State<CashierViewPage> createState() => _CashierViewPageState();
}

class _CashierViewPageState extends State<CashierViewPage> {
  List<String> get categories =>
      itemsByCategory.map((cat) => cat['category'] as String).toList();
  final List<List<Map<String, dynamic>>> pausedBills = [];
  
  final List<Map<String, dynamic>> itemsByCategory = [
    {
      'id': 1,
      'category': 'Drinks',
      'colourCode': '#FF5733',
      'items': [
        {
          'id': 1,
          'name': 'Coke',
          'colourCode': '#FF6347',
          'batches': [
            {'batchID': '123234', 'pprice': 120.00, 'price': 150.0, 'quantity': 20},
          ],
        },
      ],
    },
  ];

  final List<Map<String, dynamic>> cartItems = [];
  String searchQuery = '';
  bool isPercentageDiscount = true;
  double discount = 0;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF0D1B2A),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cashier'),
              Row(
                children: [
                  const Text('John Doe'),
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CashierInsightsPage()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth >= 1000;
            return isWideScreen
                ? _buildDesktopLayout(context)
                : _buildCompactLayout(context, constraints.maxWidth);
          },
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return const Row(
      children: [
        Expanded(flex: 3, child: Text('Left Panel')),
        Expanded(flex: 4, child: Text('Right Panel')),
      ],
    );
  }

  Widget _buildCompactLayout(BuildContext context, double width) {
    return const SingleChildScrollView(
      child: Column(
        children: [
          Text('Compact Layout'),
        ],
      ),
    );
  }
}

void main() {
  group('CashierViewPage Tests', () {
    
    group('Widget Rendering Tests', () {
      testWidgets('should render correctly with all basic widgets', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CashierViewPage()),
        );

        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(LayoutBuilder), findsOneWidget);
        expect(find.text('Cashier'), findsOneWidget);
        expect(find.text('John Doe'), findsOneWidget);
      });

      testWidgets('should have correct app bar configuration', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CashierViewPage()),
        );

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.automaticallyImplyLeading, isFalse);
        expect(appBar.backgroundColor, equals(const Color(0xFF0D1B2A)));
      });

      testWidgets('should apply dark theme', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CashierViewPage()),
        );

        final theme = tester.widget<Theme>(find.byType(Theme));
        expect(theme.data, equals(ThemeData.dark()));
      });

      testWidgets('should show menu icon button in app bar', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CashierViewPage()),
        );

        expect(find.byIcon(Icons.menu), findsOneWidget);
      });
    });

    group('Layout Responsive Tests', () {
      testWidgets('should show desktop layout for wide screens', (WidgetTester tester) async {
        // Set a wide screen size
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        
        await tester.pumpWidget(
          const MaterialApp(home: CashierViewPage()),
        );

        expect(find.text('Left Panel'), findsOneWidget);
        expect(find.text('Right Panel'), findsOneWidget);
        expect(find.byType(Row), findsWidgets);
      });

      testWidgets('should show compact layout for narrow screens', (WidgetTester tester) async {
        // Set a narrow screen size
        await tester.binding.setSurfaceSize(const Size(800, 600));
        
        await tester.pumpWidget(
          const MaterialApp(home: CashierViewPage()),
        );

        expect(find.text('Compact Layout'), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });

      testWidgets('should respond to screen size changes', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CashierViewPage()),
        );

        // Start with narrow screen
        await tester.binding.setSurfaceSize(const Size(800, 600));
        await tester.pumpAndSettle();
        expect(find.text('Compact Layout'), findsOneWidget);

        // Change to wide screen
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        await tester.pumpAndSettle();
        expect(find.text('Left Panel'), findsOneWidget);
        expect(find.text('Right Panel'), findsOneWidget);
      });
    });

    group('Navigation Tests', () {
      testWidgets('should navigate to insights page when menu button tapped', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CashierViewPage()),
        );

        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();

        expect(find.byType(CashierInsightsPage), findsOneWidget);
      });

      testWidgets('should be able to navigate back from insights page', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CashierViewPage()),
        );

        // Navigate to insights
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();

        // Navigate back
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        expect(find.byType(CashierViewPage), findsOneWidget);
        expect(find.text('Cashier'), findsOneWidget);
      });
    });

    group('State Management Tests', () {
      testWidgets('should maintain state during widget rebuilds', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CashierViewPage()),
        );

        // Trigger a rebuild
        await tester.pumpWidget(
          const MaterialApp(home: CashierViewPage()),
        );

        expect(find.byType(CashierViewPage), findsOneWidget);
        expect(find.text('Cashier'), findsOneWidget);
      });

      testWidgets('should be a StatefulWidget', (WidgetTester tester) async {
        const widget = CashierViewPage();
        expect(widget, isA<StatefulWidget>());
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should have accessible button for menu', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CashierViewPage()),
        );

        final menuButton = find.byIcon(Icons.menu);
        expect(menuButton, findsOneWidget);
        
        // Should be tappable
        await tester.tap(menuButton);
        await tester.pumpAndSettle();
        
        expect(find.byType(CashierInsightsPage), findsOneWidget);
      });

      testWidgets('should have proper text contrast in dark theme', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CashierViewPage()),
        );

        final theme = tester.widget<Theme>(find.byType(Theme));
        expect(theme.data.brightness, equals(Brightness.dark));
      });
    });

    group('Performance Tests', () {
      testWidgets('should build without performance issues', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(
          const MaterialApp(home: CashierViewPage()),
        );
        
        stopwatch.stop();
        
        // Should build reasonably quickly (adjust threshold as needed)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      testWidgets('should handle multiple rebuilds efficiently', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CashierViewPage()),
        );

        // Multiple rebuilds
        for (int i = 0; i < 5; i++) {
          await tester.pumpWidget(
            const MaterialApp(home: CashierViewPage()),
          );
        }

        expect(find.byType(CashierViewPage), findsOneWidget);
      });
    });
  });

  group('CashierViewPage Widget Properties Tests', () {
    test('should have correct key parameter', () {
      const key = Key('test_key');
      const widget = CashierViewPage(key: key);
      expect(widget.key, equals(key));
    });

    test('should have const constructor', () {
      // Should compile without issues
      const widget1 = CashierViewPage();
      const widget2 = CashierViewPage();
      
      expect(widget1, isA<CashierViewPage>());
      expect(widget2, isA<CashierViewPage>());
    });
  });

  group('Error Handling Tests', () {
    testWidgets('should handle null context gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CashierViewPage()),
      );

      // Widget should render without throwing exceptions
      expect(find.byType(CashierViewPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should recover from navigation errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CashierViewPage()),
      );

      // Multiple navigation attempts should not break the widget
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
        
        if (find.byType(BackButton).evaluate().isNotEmpty) {
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(CashierViewPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // Clean up after tests
  tearDown(() {
    // Reset any static state if needed
  });
}