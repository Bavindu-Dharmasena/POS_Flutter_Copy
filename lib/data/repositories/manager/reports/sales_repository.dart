import 'package:sqflite/sqflite.dart';

import 'package:pos_system/data/db/database_helper.dart';
import 'package:pos_system/data/models/manager/reports/sales_record.dart';

class SalesRepository {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  /// Fetch orders (each payment row represents one sale).
  /// [from] inclusive, [to] exclusive.
  Future<List<SalesRecord>> fetch(
    DateTime from,
    DateTime to, {
    String? query,
  }) async {
    final db = await _db;

    // Optional search by sale_invoice_id (order id)
    final where = StringBuffer('pay.date >= ? AND pay.date < ?');
    final args = <Object>[
      from.millisecondsSinceEpoch,
      to.millisecondsSinceEpoch,
    ];

    if (query != null && query.trim().isNotEmpty) {
      where.write(' AND pay.sale_invoice_id LIKE ?');
      args.add('%${query.trim()}%');
    }

    final rows = await db.rawQuery('''
      SELECT
        pay.sale_invoice_id AS order_id,
        pay.date            AS date,             -- epoch ms
        COALESCE(u.name,'Main Store') AS store,  -- use user name as "store"
        pay.type            AS payment_method,
        pay.amount          AS amount
      FROM payment pay
      LEFT JOIN user u ON u.id = pay.user_id
      WHERE $where
      ORDER BY pay.date ASC
    ''', args);

    return rows.map((r) => SalesRecord.fromRow(r)).toList();
  }

  /// Useful extras if you want them later:
  Future<double> totalRevenue(DateTime from, DateTime to) async {
    final db = await _db;
    final rs = await db.rawQuery(
      'SELECT IFNULL(SUM(amount),0) AS t FROM payment WHERE date >= ? AND date < ?',
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    final n = rs.first['t'] as num? ?? 0;
    return n.toDouble();
  }

  Future<int> orderCount(DateTime from, DateTime to) async {
    final db = await _db;
    final rs = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM payment WHERE date >= ? AND date < ?',
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    return (rs.first['c'] as num? ?? 0).toInt();
  }
}
