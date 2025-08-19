import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SearchAndCategories extends StatefulWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChange;

  final List<Map<String, dynamic>> itemsByCategory;
  final List<String> categories;

  final List<Map<String, dynamic>> searchedItems;
  final void Function(String category) onCategoryTap;
  final void Function(Map<String, dynamic> item) onSearchedItemTap;

  // optional layout tweaks for mobile
  final double? gridHeight;
  final int gridCrossAxisCount;

  // optional control of the search field
  final FocusNode? searchFieldFocusNode;
  final TextEditingController? searchController;

  // focus node for categories grid (so parent can focus via hotkey)
  final FocusNode? categoriesFocusNode;

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
    this.gridCrossAxisCount = 4,
    this.searchFieldFocusNode,
    this.searchController,
    this.categoriesFocusNode,
  });

  @override
  State<SearchAndCategories> createState() => _SearchAndCategoriesState();
}

class _SearchAndCategoriesState extends State<SearchAndCategories> {
  // Category keyboard navigation
  int _selectedCategoryIndex = 0;
  bool _categoriesHasFocus = false;

  // Search results keyboard navigation
  final FocusNode _resultsFocusNode = FocusNode(debugLabel: 'SearchResults');
  int _selectedSearchIndex = 0;

  @override
  void dispose() {
    _resultsFocusNode.dispose();
    super.dispose();
  }

  int _clamp(int i, int max) {
    if (max <= 0) return 0;
    if (i < 0) return 0;
    if (i >= max) return max - 1;
    return i;
  }

  bool _handleCategoryKeys(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (widget.searchQuery.isNotEmpty) return false; // grid hidden when searching

    final key = event.logicalKey;
    int next = _selectedCategoryIndex;

    if (key == LogicalKeyboardKey.arrowRight) {
      next = _selectedCategoryIndex + 1;
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      next = _selectedCategoryIndex - 1;
    } else if (key == LogicalKeyboardKey.arrowDown) {
      next = _selectedCategoryIndex + widget.gridCrossAxisCount;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      next = _selectedCategoryIndex - widget.gridCrossAxisCount;
    } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      if (widget.categories.isNotEmpty) {
        widget.onCategoryTap(widget.categories[_selectedCategoryIndex]);
        return true;
      }
      return false;
    } else {
      return false;
    }

    next = _clamp(next, widget.categories.length);
    if (next != _selectedCategoryIndex) {
      setState(() => _selectedCategoryIndex = next);
    }
    return true;
  }

  bool _handleSearchResultsKeys(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (widget.searchQuery.isEmpty) return false; // no list when empty

    final key = event.logicalKey;
    int next = _selectedSearchIndex;

    if (key == LogicalKeyboardKey.arrowDown) {
      next = _selectedSearchIndex + 1;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      if (_selectedSearchIndex == 0) {
        // jump back to search field
        widget.searchFieldFocusNode?.requestFocus();
        return true;
      }
      next = _selectedSearchIndex - 1;
    } else if (key == LogicalKeyboardKey.enter) {
      if (widget.searchedItems.isNotEmpty) {
        final item = widget.searchedItems[_selectedSearchIndex];
        widget.onSearchedItemTap(item);
        return true;
      }
      return false;
    } else if (key == LogicalKeyboardKey.escape) {
      widget.searchFieldFocusNode?.requestFocus();
      return true;
    } else {
      return false;
    }

    next = _clamp(next, widget.searchedItems.length);
    if (next != _selectedSearchIndex) {
      setState(() => _selectedSearchIndex = next);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          // Let ArrowDown jump into search results when visible
          child: Focus(
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.arrowDown &&
                  widget.searchQuery.isNotEmpty) {
                _resultsFocusNode.requestFocus();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: TextField(
              controller: widget.searchController,
              focusNode: widget.searchFieldFocusNode,
              onChanged: (v) {
                // reset results cursor to top when query changes
                setState(() => _selectedSearchIndex = 0);
                widget.onSearchChange(v);
              },
              decoration: InputDecoration(
                hintText: 'Search item or scan barcode...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: widget.searchQuery.isEmpty
              ? SizedBox(
                  height: widget.gridHeight,
                  child: Focus(
                    focusNode: widget.categoriesFocusNode,
                    onFocusChange: (has) => setState(() => _categoriesHasFocus = has),
                    onKeyEvent: (node, event) =>
                        _handleCategoryKeys(event)
                            ? KeyEventResult.handled
                            : KeyEventResult.ignored,
                    child: GridView.count(
                      crossAxisCount: widget.gridCrossAxisCount,
                      padding: const EdgeInsets.all(10),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      children: widget.categories.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final cat = entry.value;

                        final colorCode = widget.itemsByCategory.firstWhere(
                          (item) => item['category'] == cat,
                        )['colourCode'];

                        final isSelected = _categoriesHasFocus && idx == _selectedCategoryIndex;

                        // Style is the same; only adds a subtle scale when focused/selected.
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedCategoryIndex = idx);
                            widget.onCategoryTap(cat);
                          },
                          child: AnimatedScale(
                            scale: isSelected ? 1.08 : 1.0,
                            duration: const Duration(milliseconds: 120),
                            child: Card(
                              color: Color(
                                int.parse("0xFF${colorCode.toString().replaceAll('#', '')}"),
                              ),
                              child: Center(
                                child: Text(
                                  cat,
                                  style: TextStyle(fontSize: isMobile ? 10 : 20),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                )
              : Focus(
                  focusNode: _resultsFocusNode,
                  onKeyEvent: (node, event) =>
                      _handleSearchResultsKeys(event)
                          ? KeyEventResult.handled
                          : KeyEventResult.ignored,
                  child: ListView.builder(
                    itemCount: widget.searchedItems.length,
                    itemBuilder: (_, i) {
                      final item = widget.searchedItems[i];
                      final firstBatch = item['batches'][0];
                      final selected = i == _selectedSearchIndex && _resultsFocusNode.hasFocus;

                      return Container(
                        // Minimal selection feedback; keeps style intact
                        decoration: selected
                            ? BoxDecoration(
                                border: Border.all(color: Colors.white24, width: 1),
                                borderRadius: BorderRadius.circular(6),
                              )
                            : null,
                        child: ListTile(
                          title: Text(item['name']),
                          trailing: Text('Rs. ${firstBatch['price']}'),
                          onTap: () => widget.onSearchedItemTap(item),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
