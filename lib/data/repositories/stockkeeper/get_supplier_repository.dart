import 'package:sqflite/sqflite.dart';

// 👇 Adjust if your helper is in a different path.
import 'package:pos_system/data/db/database_helper.dart';

import '../../models/stockkeeper/supplier_model.dart';

class SupplierRepository {
  SupplierRepository._();
  static final SupplierRepository instance = SupplierRepository._();

  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<SupplierModel> create(SupplierModel supplier) async {
    final db = await _db;
    final id = await db.insert('supplier', supplier.toMap());
    return supplier.copyWith(id: id);
  }

  Future<List<SupplierModel>> all({String? query}) async {
    final db = await _db;
    List<Map<String, Object?>> rows;
    if (query != null && query.trim().isNotEmpty) {
      final q = '%${query.trim()}%';
      rows = await db.query(
        'supplier',
        where: 'name LIKE ? OR contact LIKE ? OR brand LIKE ? OR location LIKE ?',
        whereArgs: [q, q, q, q],
        orderBy: 'updated_at DESC',
      );
    } else {
      rows = await db.query('supplier', orderBy: 'updated_at DESC');
    }
    return rows.map(SupplierModel.fromMap).toList();
  }

  Future<SupplierModel?> findById(int id) async {
    final db = await _db;
    final r = await db.query('supplier', where: 'id = ?', whereArgs: [id], limit: 1);
    if (r.isEmpty) return null;
    return SupplierModel.fromMap(r.first);
  }

  Future<int> update(SupplierModel supplier) async {
    if (supplier.id == null) return 0;
    final db = await _db;
    return db.update(
      'supplier',
      supplier.toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete('supplier', where: 'id = ?', whereArgs: [id]);
  }
}
