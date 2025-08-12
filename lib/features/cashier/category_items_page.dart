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

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        appBar: AppBar(title: Text(widget.category)),
        body: Shortcuts(
          shortcuts: {
            LogicalKeySet(LogicalKeyboardKey.arrowUp): const ArrowDirection.up(),
            LogicalKeySet(LogicalKeyboardKey.arrowDown): const ArrowDirection.down(),
            LogicalKeySet(LogicalKeyboardKey.arrowLeft): const ArrowDirection.left(),
            LogicalKeySet(LogicalKeyboardKey.arrowRight): const ArrowDirection.right(),
            LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
            LogicalKeySet(LogicalKeyboardKey.space): const ActivateIntent(),
            LogicalKeySet(LogicalKeyboardKey.escape): const EscapeIntent(), // 🔹 ESC to go back
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
                  widget.onItemSelected(widget.items[_focusedIndex]);
                  return null;
                },
              ),
              EscapeIntent: CallbackAction<EscapeIntent>(
                onInvoke: (intent) {
                  Navigator.pop(context); // 🔹 Go back on ESC
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
                  final firstBatch = item['batches']?[0];
                  final price = firstBatch != null ? firstBatch['price'] : 'N/A';
                  final itemColorCode = item['colourCode'];
                  final isFocused = index == _focusedIndex;

                  return AnimatedScale(
                    scale: isFocused ? 1.06 : 1.0, // 🔹 Slight zoom on focus
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    child: GestureDetector(
                      onTap: () => widget.onItemSelected(item),
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
                                item['name'],
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
