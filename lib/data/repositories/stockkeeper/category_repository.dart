import 'package:pos_system/data/db/database_helper.dart';
import 'package:pos_system/data/models/stockkeeper/add_category_model.dart';
import 'package:sqflite/sqflite.dart';



class CategoryRepository {
  CategoryRepository._internal();
  static final CategoryRepository instance = CategoryRepository._internal();

  static const String _tableName = 'category';

  // Get database instance
  Future<Database> get _database async => DatabaseHelper.instance.database;

  // Create a new category
  Future<int> createCategory(Category category) async {
    try {
      final db = await _database;
      
      // Check if category name already exists
      final existingCategory = await getCategoryByName(category.category);
      if (existingCategory != null) {
        throw Exception('Category "${category.category}" already exists');
      }

      return await db.insert(
        _tableName,
        category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  // Get all categories
  Future<List<Category>> getAllCategories() async {
    try {
      final db = await _database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'category ASC',
      );
      
      return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  // Get category by ID
  Future<Category?> getCategoryById(int id) async {
    try {
      final db = await _database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return Category.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get category: $e');
    }
  }

  // Get category by name
  Future<Category?> getCategoryByName(String name) async {
    try {
      final db = await _database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'LOWER(category) = LOWER(?)',
        whereArgs: [name.trim()],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return Category.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get category by name: $e');
    }
  }

  // Update category
  Future<int> updateCategory(Category category) async {
    try {
      if (category.id == null) {
        throw Exception('Category ID cannot be null for update');
      }

      final db = await _database;
      
      // Check if another category with the same name exists (excluding current)
      final existingCategory = await getCategoryByName(category.category);
      if (existingCategory != null && existingCategory.id != category.id) {
        throw Exception('Category "${category.category}" already exists');
      }

      return await db.update(
        _tableName,
        category.toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  // Delete category
  Future<int> deleteCategory(int id) async {
    try {
      final db = await _database;
      
      // Check if category is being used by any items
      final itemCount = await _getCategoryUsageCount(id);
      if (itemCount > 0) {
        throw Exception('Cannot delete category: $itemCount items are using this category');
      }

      return await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  // Check how many items are using this category
  Future<int> _getCategoryUsageCount(int categoryId) async {
    try {
      final db = await _database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM item WHERE category_id = ?',
        [categoryId],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Get categories for dropdown (id and name only)
  Future<List<Map<String, dynamic>>> getCategoriesForDropdown() async {
    try {
      final db = await _database;
      return await db.query(
        _tableName,
        columns: ['id', 'category', 'color_code'],
        orderBy: 'category ASC',
      );
    } catch (e) {
      throw Exception('Failed to get categories for dropdown: $e');
    }
  }

  // Search categories by name
  Future<List<Category>> searchCategories(String searchTerm) async {
    try {
      final db = await _database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'category LIKE ?',
        whereArgs: ['%$searchTerm%'],
        orderBy: 'category ASC',
      );
      
      return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to search categories: $e');
    }
  }

  // Get category count
  Future<int> getCategoryCount() async {
    try {
      final db = await _database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Batch operations
  Future<void> createMultipleCategories(List<Category> categories) async {
    final db = await _database;
    await db.transaction((txn) async {
      for (final category in categories) {
        await txn.insert(
          _tableName,
          category.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
    });
  }
}