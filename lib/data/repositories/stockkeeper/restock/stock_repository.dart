import 'package:sqflite/sqflite.dart';
import 'package:pos_system/data/db/database_helper.dart';

class StockUpdateInput {
  final int itemId;
  final String batchId;
  final int quantityToAdd;
  final double unitPrice;
  final double sellPrice;
  final double discountAmount;

  const StockUpdateInput({
    required this.itemId,
    required this.batchId,
    required this.quantityToAdd,
    required this.unitPrice,
    required this.sellPrice,
    required this.discountAmount,
  });
}

class StockRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> applyRestockEntries(List<StockUpdateInput> entries) async {
    if (entries.isEmpty) return;
    final db = await _dbHelper.database;

    await db.transaction((tx) async {
      for (final e in entries) {
        final existing = await tx.query(
          'stock',
          where: 'item_id = ? AND batch_id = ?',
          whereArgs: [e.itemId, e.batchId],
          limit: 1,
        );

        if (existing.isNotEmpty) {
          final row = existing.first;
          final stockId = row['id'] as int;
          final prevQty = (row['quantity'] as int?) ?? 0;
          final newQty = prevQty + e.quantityToAdd;

          await tx.update(
            'stock',
            {
              'quantity': newQty,
              'unit_price': e.unitPrice,
              'sell_price': e.sellPrice,
              'discount_amount': e.discountAmount,
            },
            where: 'id = ?',
            whereArgs: [stockId],
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        } else {
          final itemRows = await tx.query(
            'item',
            columns: ['supplier_id'],
            where: 'id = ?',
            whereArgs: [e.itemId],
            limit: 1,
          );
          if (itemRows.isEmpty) {
            throw StateError('Item ${e.itemId} not found');
          }
          final supplierId = itemRows.first['supplier_id'] as int;

          await tx.insert(
            'stock',
            {
              'batch_id': e.batchId,
              'item_id': e.itemId,
              'quantity': e.quantityToAdd,
              'unit_price': e.unitPrice,
              'sell_price': e.sellPrice,
              'discount_amount': e.discountAmount,
              'supplier_id': supplierId,
            },
            conflictAlgorithm: ConflictAlgorithm.abort, // UNIQUE(batch_id,item_id)
          );
        }
      }
    });
  }

  // Optional helpers when debugging:
  Future<int> getTotalQuantityForItem(int itemId) async {
    final db = await _dbHelper.database;
    final res = await db.rawQuery(
      'SELECT IFNULL(SUM(quantity),0) AS total_qty FROM stock WHERE item_id = ?',
      [itemId],
    );
    final v = res.first['total_qty'];
    return (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
  }

  Future<Map<String, Object?>?> getLatestStockForItem(int itemId) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      'stock',
      where: 'item_id = ?',
      whereArgs: [itemId],
      orderBy: 'id DESC',
      limit: 1,
    );
    return res.isEmpty ? null : res.first;
  }
}
