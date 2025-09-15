// lib/data/models/stockkeeper/supplier_request_model.dart

/// Header + detail aggregate for a supplier request.
class SupplierRequestRecord {
  final int id;
  final int supplierId;
  final String supplierName;
  final int createdAt; // epoch ms
  final String status;
  final List<SupplierRequestLine> items;

  SupplierRequestRecord({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.createdAt,
    required this.status,
    this.items = const [],
  });

  String get displayId => 'REQ-${id.toString().padLeft(4, '0')}';
  DateTime get createdAtDt => DateTime.fromMillisecondsSinceEpoch(createdAt);

  SupplierRequestRecord copyWith({List<SupplierRequestLine>? items}) {
    return SupplierRequestRecord(
      id: id,
      supplierId: supplierId,
      supplierName: supplierName,
      createdAt: createdAt,
      status: status,
      items: items ?? this.items,
    );
  }

  /// Map a *header* row (no lines) to the model.
  static SupplierRequestRecord fromHeaderMap(Map<String, Object?> m) {
    return SupplierRequestRecord(
      id: (m['id'] as num).toInt(),
      supplierId: (m['supplier_id'] as num).toInt(),
      supplierName: (m['supplier_name'] as String?) ?? 'Supplier',
      createdAt: (m['created_at'] as num).toInt(),
      status: (m['status'] as String?) ?? 'PENDING',
    );
  }
}

/// One line (item) inside a supplier request.
class SupplierRequestLine {
  final int id;
  final int itemId;
  final String itemName;
  final int currentStock;      // computed at read-time
  final int requestedAmount;   // "Req. amount" column in UI
  final int quantity;          // editable "Quantity" column
  final double unitPrice;
  final double salePrice;

  SupplierRequestLine({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.currentStock,
    required this.requestedAmount,
    required this.quantity,
    required this.unitPrice,
    required this.salePrice,
  });

  factory SupplierRequestLine.fromMap(Map<String, Object?> m) {
    return SupplierRequestLine(
      id: (m['id'] as num).toInt(),
      itemId: (m['item_id'] as num).toInt(),
      itemName: (m['item_name'] as String?) ?? 'Item',
      currentStock: (m['current_stock'] as num?)?.toInt() ?? 0,
      requestedAmount: (m['requested_amount'] as num?)?.toInt() ?? 0,
      quantity: (m['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (m['unit_price'] as num?)?.toDouble() ?? 0,
      salePrice: (m['sale_price'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Helper for creation API (keeps your existing repo signature)
class CreateSupplierRequestLine {
  final int itemId;
  final int requestedAmount;
  final int quantity;
  final double unitPrice;
  final double salePrice;

  const CreateSupplierRequestLine({
    required this.itemId,
    required this.requestedAmount,
    required this.quantity,
    required this.unitPrice,
    required this.salePrice,
  });

  Map<String, Object?> toInsertMap(int requestId) => {
        'request_id': requestId,
        'item_id': itemId,
        'requested_amount': requestedAmount,
        'quantity': quantity,
        'unit_price': unitPrice,
        'sale_price': salePrice,
      };
}
