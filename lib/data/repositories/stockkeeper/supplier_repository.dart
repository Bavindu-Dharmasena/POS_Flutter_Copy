import 'package:sqflite/sqflite.dart';
import 'package:pos_system/data/db/database_helper.dart';
import 'package:pos_system/data/models/stockkeeper/supplier_model.dart' as model;
import 'package:pos_system/data/models/stockkeeper/supplier_db_maps.dart';

class SupplierRepository {
  SupplierRepository._();
  static final SupplierRepository instance = SupplierRepository._();

  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<model.Supplier> create(model.Supplier supplier) async {
    final db = await _db;
    final id = await db.insert(
      'supplier',
      supplier.toInsertMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return supplier.copyWith(id: id);
  }

  Future<int> update(model.Supplier supplier) async {
    if (supplier.id == null) {
      throw ArgumentError('Supplier id is required for update');
    }
    final db = await _db;
    return db.update(
      'supplier',
      supplier.toUpdateMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete('supplier', where: 'id = ?', whereArgs: [id]);
  }

  Future<model.Supplier?> findById(int id) async {
    final db = await _db;
    final rows = await db.query('supplier', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return model.Supplier.fromMap(rows.first);
  }

  Future<List<model.Supplier>> all({String? query, int? limit, int? offset}) async {
    final db = await _db;

    String? where;
    List<Object?>? whereArgs;

    if ((query ?? '').trim().isNotEmpty) {
      final q = '%${query!.trim()}%';
      where = '(name LIKE ? COLLATE NOCASE'
          ' OR contact LIKE ? COLLATE NOCASE'
          ' OR brand LIKE ? COLLATE NOCASE'
          ' OR location LIKE ? COLLATE NOCASE)';
      whereArgs = [q, q, q, q];
    }

    final rows = await db.query(
      'supplier',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'updated_at DESC, id DESC',
      limit: limit,
      offset: offset,
    );

    return rows.map((r) => model.Supplier.fromMap(r)).toList();
  }

  Future<List<model.Supplier>> getAll({String? q}) => all(query: q);
}
