class ItemModel {
  final int? id;
  final String name;
  final String barcode;      // UNIQUE
  final int categoryId;
  final int supplierId;
  final int reorderLevel;
  final String? gradient;
  final String? remark;
  final String colorCode;    // #RRGGBB

  const ItemModel({
    this.id,
    required this.name,
    required this.barcode,
    required this.categoryId,
    required this.supplierId,
    required this.reorderLevel,
    this.gradient,
    this.remark,
    required this.colorCode,
  });

  factory ItemModel.fromMap(Map<String, Object?> m) => ItemModel(
        id: m['id'] as int?,
        name: m['name'] as String,
        barcode: m['barcode'] as String,
        categoryId: m['category_id'] as int,
        supplierId: m['supplier_id'] as int,
        reorderLevel: m['reorder_level'] as int,
        gradient: m['gradient'] as String?,
        remark: m['remark'] as String?,
        colorCode: m['color_code'] as String,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'barcode': barcode,
        'category_id': categoryId,
        'supplier_id': supplierId,
        'reorder_level': reorderLevel,
        'gradient': gradient,
        'remark': remark,
        'color_code': colorCode,
      };
}
