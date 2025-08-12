import 'package:flutter/material.dart';

class CategoryItemsPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        appBar: AppBar(title: Text(category)),
        body: GridView.count(
          crossAxisCount: 6,
          padding: const EdgeInsets.all(10),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: items.map((item) {
            final firstBatch = item['batches']?[0];
            final price = firstBatch != null ? firstBatch['price'] : 'N/A';
            final itemColorCode = item['colourCode'];

            return GestureDetector(
              onTap: () => onItemSelected(item),
              child: Card(
                color: Color(int.parse("0xFF${itemColorCode.replaceAll('#', '')}")),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['name'],
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      Text('Rs. $price', style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
