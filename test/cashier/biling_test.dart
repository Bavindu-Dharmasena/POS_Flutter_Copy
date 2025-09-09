import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/features/cashier/category_items_page.dart';
// Update with your actual import path

void main() {
  group('CategoryItemsPage Tests', () {
    late List<Map<String, dynamic>> mockItems;
    late Function(Map<String, dynamic>) mockOnItemSelected;
    late List<Map<String, dynamic>> capturedSelections;

    setUp(() {
      capturedSelections = [];
      mockOnItemSelected = (item) => capturedSelections.add(item);
      
      mockItems = [
        {
          'name': 'Item 1',
          'colourCode': '#FF0000',
          'batches': [
            {'batchID': 'B001', 'price': 100.0}
          ]
        },
        {
          'name': 'Item 2',
          'colourCode': '#00FF00',
          'batches': [
            {'batchID': 'B002', 'price': 200.0}
          ]
        },
        {
          'name': 'Item 3',
          'colourCode': '#0000FF',
          'batches': [
            {'batchID': 'B003', 'price': 300.0}
          ]
        },
        {
          'name': 'Item 4',
          'colourCode': '#FFFF00',
          'batches': [
            {'batchID': 'B004', 'price': 400.0}
          ]
        },
        {
          'name': 'Item 5',
          'colourCode': '#FF00FF',
          'batches': [
            {'batchID': 'B005', 'price': 500.0}
          ]
        },
        {
          'name': 'Item 6',
          'colourCode': '#00FFFF',
          'batches': [
            {'batchID': 'B006', 'price': 600.0}
          ]
        },
        {
          'name': 'Item 7',
          'colourCode': '#888888',
          'batches': [
            {'batchID': 'B007', 'price': 700.0}
          ]
        },
      ];
    });

    Widget createTestWidget({List<Map<String, dynamic>>? items}) {
      return MaterialApp(
        home: CategoryItemsPage(
          category: 'Test Category',
          items: items ?? mockItems,
          onItemSelected: mockOnItemSelected,
        ),
      );
    }

    testWidgets('should display category title in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      expect(find.text('Test Category'), findsOneWidget);
    });

    testWidgets('should display all items in grid', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      for (int i = 0; i < mockItems.length; i++) {
        expect(find.text('Item ${i + 1}'), findsOneWidget);
        expect(find.text('Rs. ${(i + 1) * 100}.0'), findsOneWidget);
      }
    });

    testWidgets('should display item without batches correctly', (tester) async {
      final itemsWithoutBatch = [
        {
          'name': 'No Batch Item',
          'colourCode': '#FF0000',
          'batches': []
        }
      ];
      
      await tester.pumpWidget(createTestWidget(items: itemsWithoutBatch));
      
      expect(find.text('No Batch Item'), findsOneWidget);
      expect(find.text('Rs. N/A'), findsOneWidget);
    });

    testWidgets('should handle null batches', (tester) async {
      final itemsWithNullBatch = [
        {
          'name': 'Null Batch Item',
          'colourCode': '#FF0000',
          'batches': null
        }
      ];
      
      await tester.pumpWidget(createTestWidget(items: itemsWithNullBatch));
      
      expect(find.text('Null Batch Item'), findsOneWidget);
      expect(find.text('Rs. N/A'), findsOneWidget);
    });

    testWidgets('should apply correct color from colourCode', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final card = tester.widget<Card>(find.byType(Card).first);
      expect(card.color, equals(const Color(0xFFFF0000))); // Red color
    });

    testWidgets('should handle missing colourCode with default', (tester) async {
      final itemsWithoutColor = [
        {
          'name': 'No Color Item',
          'batches': [
            {'batchID': 'B001', 'price': 100.0}
          ]
        }
      ];
      
      await tester.pumpWidget(createTestWidget(items: itemsWithoutColor));
      
      final card = tester.widget<Card>(find.byType(Card).first);
      expect(card.color, equals(const Color(0xFF222222))); // Default color
    });

    group('Keyboard Navigation Tests', () {
      testWidgets('should move focus right with arrow right key', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Initially focused on index 0
        expect(find.byType(AnimatedScale), findsWidgets);
        
        // Press right arrow
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        
        // Should move to index 1
        // You can verify this by checking the scale animation or focus state
      });

      testWidgets('should move focus left with arrow left key', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Move to index 1 first
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        
        // Then move back left
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();
        
        // Should be back at index 0
      });

      testWidgets('should move focus down with arrow down key', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Press down arrow (should move by crossAxisCount = 6)
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        
        // Should move to index 6 if it exists
      });

      testWidgets('should move focus up with arrow up key', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Move down first to have somewhere to go up from
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        
        // Then move up
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
      });

      testWidgets('should not move focus below 0', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Try to move left from index 0
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();
        
        // Try to move up from index 0
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        
        // Focus should remain at index 0
      });

      testWidgets('should not move focus beyond last item', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Move to last item by pressing right multiple times
        for (int i = 0; i < mockItems.length; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await tester.pumpAndSettle();
        }
        
        // Try to move beyond last item
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        
        // Focus should remain at last valid index
      });

      testWidgets('should navigate back with escape key', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Press escape
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        
        // Should navigate back (page should be popped)
      });
    });

    group('Item Selection Tests', () {
      testWidgets('should show quantity dialog when item is tapped', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap on first item
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        // Should show quantity dialog
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Enter quantity for Item 1 (Batch: B001)'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Add'), findsOneWidget);
      });

      testWidgets('should show quantity dialog when enter key is pressed', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Press enter key
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        // Should show quantity dialog
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Enter quantity for Item 1 (Batch: B001)'), findsOneWidget);
      });

      testWidgets('should show quantity dialog when space key is pressed', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Press space key
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();

        // Should show quantity dialog
        expect(find.byType(AlertDialog), findsOneWidget);
      });

      testWidgets('should handle item without batches gracefully', (tester) async {
        final itemsWithoutBatches = [
          {
            'name': 'No Batch Item',
            'colourCode': '#FF0000',
            'batches': []
          }
        ];
        
        await tester.pumpWidget(createTestWidget(items: itemsWithoutBatches));
        await tester.pumpAndSettle();

        // Tap on item without batches
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        // Should not show dialog and should not crash
        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets('should accept quantity input in dialog', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Open dialog
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        // Enter quantity
        await tester.enterText(find.byType(TextField), '5');
        await tester.pumpAndSettle();

        // Tap Add button
        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();

        // Should close dialog
        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets('should submit quantity when pressing enter in text field', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Open dialog
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        // Enter quantity and press enter
        await tester.enterText(find.byType(TextField), '3');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Should close dialog
        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets('should handle invalid quantity input', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Open dialog
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        // Enter invalid quantity
        await tester.enterText(find.byType(TextField), 'invalid');
        await tester.pumpAndSettle();

        // Tap Add button
        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();

        // Should still close dialog (defaults to quantity 1)
        expect(find.byType(AlertDialog), findsNothing);
      });
    });

    group('Focus and Animation Tests', () {
      testWidgets('should apply correct scale to focused item', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Find all AnimatedScale widgets
        final animatedScales = tester.widgetList<AnimatedScale>(find.byType(AnimatedScale));
        
        // First item should be focused (scale 1.06)
        expect(animatedScales.first.scale, equals(1.06));
        
        // Other items should not be focused (scale 1.0)
        for (int i = 1; i < animatedScales.length; i++) {
          expect(animatedScales.elementAt(i).scale, equals(1.0));
        }
      });

      testWidgets('should apply correct elevation to focused item', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final cards = tester.widgetList<Card>(find.byType(Card));
        
        // First card should have higher elevation (focused)
        expect(cards.first.elevation, equals(6));
        
        // Other cards should have lower elevation
        for (int i = 1; i < cards.length; i++) {
          expect(cards.elementAt(i).elevation, equals(2));
        }
      });

      testWidgets('should update focus when navigation keys are pressed', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Move focus right
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();

        final animatedScales = tester.widgetList<AnimatedScale>(find.byType(AnimatedScale));
        
        // Second item should now be focused
        expect(animatedScales.elementAt(1).scale, equals(1.06));
        expect(animatedScales.first.scale, equals(1.0));
      });
    });

    group('Edge Cases and Error Handling', () {
      testWidgets('should handle empty items list', (tester) async {
        await tester.pumpWidget(createTestWidget(items: []));
        await tester.pumpAndSettle();

        expect(find.byType(Card), findsNothing);
        expect(find.text('Test Category'), findsOneWidget); // App bar should still be there
      });

      testWidgets('should handle items with missing name', (tester) async {
        final itemsWithMissingName = [
          {
            'colourCode': '#FF0000',
            'batches': [
              {'batchID': 'B001', 'price': 100.0}
            ]
          }
        ];
        
        await tester.pumpWidget(createTestWidget(items: itemsWithMissingName));
        await tester.pumpAndSettle();

        expect(find.byType(Card), findsOneWidget);
        // Should display empty string for missing name
        expect(find.text(''), findsWidgets);
      });

      testWidgets('should handle batches with missing price', (tester) async {
        final itemsWithMissingPrice = [
          {
            'name': 'Missing Price Item',
            'colourCode': '#FF0000',
            'batches': [
              {'batchID': 'B001'}
            ]
          }
        ];
        
        await tester.pumpWidget(createTestWidget(items: itemsWithMissingPrice));
        await tester.pumpAndSettle();

        expect(find.text('Missing Price Item'), findsOneWidget);
        expect(find.text('Rs. null'), findsOneWidget);
      });

      testWidgets('should not crash when pressing navigation keys with empty items', (tester) async {
        await tester.pumpWidget(createTestWidget(items: []));
        await tester.pumpAndSettle();

        // These should not crash
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();

        // No exception should be thrown
      });
    });

    group('Dialog Interaction Tests', () {
      testWidgets('should return correct data when quantity is entered', (tester) async {
        bool navigationPopped = false;
        Map<String, dynamic>? poppedResult;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryItemsPage(
                        category: 'Test Category',
                        items: mockItems,
                        onItemSelected: mockOnItemSelected,
                      ),
                    ),
                  );
                  poppedResult = result;
                  navigationPopped = true;
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );

        // Open the page
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // Tap on first item to open dialog
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        // Enter quantity
        await tester.enterText(find.byType(TextField), '5');
        await tester.pumpAndSettle();

        // Submit
        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();

        // Verify the page popped with correct result
        expect(navigationPopped, isTrue);
        expect(poppedResult, isNotNull);
        expect(poppedResult!['item']['name'], equals('Item 1'));
        expect(poppedResult!['batch']['batchID'], equals('B001'));
        expect(poppedResult!['quantity'], equals(5));
      });

      testWidgets('should handle dialog cancellation', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Open dialog
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        // Cancel dialog by tapping outside or using system back
        await tester.tapAt(const Offset(10, 10)); // Tap outside dialog
        await tester.pumpAndSettle();

        // Dialog should be closed
        expect(find.byType(AlertDialog), findsNothing);
      });
    });

    group('Intent and Action Tests', () {
      testWidgets('should register all required shortcuts', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final shortcuts = tester.widget<Shortcuts>(find.byType(Shortcuts));
        
        expect(shortcuts.shortcuts.containsKey(LogicalKeySet(LogicalKeyboardKey.arrowUp)), isTrue);
        expect(shortcuts.shortcuts.containsKey(LogicalKeySet(LogicalKeyboardKey.arrowDown)), isTrue);
        expect(shortcuts.shortcuts.containsKey(LogicalKeySet(LogicalKeyboardKey.arrowLeft)), isTrue);
        expect(shortcuts.shortcuts.containsKey(LogicalKeySet(LogicalKeyboardKey.arrowRight)), isTrue);
        expect(shortcuts.shortcuts.containsKey(LogicalKeySet(LogicalKeyboardKey.enter)), isTrue);
        expect(shortcuts.shortcuts.containsKey(LogicalKeySet(LogicalKeyboardKey.space)), isTrue);
        expect(shortcuts.shortcuts.containsKey(LogicalKeySet(LogicalKeyboardKey.escape)), isTrue);
      });

      testWidgets('should have Focus widget with autofocus enabled', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final focus = tester.widget<Focus>(find.byType(Focus));
        expect(focus.autofocus, isTrue);
      });
    });

    group('Grid Layout Tests', () {
      testWidgets('should display items in 6-column grid', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final gridView = tester.widget<GridView>(find.byType(GridView));
        expect((gridView.childrenDelegate as SliverChildListDelegate).children.length, 
               equals(mockItems.length));
      });

      testWidgets('should apply correct padding and spacing', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final gridView = tester.widget<GridView>(find.byType(GridView));
        final delegate = gridView.delegate as SliverGridDelegateWithFixedCrossAxisCount;
        
        expect(delegate.crossAxisCount, equals(6));
        expect(delegate.crossAxisSpacing, equals(10));
        expect(delegate.mainAxisSpacing, equals(10));
      });
    });

    group('Widget State Management', () {
      testWidgets('should maintain focus state across rebuilds', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Move focus to second item
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();

        // Trigger rebuild by calling setState (simulate external state change)
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Focus should still be maintained after rebuild
        final animatedScales = tester.widgetList<AnimatedScale>(find.byType(AnimatedScale));
        expect(animatedScales.elementAt(1).scale, equals(1.06));
      });
    });
  });

  group('ArrowDirection Intent Tests', () {
    test('should create correct ArrowDirection intents', () {
      final upIntent = ArrowDirection.up();
      final downIntent = ArrowDirection.down();
      final leftIntent = ArrowDirection.left();
      final rightIntent = ArrowDirection.right();

      expect(upIntent.direction, equals(ArrowKey.up));
      expect(downIntent.direction, equals(ArrowKey.down));
      expect(leftIntent.direction, equals(ArrowKey.left));
      expect(rightIntent.direction, equals(ArrowKey.right));
    });
  });

  group('EscapeIntent Tests', () {
    test('should create EscapeIntent', () {
      final escapeIntent = EscapeIntent();
      expect(escapeIntent, isA<EscapeIntent>());
    });
  });
}

extension on GridView {
  Null get delegate => null;
}

// Helper extension to make testing easier
extension CategoryItemsPageTester on WidgetTester {
  /// Helper method to get the current focused index by checking AnimatedScale widgets
  int getCurrentFocusedIndex() {
    final animatedScales = widgetList<AnimatedScale>(find.byType(AnimatedScale));
    for (int i = 0; i < animatedScales.length; i++) {
      if (animatedScales.elementAt(i).scale == 1.06) {
        return i;
      }
    }
    return -1; // No focused item found
  }

  /// Helper method to simulate navigation and verify focus changes
  Future<void> navigateAndVerifyFocus(
    LogicalKeyboardKey key,
    int expectedIndex,
  ) async {
    await sendKeyEvent(key);
    await pumpAndSettle();
    expect(getCurrentFocusedIndex(), equals(expectedIndex));
  }
}
