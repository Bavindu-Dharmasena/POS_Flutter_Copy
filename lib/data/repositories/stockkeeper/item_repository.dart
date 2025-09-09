// lib/data/repositories/stockkeeper/item_repository.dart

import 'package:sqflite/sqflite.dart';

import '../../db/database_helper.dart';
import '../../models/stockkeeper/category_model.dart';
import '../../models/stockkeeper/item_model.dart';
import '../../models/stockkeeper/supplier_model.dart';

class ItemRepository {
  ItemRepository._();
  static final ItemRepository instance = ItemRepository._();

  Future<Database> get _db async => DatabaseHelper.instance.database;

  // ---------- Lookups ----------

  Future<List<CategoryModel>> fetchCategories() async {
    final db = await _db;
    final rows = await db.query(
      'category',
      orderBy: 'category COLLATE NOCASE ASC',
    );
    return rows.map((e) => CategoryModel.fromMap(e)).toList();
  }

  Future<List<SupplierModel>> fetchSuppliers() async {
    final db = await _db;
    final rows = await db.query(
      'supplier',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map((e) => SupplierModel.fromMap(e)).toList();
  }

  // ---------- Items CRUD ----------

  /// Check if a barcode already exists (for uniqueness validation).
  Future<bool> barcodeExists(String barcode) async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM item WHERE barcode = ?',
            [barcode],
          ),
        ) ??
        0;
    return count > 0;
  }

  /// Inserts an item and returns the new row id.
  Future<int> insertItem(ItemModel item) async {
    final db = await _db;
    return db.insert(
      'item',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort, // barcode is UNIQUE
    );
  }

  /// Convenience: insert and return the full model with id set.
  Future<ItemModel> createItem(ItemModel item) async {
    final id = await insertItem(item);
    return item.copyWith(id: id);
  }

  Future<int> updateItem(ItemModel item) async {
    if (item.id == null) {
      throw ArgumentError('Item id is required to update');
    }
    final db = await _db;
    return db.update(
      'item',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await _db;
    return db.delete('item', where: 'id = ?', whereArgs: [id]);
  }

  /// Get all raw items (no joins)
  Future<List<ItemModel>> getAllItems() async {
    final db = await _db;
    final rows = await db.query('item', orderBy: 'name COLLATE NOCASE ASC');
    return rows.map((e) => ItemModel.fromMap(e)).toList();
  }

  // ---------- Inventory / Aggregates ----------

  /// One row per item with: id, name, barcode, category_name, supplier_name,
  /// min_stock, current_stock (sum of stock), unit_sell_price (latest).
  Future<List<Map<String, Object?>>> fetchItemsForInventory() async {
    final db = await _db;

    final rows = await db.rawQuery('''
      SELECT
        i.id,
        i.name,
        i.barcode,
        c.category  AS category_name,
        s.name      AS supplier_name,
        i.reorder_level AS min_stock,

        -- total quantity across all batches
        COALESCE((
          SELECT SUM(st.quantity)
          FROM stock st
          WHERE st.item_id = i.id
        ), 0) AS current_stock,

        -- most recent sell price
        COALESCE((
          SELECT st2.sell_price
          FROM stock st2
          WHERE st2.item_id = i.id
          ORDER BY st2.id DESC
          LIMIT 1
        ), 0) AS unit_sell_price

      FROM item i
      JOIN category c ON c.id = i.category_id
      JOIN supplier s ON s.id = i.supplier_id
      ORDER BY i.name COLLATE NOCASE ASC
    ''');

    return rows;
  }

  /// 🔹 Tailored for the "Total Items" page/table.
  /// Returns: id, name, qty (sum of stock.quantity),
  /// unit_cost (latest stock.unit_price), sales_price (latest stock.sell_price)
  Future<List<Map<String, Object?>>> fetchItemsForTotals() async {
    final db = await _db;

    final rows = await db.rawQuery('''
      SELECT
        i.id,
        i.name,

        -- Total qty across all batches
        COALESCE((
          SELECT SUM(st.quantity)
          FROM stock st
          WHERE st.item_id = i.id
        ), 0) AS qty,

        -- Latest unit cost (purchase)
        COALESCE((
          SELECT st2.unit_price
          FROM stock st2
          WHERE st2.item_id = i.id
          ORDER BY st2.id DESC
          LIMIT 1
        ), 0.0) AS unit_cost,

        -- Latest sales price
        COALESCE((
          SELECT st3.sell_price
          FROM stock st3
          WHERE st3.item_id = i.id
          ORDER BY st3.id DESC
          LIMIT 1
        ), 0.0) AS sales_price

      FROM item i
      ORDER BY i.name COLLATE NOCASE ASC
    ''');

    return rows;
  }
}
