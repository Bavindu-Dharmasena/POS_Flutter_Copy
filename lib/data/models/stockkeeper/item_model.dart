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

  // ✅ Needed by your repository (create -> copyWith(id))
  ItemModel copyWith({
    int? id,
    String? name,
    String? barcode,
    int? categoryId,
    int? supplierId,
    int? reorderLevel,
    String? gradient,
    String? remark,
    String? colorCode,
  }) {
    return ItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      supplierId: supplierId ?? this.supplierId,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      gradient: gradient ?? this.gradient,
      remark: remark ?? this.remark,
      colorCode: colorCode ?? this.colorCode,
    );
  }

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
