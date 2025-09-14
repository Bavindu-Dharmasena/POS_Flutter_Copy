class ItemScanModel {
  final int id;               // item.id
  final String name;          // item.name
  final String category;      // category.category
  final int currentStock;     // SUM(stock.quantity)
  final int reorderLevel;     // item.reorder_level
  final double price;         // latest stock.sell_price
  final String barcode;       // item.barcode
  final String supplier;      // supplier.name

  const ItemScanModel({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.reorderLevel,
    required this.price,
    required this.barcode,
    required this.supplier,
  });

  factory ItemScanModel.fromRow(Map<String, Object?> row) {
    double _toDouble(Object? v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int _toInt(Object? v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return ItemScanModel(
      id: _toInt(row['id']),
      name: (row['name'] as String? ?? ''),
      category: (row['category'] as String? ?? ''),
      currentStock: _toInt(row['current_stock']),
      reorderLevel: _toInt(row['reorder_level']),
      price: _toDouble(row['price']),
      barcode: (row['barcode'] as String? ?? ''),
      supplier: (row['supplier'] as String? ?? ''),
    );
  }
}
