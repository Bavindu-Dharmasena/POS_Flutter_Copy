class CategoryModel {
  final int? id;
  final String category;      // DB column: category
  final String colorCode;     // e.g. #FF5733
  final String? categoryImage;

  const CategoryModel({
    this.id,
    required this.category,
    required this.colorCode,
    this.categoryImage,
  });

  factory CategoryModel.fromMap(Map<String, Object?> m) => CategoryModel(
        id: m['id'] as int?,
        category: m['category'] as String,
        colorCode: m['color_code'] as String,
        categoryImage: m['category_image'] as String?,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'category': category,
        'color_code': colorCode,
        'category_image': categoryImage,
      };
}
