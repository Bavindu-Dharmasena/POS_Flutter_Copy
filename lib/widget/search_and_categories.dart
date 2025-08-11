import 'package:flutter/material.dart';

class SearchAndCategories extends StatelessWidget {
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
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: TextField(
            onChanged: onSearchChange,
            decoration: InputDecoration(
              hintText: 'Search item or scan barcode...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        Expanded(
          child: searchQuery.isEmpty
              ? SizedBox(
                  height: gridHeight,
                  child: GridView.count(
                    crossAxisCount: gridCrossAxisCount,
                    padding: const EdgeInsets.all(10),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: categories.map((cat) {
                      final colorCode = itemsByCategory
                          .firstWhere((item) => item['category'] == cat)['colourCode'];
                      return GestureDetector(
                        onTap: () => onCategoryTap(cat),
                        child: Card(
                          color: Color(int.parse(
                              "0xFF${colorCode.toString().replaceAll('#', '')}")),
                          child: Center(
                            child: Text(
                              cat,
                              style: TextStyle(fontSize: isMobile ? 10 : 20),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                )
              : ListView(
                  children: searchedItems.map((item) {
                    final firstBatch = item['batches'][0];
                    return ListTile(
                      title: Text(item['name']),
                      trailing: Text('Rs. ${firstBatch['price']}'),
                      onTap: () => onSearchedItemTap(item),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}
