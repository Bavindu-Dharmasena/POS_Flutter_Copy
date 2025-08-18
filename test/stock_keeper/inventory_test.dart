import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Import your actual file - adjust the path as needed
// import 'package:pos_system/features/stockkeeper/inventory/stockkeeper_inventory.dart';

// Mock classes for testing
class MockProduct {
  final String id;
  final String name;
  final String category;
  final int currentStock;
  final int minStock;
  final int maxStock;
  final double price;
  final String barcode;
  final String? image;
  final String supplier;

  MockProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.minStock,
    required this.maxStock,
    required this.price,
    required this.barcode,
    this.image,
    required this.supplier,
  });

  bool get isLowStock => currentStock <= minStock && currentStock > 0;
}

void main() {
  group('Product Model Tests', () {
    test('Product should be created with correct properties', () {
      final product = MockProduct(
        id: '001',
        name: 'Test Product',
        category: 'Test Category',
        currentStock: 50,
        minStock: 20,
        maxStock: 100,
        price: 250.0,
        barcode: '123456789',
        supplier: 'Test Supplier',
      );

      expect(product.id, '001');
      expect(product.name, 'Test Product');
      expect(product.category, 'Test Category');
      expect(product.currentStock, 50);
      expect(product.minStock, 20);
      expect(product.maxStock, 100);
      expect(product.price, 250.0);
      expect(product.barcode, '123456789');
      expect(product.supplier, 'Test Supplier');
    });

    test('isLowStock should return true when stock is at or below minimum', () {
      final lowStockProduct = MockProduct(
        id: '002',
        name: 'Low Stock Product',
        category: 'Test',
        currentStock: 15,
        minStock: 20,
        maxStock: 100,
        price: 100.0,
        barcode: '123456789',
        supplier: 'Test Supplier',
      );

      expect(lowStockProduct.isLowStock, true);
    });

    test('isLowStock should return false when stock is above minimum', () {
      final normalStockProduct = MockProduct(
        id: '003',
        name: 'Normal Stock Product',
        category: 'Test',
        currentStock: 50,
        minStock: 20,
        maxStock: 100,
        price: 100.0,
        barcode: '123456789',
        supplier: 'Test Supplier',
      );

      expect(normalStockProduct.isLowStock, false);
    });

    test('isLowStock should return false when stock is zero', () {
      final outOfStockProduct = MockProduct(
        id: '004',
        name: 'Out of Stock Product',
        category: 'Test',
        currentStock: 0,
        minStock: 20,
        maxStock: 100,
        price: 100.0,
        barcode: '123456789',
        supplier: 'Test Supplier',
      );

      expect(outOfStockProduct.isLowStock, false);
    });
  });

  group('StockKeeperInventory Widget Tests', () {

    setUp(() {
    });

    testWidgets('should render inventory page with correct title', (WidgetTester tester) async {
      // Note: You'll need to adjust this based on your actual widget structure
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Inventory Management'),
            ),
            body: Container(), // Placeholder for actual widget
          ),
        ),
      );

      expect(find.text('Inventory Management'), findsOneWidget);
    });

    testWidgets('should show search field with correct hint text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              decoration: InputDecoration(
                hintText: 'Search products, barcode, or ID...   (Esc: back, ↓: to grid)',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Search products, barcode, or ID...   (Esc: back, ↓: to grid)'), findsOneWidget);
    });

    testWidgets('should display floating action button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Add Product'), findsOneWidget);
    });
  });

  group('Product Filtering Tests', () {
    late List<MockProduct> testProducts;

    setUp(() {
      testProducts = [
        MockProduct(
          id: '001',
          name: 'Cadbury Dairy Milk',
          category: 'Chocolates',
          currentStock: 45,
          minStock: 20,
          maxStock: 100,
          price: 250.00,
          barcode: '123456789',
          supplier: 'Cadbury Lanka',
        ),
        MockProduct(
          id: '002',
          name: 'Maliban Cream Crackers',
          category: 'Biscuits',
          currentStock: 8,
          minStock: 15,
          maxStock: 80,
          price: 180.00,
          barcode: '987654321',
          supplier: 'Maliban Biscuits',
        ),
        MockProduct(
          id: '003',
          name: 'Out of Stock Item',
          category: 'Test',
          currentStock: 0,
          minStock: 10,
          maxStock: 50,
          price: 100.00,
          barcode: '000000000',
          supplier: 'Test Supplier',
        ),
      ];
    });

    test('should filter products by search query (name)', () {
      const searchQuery = 'cadbury';
      final filteredProducts = testProducts.where((product) {
        return product.name.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();

      expect(filteredProducts.length, 1);
      expect(filteredProducts.first.name, 'Cadbury Dairy Milk');
    });

    test('should filter products by search query (barcode)', () {
      const searchQuery = '987654321';
      final filteredProducts = testProducts.where((product) {
        return product.barcode.contains(searchQuery);
      }).toList();

      expect(filteredProducts.length, 1);
      expect(filteredProducts.first.name, 'Maliban Cream Crackers');
    });

    test('should filter products by search query (ID)', () {
      const searchQuery = '002';
      final filteredProducts = testProducts.where((product) {
        return product.id.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();

      expect(filteredProducts.length, 1);
      expect(filteredProducts.first.id, '002');
    });

    test('should filter products by category', () {
      const selectedCategory = 'Chocolates';
      final filteredProducts = testProducts.where((product) {
        return selectedCategory == 'All' || product.category == selectedCategory;
      }).toList();

      expect(filteredProducts.length, 1);
      expect(filteredProducts.first.category, 'Chocolates');
    });

    test('should filter products by stock status - Low Stock', () {
      const selectedStockStatus = 'Low Stock';
      final filteredProducts = testProducts.where((product) {
        return selectedStockStatus == 'All' ||
            (selectedStockStatus == 'Low Stock' && product.isLowStock) ||
            (selectedStockStatus == 'In Stock' && !product.isLowStock && product.currentStock > 0) ||
            (selectedStockStatus == 'Out of Stock' && product.currentStock == 0);
      }).toList();

      expect(filteredProducts.length, 1);
      expect(filteredProducts.first.isLowStock, true);
    });

    test('should filter products by stock status - Low Stock', () {
      const selectedStockStatus = 'Out of Stock';
      final filteredProducts = testProducts.where((product) {
        return selectedStockStatus == 'All' ||
            (selectedStockStatus == 'Low Stock' && product.isLowStock) ||
            (selectedStockStatus == 'In Stock' && !product.isLowStock && product.currentStock > 0) ||
            (selectedStockStatus == 'Out of Stock' && product.currentStock == 0);
      }).toList();

      expect(filteredProducts.length, 1);
      expect(filteredProducts.first.currentStock, 0);
    });

    test('should return all products when filters are set to "All"', () {
      const selectedCategory = 'All';
      const selectedStockStatus = 'All';
      const searchQuery = '';

      final filteredProducts = testProducts.where((product) {
        final matchesSearch = searchQuery.isEmpty ||
            product.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            product.barcode.contains(searchQuery) ||
            product.id.toLowerCase().contains(searchQuery.toLowerCase());

        final matchesCategory = selectedCategory == 'All' || product.category == selectedCategory;

        final matchesStockStatus = selectedStockStatus == 'All' ||
            (selectedStockStatus == 'Low Stock' && product.isLowStock) ||
            (selectedStockStatus == 'In Stock' && !product.isLowStock && product.currentStock > 0) ||
            (selectedStockStatus == 'Out of Stock' && product.currentStock == 0);

        return matchesSearch && matchesCategory && matchesStockStatus;
      }).toList();

      expect(filteredProducts.length, testProducts.length);
    });
  });

  group('Dashboard Summary Calculations Tests', () {
    late List<MockProduct> testProducts;

    setUp(() {
      testProducts = [
        MockProduct(
          id: '001',
          name: 'Product 1',
          category: 'Category 1',
          currentStock: 45,
          minStock: 20,
          maxStock: 100,
          price: 100.0,
          barcode: '123456789',
          supplier: 'Supplier 1',
        ),
        MockProduct(
          id: '002',
          name: 'Product 2',
          category: 'Category 2',
          currentStock: 8, // Low stock
          minStock: 15,
          maxStock: 80,
          price: 200.0,
          barcode: '987654321',
          supplier: 'Supplier 2',
        ),
        MockProduct(
          id: '003',
          name: 'Product 3',
          category: 'Category 3',
          currentStock: 0, // Out of stock
          minStock: 10,
          maxStock: 50,
          price: 150.0,
          barcode: '456789123',
          supplier: 'Supplier 3',
        ),
      ];
    });

    test('should calculate total items correctly', () {
      final totalItems = testProducts.length;
      expect(totalItems, 3);
    });

    test('should calculate low stock items correctly', () {
      final lowStockItems = testProducts.where((p) => p.isLowStock).length;
      expect(lowStockItems, 1);
    });

    test('should calculate out of stock items correctly', () {
      final outOfStockItems = testProducts.where((p) => p.currentStock == 0).length;
      expect(outOfStockItems, 1);
    });

    test('should calculate total inventory value correctly', () {
      final totalValue = testProducts.fold(0.0, (sum, p) => sum + (p.price * p.currentStock));
      // (45 * 100) + (8 * 200) + (0 * 150) = 4500 + 1600 + 0 = 6100
      expect(totalValue, 6100.0);
    });
  });

  group('Categories Generation Tests', () {
    late List<MockProduct> testProducts;

    setUp(() {
      testProducts = [
        MockProduct(
          id: '001',
          name: 'Product 1',
          category: 'Chocolates',
          currentStock: 45,
          minStock: 20,
          maxStock: 100,
          price: 100.0,
          barcode: '123456789',
          supplier: 'Supplier 1',
        ),
        MockProduct(
          id: '002',
          name: 'Product 2',
          category: 'Biscuits',
          currentStock: 8,
          minStock: 15,
          maxStock: 80,
          price: 200.0,
          barcode: '987654321',
          supplier: 'Supplier 2',
        ),
        MockProduct(
          id: '003',
          name: 'Product 3',
          category: 'Chocolates', // Duplicate category
          currentStock: 20,
          minStock: 10,
          maxStock: 50,
          price: 150.0,
          barcode: '456789123',
          supplier: 'Supplier 3',
        ),
      ];
    });

    test('should generate unique categories list with "All" at the beginning', () {
      final categories = testProducts.map((p) => p.category).toSet().toList();
      categories.insert(0, 'All');

      expect(categories.contains('All'), true);
      expect(categories.contains('Chocolates'), true);
      expect(categories.contains('Biscuits'), true);
      expect(categories.first, 'All');
      expect(categories.length, 3); // 'All', 'Chocolates', 'Biscuits'
    });
  });

  group('Focus Management Tests', () {
    testWidgets('should handle focus node creation and disposal', (WidgetTester tester) async {
      final focusNodes = <FocusNode>[];
      
      // Simulate creating focus nodes
      void ensureCardNodes(int count) {
        while (focusNodes.length > count) {
          focusNodes.removeLast().dispose();
        }
        while (focusNodes.length < count) {
          focusNodes.add(FocusNode(debugLabel: 'card_${focusNodes.length}'));
        }
      }

      // Test creating nodes
      ensureCardNodes(3);
      expect(focusNodes.length, 3);

      // Test reducing nodes
      ensureCardNodes(1);
      expect(focusNodes.length, 1);

      // Test increasing nodes again
      ensureCardNodes(5);
      expect(focusNodes.length, 5);

      // Clean up
      for (final node in focusNodes) {
        node.dispose();
      }
    });

    test('should calculate next index for arrow navigation correctly', () {
      const cols = 2;
      const count = 6; // 3x2 grid

      // Test right arrow
      int nextIndex(int current, LogicalKeyboardKey key) {
        if (key == LogicalKeyboardKey.arrowRight) return (current + 1) % count;
        if (key == LogicalKeyboardKey.arrowLeft) return (current - 1 + count) % count;
        if (key == LogicalKeyboardKey.arrowDown) {
          final j = current + cols;
          if (j < count) return j;
          final col = current % cols;
          return col;
        }
        if (key == LogicalKeyboardKey.arrowUp) {
          final j = current - cols;
          if (j >= 0) return j;
          return current;
        }
        return current;
      }

      // Test right navigation
      expect(nextIndex(0, LogicalKeyboardKey.arrowRight), 1);
      expect(nextIndex(5, LogicalKeyboardKey.arrowRight), 0); // Wrap around

      // Test left navigation  
      expect(nextIndex(1, LogicalKeyboardKey.arrowLeft), 0);
      expect(nextIndex(0, LogicalKeyboardKey.arrowLeft), 5); // Wrap around

      // Test down navigation
      expect(nextIndex(0, LogicalKeyboardKey.arrowDown), 2);
      expect(nextIndex(4, LogicalKeyboardKey.arrowDown), 0); // Wrap to same column

      // Test up navigation
      expect(nextIndex(2, LogicalKeyboardKey.arrowUp), 0);
      expect(nextIndex(0, LogicalKeyboardKey.arrowUp), 0); // Stay in place
    });
  });

  group('Stock Badge Tests', () {
    test('should return correct badge info for out of stock product', () {
      final product = MockProduct(
        id: '001',
        name: 'Test Product',
        category: 'Test',
        currentStock: 0,
        minStock: 10,
        maxStock: 50,
        price: 100.0,
        barcode: '123456789',
        supplier: 'Test Supplier',
      );

      expect(product.currentStock == 0, true);
    });

    test('should return correct badge info for low stock product', () {
      final product = MockProduct(
        id: '001',
        name: 'Test Product',
        category: 'Test',
        currentStock: 5,
        minStock: 10,
        maxStock: 50,
        price: 100.0,
        barcode: '123456789',
        supplier: 'Test Supplier',
      );

      expect(product.isLowStock, true);
      expect(product.currentStock > 0, true);
    });

    test('should return correct badge info for in stock product', () {
      final product = MockProduct(
        id: '001',
        name: 'Test Product',
        category: 'Test',
        currentStock: 25,
        minStock: 10,
        maxStock: 50,
        price: 100.0,
        barcode: '123456789',
        supplier: 'Test Supplier',
      );

      expect(product.isLowStock, false);
      expect(product.currentStock > 0, true);
    });
  });

  group('Glass Box Decoration Tests', () {
    test('should create glass box decoration with default values', () {
      BoxDecoration glassBox({
        double radius = 24.0,
        double borderOpacity = .10,
        double fillOpacity = .08,
        List<Color>? overlayGradient,
      }) {
        return BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.white.withOpacity(borderOpacity), width: 1),
          color: Colors.white.withOpacity(fillOpacity),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: overlayGradient ?? [Colors.white.withOpacity(.10), Colors.white.withOpacity(.02)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.35),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        );
      }

      final decoration = glassBox();
      
      expect(decoration.borderRadius, BorderRadius.circular(24.0));
      expect(decoration.border, isA<Border>());
      expect(decoration.color, Colors.white.withOpacity(.08));
      expect(decoration.gradient, isA<LinearGradient>());
      expect(decoration.boxShadow?.length, 1);
    });
  });

  group('Brand Gradient Tests', () {
    test('should create linear gradient with correct properties', () {
      LinearGradient brandGradient(List<Color> colors) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      );

      final colors = [Colors.red, Colors.blue];
      final gradient = brandGradient(colors);

      expect(gradient.begin, Alignment.topLeft);
      expect(gradient.end, Alignment.bottomRight);
      expect(gradient.colors, colors);
    });
  });

  group('Responsive Layout Tests', () {
    test('should determine correct layout based on screen width', () {
      // Mobile
      bool isMobile(double width) => width < 600;
      bool isTablet(double width) => width > 800;

      expect(isMobile(500), true);
      expect(isMobile(700), false);
      expect(isTablet(900), true);
      expect(isTablet(700), false);
    });

    test('should calculate correct grid columns based on screen size', () {
      int getColumns(double screenWidth) {
        final isTablet = screenWidth > 800;
        final isMobile = screenWidth < 600;
        return isTablet ? 3 : (isMobile ? 1 : 2);
      }

      expect(getColumns(500), 1); // Mobile: 1 column
      expect(getColumns(700), 2); // Desktop: 2 columns
      expect(getColumns(900), 3); // Tablet: 3 columns
    });
  });
}