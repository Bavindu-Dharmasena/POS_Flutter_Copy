class Category {
  final int? id;
  final String category;
  final String colorCode;
  final String? categoryImage;

  Category({
    this.id,
    required this.category,
    required this.colorCode,
    this.categoryImage,
  });

  // Convert a Category object to a Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'color_code': colorCode,
      'category_image': categoryImage,
    };
  }

  // Create a Category from a Map (from SQLite)
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id']?.toInt(),
      category: map['category'] ?? '',
      colorCode: map['color_code'] ?? '#3B82F6',
      categoryImage: map['category_image'],
    );
  }

  // Create a copy of Category with updated fields
  Category copyWith({
    int? id,
    String? category,
    String? colorCode,
    String? categoryImage,
  }) {
    return Category(
      id: id ?? this.id,
      category: category ?? this.category,
      colorCode: colorCode ?? this.colorCode,
      categoryImage: categoryImage ?? this.categoryImage,
    );
  }

  @override
  String toString() {
    return 'Category{id: $id, category: $category, colorCode: $colorCode, categoryImage: $categoryImage}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category &&
        other.id == id &&
        other.category == category &&
        other.colorCode == colorCode &&
        other.categoryImage == categoryImage;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        category.hashCode ^
        colorCode.hashCode ^
        categoryImage.hashCode;
  }
}