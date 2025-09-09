// lib/data/repositories/stockkeeper/Supplier_repository.dart
import 'package:sqflite/sqflite.dart';

// 👇 Adjust this path if your DatabaseHelper is elsewhere
import 'package:pos_system/data/db/database_helper.dart';

import 'package:pos_system/data/models/stockkeeper/Supplier.dart';

class SupplierRepository {
  SupplierRepository._internal();
  static final SupplierRepository instance = SupplierRepository._internal();

  static const _table = 'supplier';

  Future<Database> get _db async => DatabaseHelper.instance.database;

  // -------- READ (used by your screen) --------
  Future<List<Supplier>> all({String? query}) => getAll(q: query);

  Future<List<Supplier>> getAll({String? q}) async {
    final db = await _db;

    if (q != null && q.trim().isNotEmpty) {
      final like = '%${q.trim().toLowerCase()}%';
      final rows = await db.query(
        _table,
        where: 'LOWER(name) LIKE ? OR LOWER(contact) LIKE ? OR LOWER(brand) LIKE ? OR LOWER(location) LIKE ?',
        whereArgs: [like, like, like, like],
        orderBy: 'updated_at DESC',
      );
      return rows.map(Supplier.fromMap).toList();
    } else {
      final rows = await db.query(_table, orderBy: 'updated_at DESC');
      return rows.map(Supplier.fromMap).toList();
    }
  }

  // -------- (Optional) other CRUD you may already have --------
  Future<Supplier> create(Supplier supplier) async {
    final db = await _db;
    final id = await db.insert(
      _table,
      supplier.toMap(forInsert: true),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return supplier.copyWith(id: id);
  }

  Future<int> update(Supplier supplier) async {
    if (supplier.id == null) {
      throw ArgumentError('Supplier.id is required for update');
    }
    final db = await _db;
    return db.update(
      _table,
      supplier.toMap(forInsert: false),
      where: 'id = ?',
      whereArgs: [supplier.id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<Supplier?> findById(int id) async {
    final db = await _db;
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Supplier.fromMap(rows.first);
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
