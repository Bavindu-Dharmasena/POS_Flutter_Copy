class ItemScanModel {
  final int id;
  final String name;
  final String barcode;
  final String category;     // category.category
  final String supplier;     // supplier.name
  final int reorderLevel;    // item.reorder_level
  final int currentStock;    // SUM(stock.quantity)
  final double price;        // MAX(stock.sell_price) as a simple current price

  const ItemScanModel({
    required this.id,
    required this.name,
    required this.barcode,
    required this.category,
    required this.supplier,
    required this.reorderLevel,
    required this.currentStock,
    required this.price,
  });

  factory ItemScanModel.fromMap(Map<String, Object?> m) => ItemScanModel(
        id: (m['id'] as num).toInt(),
        name: (m['name'] as String?) ?? '',
        barcode: (m['barcode'] as String?) ?? '',
        category: (m['category'] as String?) ?? '',
        supplier: (m['supplier'] as String?) ?? '',
        reorderLevel: (m['reorder_level'] as num?)?.toInt() ?? 0,
        currentStock: (m['current_stock'] as num?)?.toInt() ?? 0,
        price: (m['price'] as num?)?.toDouble() ?? 0.0,
      );
}
