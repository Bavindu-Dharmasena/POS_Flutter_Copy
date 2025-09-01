import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

// Import your actual file - adjust path as needed
import 'package:pos_system/features/stockkeeper/stockkeeper_inventory.dart';

void main() {
  group('Product Model Tests', () {
    test('should create Product with all required fields', () {
      const product = Product(
        id: '001',
        name: 'Test Product',
        category: 'Test Category',
        currentStock: 50,
        minStock: 20,
        maxStock: 100,
        price: 250.00,
        barcode: '123456789',
        supplier: 'Test Supplier',
      );

      expect(product.id, '001');
      expect(product.name, 'Test Product');
      expect(product.category, 'Test Category');
      expect(product.currentStock, 50);
      expect(product.minStock, 20);
      expect(product.maxStock, 100);
      expect(product.price, 250.00);
      expect(product.barcode, '123456789');
      expect(product.supplier, 'Test Supplier');
      expect(product.image, null);
    });

    test('should correctly identify low stock products', () {
      const lowStockProduct = Product(
        id: '001',
        name: 'Low Stock Item',
        category: 'Test',
        currentStock: 15, // Less than minStock (20)
        minStock: 20,
        maxStock: 100,
        price: 100.00,
        barcode: '123456789',
        supplier: 'Test Supplier',
      );

      expect(lowStockProduct.isLowStock, true);
      expect(lowStockProduct.isOutOfStock, false);
    });

    test('should correctly identify out of stock products', () {
      const outOfStockProduct = Product(
        id: '002',
        name: 'Out of Stock Item',
        category: 'Test',
        currentStock: 0,
        minStock: 20,
        maxStock: 100,
        price: 100.00,
        barcode: '123456789',
        supplier: 'Test Supplier',
      );

      expect(outOfStockProduct.isOutOfStock, true);
      expect(outOfStockProduct.isLowStock, false);
    });

    test('should correctly identify normal stock products', () {
      const normalStockProduct = Product(
        id: '003',
        name: 'Normal Stock Item',
        category: 'Test',
        currentStock: 50, // Above minStock (20)
        minStock: 20,
        maxStock: 100,
        price: 100.00,
        barcode: '123456789',
        supplier: 'Test Supplier',
      );

      expect(normalStockProduct.isLowStock, false);
      expect(normalStockProduct.isOutOfStock, false);
    });

    test('should handle edge case when currentStock equals minStock', () {
      const edgeStockProduct = Product(
        id: '004',
        name: 'Edge Case Item',
        category: 'Test',
        currentStock: 20, // Equal to minStock
        minStock: 20,
        maxStock: 100,
        price: 100.00,
        barcode: '123456789',
        supplier: 'Test Supplier',
      );

      expect(edgeStockProduct.isLowStock, true);
      expect(edgeStockProduct.isOutOfStock, false);
    });
  });

  group('Helper Function Tests', () {
    testWidgets('themedHeaderGradient should return correct gradient', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final colorScheme = Theme.of(context).colorScheme;
              final gradient = themedHeaderGradient(colorScheme);
              
              expect(gradient.colors.length, 2);
              expect(gradient.colors[0], colorScheme.primary);
              expect(gradient.colors[1], colorScheme.tertiary);
              expect(gradient.begin, Alignment.topLeft);
              expect(gradient.end, Alignment.bottomRight);
              
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('themedBackgroundSheen should return correct gradient', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final colorScheme = Theme.of(context).colorScheme;
              final gradient = themedBackgroundSheen(colorScheme);
              
              expect(gradient.colors.length, 3);
              expect(gradient.colors[0], colorScheme.surface);
              expect(gradient.colors[2], colorScheme.background);
              expect(gradient.begin, Alignment.topLeft);
              expect(gradient.end, Alignment.bottomRight);
              
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('InventoryStatsOnly Widget Tests', () {
    testWidgets('should display correct app bar title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InventoryStatsOnly(),
        ),
      );

      expect(find.text('Inventory Management'), findsOneWidget);
    });

    testWidgets('should display app bar action icons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InventoryStatsOnly(),
        ),
      );

      expect(find.byIcon(Feather.search), findsOneWidget);
      expect(find.byIcon(Feather.download), findsOneWidget);
    });

    testWidgets('should display all stat tiles', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InventoryStatsOnly(),
        ),
      );

      expect(find.text('Total Items'), findsOneWidget);
      expect(find.text('Low Stock'), findsOneWidget);
      expect(find.text('Re-Stock'), findsOneWidget);
    });

    testWidgets('should display correct total items count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InventoryStatsOnly(),
        ),
      );

      // Based on dummy data in the code (4 products)
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('should display correct low stock count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InventoryStatsOnly(),
        ),
      );

      // Based on dummy data (3 low stock items)
      expect(find.text('3'), findsNWidgets(2)); // Appears twice (Low Stock + Re-Stock tiles)
    });

    testWidgets('should show mobile banner for out of stock items on mobile', (tester) async {
      // Set mobile screen size
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: InventoryStatsOnly(),
        ),
      );

      // Trigger the post-frame callback
      await tester.pumpAndSettle();

      expect(find.text('Out of stock: 1 item(s) need immediate attention.'), findsOneWidget);
      expect(find.text('DISMISS'), findsOneWidget);
      expect(find.text('VIEW'), findsOneWidget);

      // Reset window size
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
    });

    testWidgets('should show desktop out of stock pill on desktop', (tester) async {
      // Set desktop screen size
      tester.binding.window.physicalSizeTestValue = const Size(1200, 800);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: InventoryStatsOnly(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Out of Stock: 1'), findsOneWidget);

      // Reset window size
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
    });
  });

  group('Keyboard Navigation Tests', () {
    testWidgets('should handle escape key navigation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InventoryStatsOnly()),
                ),
                child: const Text('Navigate'),
              ),
            ),
          ),
        ),
      );

      // Navigate to inventory page
      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      // Simulate escape key press
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Should navigate back
      expect(find.text('Navigate'), findsOneWidget);
    });

    testWidgets('should handle keyboard events without navigation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InventoryStatsOnly(),
        ),
      );

      await tester.pumpAndSettle();

      // Test that keyboard listener is present
      expect(find.byType(KeyboardListener), findsOneWidget);

      // Simulate arrow key events (without triggering navigation)
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(); // Use pump instead of pumpAndSettle to avoid navigation

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      // Test that keyboard events are received (verify KeyboardListener is functional)
      final keyboardListener = tester.widget<KeyboardListener>(
        find.byType(KeyboardListener),
      );
      expect(keyboardListener.onKeyEvent, isNotNull);
    });

    testWidgets('should have focus node for keyboard interaction', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InventoryStatsOnly(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify KeyboardListener has a focus node
      final keyboardListener = tester.widget<KeyboardListener>(
        find.byType(KeyboardListener),
      );
      expect(keyboardListener.focusNode, isNotNull);
    });

    testWidgets('should handle safe keyboard navigation events', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InventoryStatsOnly(),
        ),
      );

      await tester.pumpAndSettle();

      // Test escape key with proper navigation stack
      final context = tester.element(find.byType(InventoryStatsOnly));
      final navigator = Navigator.of(context);
      
      // Verify we can access the navigator
      expect(navigator, isNotNull);
      
      // Test keyboard events that don't cause navigation
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      
      // Verify the widget is still there and functional
      expect(find.byType(InventoryStatsOnly), findsOneWidget);
      expect(find.byType(KeyboardListener), findsOneWidget);
    });
  });

  group('Widget Interaction Tests', () {
    testWidgets('should find and interact with stat tiles', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InventoryStatsOnly(),
        ),
      );

      await tester.pumpAndSettle();

      // Find tiles by their text content and verify they exist
      expect(find.text('Total Items'), findsOneWidget);
      expect(find.text('Low Stock'), findsOneWidget);
      expect(find.text('Re-Stock'), findsOneWidget);

      // Find Material widgets (which contain InkWell) that contain the tile content
      final totalItemsMaterial = find.ancestor(
        of: find.text('Total Items'),
        matching: find.byType(Material),
      ).first;
      expect(totalItemsMaterial, findsOneWidget);

      final lowStockMaterial = find.ancestor(
        of: find.text('Low Stock'),
        matching: find.byType(Material),
      ).first;
      expect(lowStockMaterial, findsOneWidget);

      final restockMaterial = find.ancestor(
        of: find.text('Re-Stock'),
        matching: find.byType(Material),
      ).first;
      expect(restockMaterial, findsOneWidget);

      // Test that we can tap on the tiles (test one to avoid navigation issues)
      await tester.tap(totalItemsMaterial);
      await tester.pump(); // Use pump instead of pumpAndSettle to avoid navigation
    });

    testWidgets('should display correct icons in stat tiles', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InventoryStatsOnly(),
        ),
      );

      await tester.pumpAndSettle();

      // Check for archive icon (Total Items)
      expect(find.byIcon(Feather.archive), findsOneWidget);
      
      // Check for alert triangle icons (Low Stock and Re-Stock)
      expect(find.byIcon(Feather.alert_triangle), findsNWidgets(2));
    });

    testWidgets('should show warning icon in out of stock scenarios', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InventoryStatsOnly(),
        ),
      );

      await tester.pumpAndSettle();

      // Should show warning icons for out of stock alerts
      expect(find.byIcon(Icons.warning_amber_rounded), findsAtLeastNWidgets(1));
    });

    testWidgets('should have proper tile structure with gradients', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InventoryStatsOnly(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the tiles have proper structure with decoration
      final decoratedBoxes = find.byType(DecoratedBox);
      expect(decoratedBoxes, findsAtLeastNWidgets(3)); // At least 3 tiles

      // Verify AnimatedContainer widgets exist (for selection animation)
      final animatedContainers = find.byType(AnimatedContainer);
      expect(animatedContainers, findsAtLeastNWidgets(3));
    });
  });

  group('Dialog and Banner Tests', () {
    testWidgets('should handle dialog interactions', (tester) async {
      // Set desktop screen size to show the pill
      tester.binding.window.physicalSizeTestValue = const Size(1200, 800);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: InventoryStatsOnly(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the out of stock pill to open dialog
      final outOfStockPill = find.text('Out of Stock: 1');
      expect(outOfStockPill, findsOneWidget);

      await tester.tap(outOfStockPill);
      await tester.pumpAndSettle();

      // Should show dialog
      expect(find.text('Out of Stock'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      expect(find.text('Review & Restock'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
    });

    testWidgets('should handle mobile banner dismiss', (tester) async {
      // Set mobile screen size
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: InventoryStatsOnly(),
        ),
      );

      await tester.pumpAndSettle();

      // Should show mobile banner
      expect(find.text('Out of stock: 1 item(s) need immediate attention.'), findsOneWidget);
      expect(find.text('DISMISS'), findsOneWidget);

      // Tap dismiss button
      await tester.tap(find.text('DISMISS'));
      await tester.pumpAndSettle();

      // Banner should be dismissed
      expect(find.text('Out of stock: 1 item(s) need immediate attention.'), findsNothing);

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
    });

    testWidgets('should handle mobile banner view action', (tester) async {
      // Set mobile screen size
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: InventoryStatsOnly(),
        ),
      );

      await tester.pumpAndSettle();

      // Should show mobile banner
      expect(find.text('VIEW'), findsOneWidget);

      // Tap view button (this should navigate to LowStockRequestPage)
      await tester.tap(find.text('VIEW'));
      await tester.pumpAndSettle();

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
    });
  });

  group('Stock Calculations Tests', () {
    test('should correctly filter out of stock products', () {
      const products = [
        Product(
          id: '001',
          name: 'Normal Stock',
          category: 'Test',
          currentStock: 50,
          minStock: 20,
          maxStock: 100,
          price: 100.0,
          barcode: '123',
          supplier: 'Test',
        ),
        Product(
          id: '002',
          name: 'Out of Stock',
          category: 'Test',
          currentStock: 0,
          minStock: 20,
          maxStock: 100,
          price: 100.0,
          barcode: '456',
          supplier: 'Test',
        ),
        Product(
          id: '003',
          name: 'Another Out of Stock',
          category: 'Test',
          currentStock: 0,
          minStock: 15,
          maxStock: 80,
          price: 150.0,
          barcode: '789',
          supplier: 'Test',
        ),
      ];

      final outOfStock = products.where((p) => p.isOutOfStock).toList();
      expect(outOfStock.length, 2);
      expect(outOfStock[0].name, 'Out of Stock');
      expect(outOfStock[1].name, 'Another Out of Stock');
    });

    test('should correctly filter low stock products', () {
      const products = [
        Product(
          id: '001',
          name: 'Normal Stock',
          category: 'Test',
          currentStock: 50,
          minStock: 20,
          maxStock: 100,
          price: 100.0,
          barcode: '123',
          supplier: 'Test',
        ),
        Product(
          id: '002',
          name: 'Low Stock',
          category: 'Test',
          currentStock: 15,
          minStock: 20,
          maxStock: 100,
          price: 100.0,
          barcode: '456',
          supplier: 'Test',
        ),
        Product(
          id: '003',
          name: 'Out of Stock',
          category: 'Test',
          currentStock: 0,
          minStock: 15,
          maxStock: 80,
          price: 150.0,
          barcode: '789',
          supplier: 'Test',
        ),
      ];

      final lowStock = products.where((p) => p.isLowStock).toList();
      expect(lowStock.length, 1);
      expect(lowStock[0].name, 'Low Stock');
    });
  });

  group('Responsive Layout Tests', () {
    testWidgets('should use mobile layout for small screens', (tester) async {
      // Set mobile screen size
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: InventoryStatsOnly(),
        ),
      );

      await tester.pumpAndSettle();

      // Should show mobile banner and not show desktop pill
      expect(find.text('Out of stock: 1 item(s) need immediate attention.'), findsOneWidget);
      expect(find.text('Out of Stock: 1'), findsNothing);

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
    });

    testWidgets('should use desktop layout for large screens', (tester) async {
      // Set desktop screen size
      tester.binding.window.physicalSizeTestValue = const Size(1200, 800);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: InventoryStatsOnly(),
        ),
      );

      await tester.pumpAndSettle();

      // Should show desktop pill and clear any mobile banners
      expect(find.text('Out of Stock: 1'), findsOneWidget);

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
    });
  });
}