class SupplierModel {
  final int? id;
  final String name;

  const SupplierModel({this.id, required this.name});

  factory SupplierModel.fromMap(Map<String, Object?> m) => SupplierModel(
        id: m['id'] as int?,
        name: m['name'] as String,
      );
}
