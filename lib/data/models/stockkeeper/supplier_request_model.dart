import 'package:flutter/foundation.dart';

@immutable
class SupplierRequestLine {
  final int id;                 // row id in supplier_request_item
  final int itemId;
  final String itemName;        // joined from item.name
  final int currentStock;       // computed from stock table
  final int requestedAmount;    // asked from supplier
  final int quantity;           // editable qty (your UI edits this)
  final double unitPrice;
  final double salePrice;

  const SupplierRequestLine({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.currentStock,
    required this.requestedAmount,
    required this.quantity,
    required this.unitPrice,
    required this.salePrice,
  });

  SupplierRequestLine copyWith({
    int? id,
    int? itemId,
    String? itemName,
    int? currentStock,
    int? requestedAmount,
    int? quantity,
    double? unitPrice,
    double? salePrice,
  }) {
    return SupplierRequestLine(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      currentStock: currentStock ?? this.currentStock,
      requestedAmount: requestedAmount ?? this.requestedAmount,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      salePrice: salePrice ?? this.salePrice,
    );
  }
}

@immutable
class SupplierRequestRecord {
  final int id;                 // numeric DB id
  final int supplierId;
  final String supplierName;    // joined from supplier.name
  final int createdAt;          // ms since epoch
  final String status;          // PENDING | ACCEPTED | REJECTED | RESENT
  final List<SupplierRequestLine> items;

  const SupplierRequestRecord({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.createdAt,
    required this.status,
    required this.items,
  });

  String get displayId => 'REQ-${id.toString().padLeft(4, '0')}';
  DateTime get createdAtDt => DateTime.fromMillisecondsSinceEpoch(createdAt);

  SupplierRequestRecord copyWith({
    int? id,
    int? supplierId,
    String? supplierName,
    int? createdAt,
    String? status,
    List<SupplierRequestLine>? items,
  }) {
    return SupplierRequestRecord(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      items: items ?? this.items,
    );
  }
}

/// Simple DTO for creating lines
@immutable
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
