import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CategoryItemsPage extends StatefulWidget {
  final String category;
  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic>) onItemSelected;

  const CategoryItemsPage({
    super.key,
    required this.category,
    required this.items,
    required this.onItemSelected,
  });

  @override
  State<CategoryItemsPage> createState() => _CategoryItemsPageState();
}

class _CategoryItemsPageState extends State<CategoryItemsPage> {
  int _focusedIndex = 0;
  final int _crossAxisCount = 6;

  void _moveFocus(int offset) {
    setState(() {
      int newIndex = _focusedIndex + offset;
      if (newIndex < 0) {
        newIndex = 0;
      } else if (newIndex >= widget.items.length) {
        newIndex = widget.items.length - 1;
      }
      _focusedIndex = newIndex;
    });
  }

  void _moveUp() => _moveFocus(-_crossAxisCount);
  void _moveDown() => _moveFocus(_crossAxisCount);
  void _moveLeft() => _moveFocus(-1);
  void _moveRight() => _moveFocus(1);

  // ---------- DIALOG ----------
  Future<int?> _showQuantityInputDialog({
    required Map<String, dynamic> item,
    required Map<String, dynamic> batch,
  }) {
    int quantity = 1;
    return showDialog<int>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          'Enter quantity for ${item['name']} (Batch: ${batch['batchID']})',
        ),
        content: TextField(
          autofocus: true,
          keyboardType: TextInputType.number,
          onChanged: (value) => quantity = int.tryParse(value) ?? 1,
          onSubmitted: (value) {
            quantity = int.tryParse(value) ?? 1;
            Navigator.of(dialogCtx).pop(quantity); // return quantity
          },
          decoration: const InputDecoration(hintText: 'Quantity'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop(quantity); // return quantity
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ---------- ITEM PICK FLOW ----------
  Future<void> _pickItemAndReturn(Map<String, dynamic> item) async {
    final batches = (item['batches'] as List?) ?? const [];
    if (batches.isEmpty) {
      // No batch -> just go back without result or show a message (optional)
      return;
    }
    final Map<String, dynamic> batch = Map<String, dynamic>.from(batches.first);

    final qty = await _showQuantityInputDialog(item: item, batch: batch);
    if (qty == null || !mounted) return;

    // Pop ONLY this page (CategoryItemsPage) with the selection result.
    Navigator.pop(context, {'item': item, 'batch': batch, 'quantity': qty});
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        appBar: AppBar(title: Text(widget.category)),
        body: Shortcuts(
          shortcuts: {
            LogicalKeySet(LogicalKeyboardKey.arrowUp):
                const ArrowDirection.up(),
            LogicalKeySet(LogicalKeyboardKey.arrowDown):
                const ArrowDirection.down(),
            LogicalKeySet(LogicalKeyboardKey.arrowLeft):
                const ArrowDirection.left(),
            LogicalKeySet(LogicalKeyboardKey.arrowRight):
                const ArrowDirection.right(),
            LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
            LogicalKeySet(LogicalKeyboardKey.space): const ActivateIntent(),
            LogicalKeySet(LogicalKeyboardKey.escape):
                const EscapeIntent(), // ESC to go back
          },
          child: Actions(
            actions: {
              ArrowDirection: CallbackAction<ArrowDirection>(
                onInvoke: (intent) {
                  switch (intent.direction) {
                    case ArrowKey.up:
                      _moveUp();
                      break;
                    case ArrowKey.down:
                      _moveDown();
                      break;
                    case ArrowKey.left:
                      _moveLeft();
                      break;
                    case ArrowKey.right:
                      _moveRight();
                      break;
                  }
                  return null;
                },
              ),
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (intent) {
                  final item = widget.items[_focusedIndex];
                  _pickItemAndReturn(item); // open dialog, then pop with result
                  return null;
                },
              ),
              EscapeIntent: CallbackAction<EscapeIntent>(
                onInvoke: (intent) {
                  Navigator.pop(context); // Back one page
                  return null;
                },
              ),
            },
            child: Focus(
              autofocus: true,
              child: GridView.count(
                crossAxisCount: _crossAxisCount,
                padding: const EdgeInsets.all(10),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: List.generate(widget.items.length, (index) {
                  final item = widget.items[index];
                  final firstBatch =
                      (item['batches'] as List?)?.isNotEmpty == true
                      ? (item['batches'] as List).first
                      : null;
                  final price = firstBatch != null
                      ? firstBatch['price']
                      : 'N/A';
                  final itemColorCode =
                      (item['colourCode'] ?? '#222222') as String;
                  final isFocused = index == _focusedIndex;

                  return AnimatedScale(
                    scale: isFocused ? 1.06 : 1.0,
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    child: GestureDetector(
                      onTap: () => _pickItemAndReturn(item),
                      child: Card(
                        elevation: isFocused ? 6 : 2,
                        color: Color(
                          int.parse("0xFF${itemColorCode.replaceAll('#', '')}"),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item['name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'Rs. $price',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ArrowDirection extends Intent {
  final ArrowKey direction;
  const ArrowDirection.up() : direction = ArrowKey.up;
  const ArrowDirection.down() : direction = ArrowKey.down;
  const ArrowDirection.left() : direction = ArrowKey.left;
  const ArrowDirection.right() : direction = ArrowKey.right;
}

class EscapeIntent extends Intent {
  const EscapeIntent();
}

enum ArrowKey { up, down, left, right }
