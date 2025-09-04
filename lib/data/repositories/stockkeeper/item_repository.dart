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
    final rows = await db.query('category', orderBy: 'category ASC');
    return rows.map(CategoryModel.fromMap).toList();
  }

  Future<List<SupplierModel>> fetchSuppliers() async {
    final db = await _db;
    final rows = await db.query('supplier', columns: ['id', 'name'], orderBy: 'name ASC');
    return rows.map(SupplierModel.fromMap).toList();
  }

  Future<bool> barcodeExists(String barcode) async {
    final db = await _db;
    final rows = await db.query('item',
        columns: ['id'], where: 'barcode = ?', whereArgs: [barcode], limit: 1);
    return rows.isNotEmpty;
  }

  // ---------- Mutations ----------
  Future<int> insertItem(ItemModel item) async {
    final db = await _db;
    return await db.insert('item', item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  // (Optional) update/delete if you need later:
  Future<int> updateItem(ItemModel item) async {
    if (item.id == null) throw ArgumentError('Item id is required to update');
    final db = await _db;
    return db.update('item', item.toMap(),
        where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> deleteItem(int id) async {
    final db = await _db;
    return db.delete('item', where: 'id = ?', whereArgs: [id]);
  }
}
