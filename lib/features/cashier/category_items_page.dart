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

  // ---------- NAV FOCUS HELPERS ----------
  void _moveFocus(int offset, int currentCrossAxisCount) {
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

  void _moveUp(int currentCrossAxisCount) => _moveFocus(-currentCrossAxisCount, currentCrossAxisCount);
  void _moveDown(int currentCrossAxisCount) => _moveFocus(currentCrossAxisCount, currentCrossAxisCount);
  void _moveLeft(int currentCrossAxisCount) => _moveFocus(-1, currentCrossAxisCount);
  void _moveRight(int currentCrossAxisCount) => _moveFocus(1, currentCrossAxisCount);

  // ---------- HELPERS ----------
  Color _parseHexColor(String? hex, {String fallback = '#222222'}) {
    final raw = (hex == null || hex.isEmpty) ? fallback : hex;
    final normalized = raw.startsWith('#') ? raw.substring(1) : raw;
    final six = normalized.length == 6 ? normalized : fallback.replaceAll('#', '');
    return Color(int.parse('0xFF$six'));
  }

  void _finishSelection(Map<String, dynamic> item, Map<String, dynamic> batch, int qty) {
    final payload = {
      'item': item,
      'batch': batch,
      'quantity': qty,
    };
    widget.onItemSelected(payload);
    if (mounted) {
      Navigator.pop(context, payload);
    }
  }

  // ---------- DIALOGS ----------
  Future<int?> _showQuantityInputDialog({
    required Map<String, dynamic> item,
    required Map<String, dynamic> batch,
  }) async {
    int quantity = 1;
    return showDialog<int>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Enter quantity for ${item['name']} (Batch: ${batch['batchID']})'),
        content: TextField(
          autofocus: true,
          keyboardType: TextInputType.number,
          onChanged: (value) => quantity = int.tryParse(value) ?? 1,
          onSubmitted: (value) {
            quantity = int.tryParse(value) ?? 1;
            Navigator.of(dialogCtx).pop(quantity);
          },
          decoration: const InputDecoration(hintText: 'Quantity'),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogCtx).pop(null);
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Home'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(quantity),
                child: const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _showBatchPickerDialog({
    required String itemName,
    required List<Map<String, dynamic>> batches,
  }) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Select Batch for $itemName'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: batches.length,
            itemBuilder: (context, index) {
              final batch = batches[index];
              final dynamic price = batch['price'];
              final dynamic discount = batch['discountAmount'] ?? 0.0;
              return ListTile(
                title: Text('Batch: ${batch['batchID']}  •  Price: Rs. $price'),
                subtitle: (discount is num && discount > 0)
                    ? Text('Discount: Rs. $discount')
                    : null,
                onTap: () => Navigator.of(context).pop(batch),
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------- ITEM PICK FLOW ----------
  Future<void> _pickItemAndReturn(Map<String, dynamic> item) async {
    final List<Map<String, dynamic>> batchList =
        List<Map<String, dynamic>>.from(item['batches'] ?? const []);

    if (batchList.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No batches available for this item')),
      );
      return;
    }

    Map<String, dynamic> selectedBatch;
    if (batchList.length == 1) {
      selectedBatch = Map<String, dynamic>.from(batchList.first);
    } else {
      final chosen = await _showBatchPickerDialog(
        itemName: item['name'] ?? '',
        batches: batchList,
      );
      if (chosen == null) return;
      selectedBatch = Map<String, dynamic>.from(chosen);
    }

    selectedBatch['name'] = item['name'];

    final qty = await _showQuantityInputDialog(item: item, batch: selectedBatch);
    if (qty == null) return;

    _finishSelection(item, selectedBatch, qty);
  }

  // Helper function to calculate cross axis count based on screen width
  int _calculateCrossAxisCount(double screenWidth) {
    if (screenWidth > 1000) {
      return 6;
    } else if (screenWidth > 500) {
      return 4;  // Changed from 6 to 4
    } else {
      return 2;
    }
  }

  // Helper function to get font size based on cross axis count
  double _getFontSize(int crossAxisCount, {bool isTitle = true}) {
    if (crossAxisCount == 6) {
      return isTitle ? 25 : 20;
    } else if (crossAxisCount == 4) {
      return isTitle ? 25 : 20;  // Medium size for 4 columns
    } else {
      return isTitle ? 25 : 20;  // Largest size for 2 columns
    }
  }      

  // Helper function to get image size based on cross axis count
  double _getImageSize(int crossAxisCount) {
    if (crossAxisCount == 6) {
      return 40;  // Smallest for 6 columns
    } else if (crossAxisCount == 4) {
      return 50;  // Medium for 4 columns
    } else {
      return 60;  // Largest for 2 columns
    }
  }

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
            LogicalKeySet(LogicalKeyboardKey.escape): const EscapeIntent(),
          },
          child: Actions(
            actions: {
              ArrowDirection: CallbackAction<ArrowDirection>(
                onInvoke: (intent) {
                  return null;
                },
              ),
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (intent) {
                  if (widget.items.isEmpty) return null;
                  final item = widget.items[_focusedIndex];
                  _pickItemAndReturn(item);
                  return null;
                },
              ),
              EscapeIntent: CallbackAction<EscapeIntent>(
                onInvoke: (intent) {
                  if (Navigator.of(context).canPop()) {
                    Navigator.pop(context);
                  }
                  return null;
                },
              ),
            },
            child: Focus(
              autofocus: true,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final currentCrossAxisCount = _calculateCrossAxisCount(screenWidth);
                  final titleFontSize = _getFontSize(currentCrossAxisCount, isTitle: true);
                  final priceFontSize = _getFontSize(currentCrossAxisCount, isTitle: false);
                  final imageSize = _getImageSize(currentCrossAxisCount);
                  
                  return Actions(
                    actions: {
                      ArrowDirection: CallbackAction<ArrowDirection>(
                        onInvoke: (intent) {
                          switch (intent.direction) {
                            case ArrowKey.up:
                              _moveUp(currentCrossAxisCount);
                              break;
                            case ArrowKey.down:
                              _moveDown(currentCrossAxisCount);
                              break;
                            case ArrowKey.left:
                              _moveLeft(currentCrossAxisCount);
                              break;
                            case ArrowKey.right:
                              _moveRight(currentCrossAxisCount);
                              break;
                          }
                          return null;
                        },
                      ),
                    },
                    child: GridView.count(
                      crossAxisCount: currentCrossAxisCount,
                      padding: const EdgeInsets.all(10),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      children: List.generate(widget.items.length, (index) {
                        final item = widget.items[index];
                        final List batches = (item['batches'] as List?) ?? const [];
                        final firstBatch = batches.isNotEmpty ? batches.first : null;
                        final dynamic price = firstBatch != null ? firstBatch['price'] : 'N/A';
                        final String itemColorCode = (item['colourCode'] ?? '#222222') as String;
                        final String itemImage = (item['itemImage'] ?? 'assets/item/placeholder.png') as String;
                        final bool isFocused = index == _focusedIndex;

                        return AnimatedScale(
                          scale: isFocused ? 1.06 : 1.0,
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeOut,
                          child: GestureDetector(
                            onTap: () => _pickItemAndReturn(item),
                            child: Card(
                              elevation: isFocused ? 6 : 2,
                              color: _parseHexColor(itemColorCode),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      (item['name'] ?? '').toString(),
                                      style: TextStyle(
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Image.asset(
                                          itemImage,
                                          width: imageSize,
                                          height: imageSize,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Icon(Icons.image_not_supported, 
                                                   size: imageSize * 0.75, 
                                                   color: Colors.white.withOpacity(0.7)),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      batches.isEmpty ? 'N/A' : 'Rs. $price',
                                      style: TextStyle(
                                        fontSize: priceFontSize,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                },
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