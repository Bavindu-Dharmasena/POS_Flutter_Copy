import 'package:sqflite/sqflite.dart';
import 'package:pos_system/data/models/stockkeeper/restock/item_scan_model.dart';
import 'package:pos_system/data/db/database_helper.dart';

class ItemLookupRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<ItemScanModel?> findByBarcodeOrId(String code) async {
    final db = await _dbHelper.database;

    int? asId;
    try { asId = int.parse(code); } catch (_) { asId = null; }

    final res = await db.rawQuery('''
      SELECT
        i.id                  AS id,
        i.name                AS name,
        i.barcode             AS barcode,
        i.reorder_level       AS reorder_level,
        c.category            AS category,
        s.name                AS supplier,
        IFNULL((SELECT SUM(st.quantity) FROM stock st WHERE st.item_id = i.id), 0) AS current_stock,
        IFNULL((
          SELECT st.sell_price
          FROM stock st
          WHERE st.item_id = i.id
          ORDER BY st.id DESC
          LIMIT 1
        ), 0.0)               AS price
      FROM item i
      JOIN category c ON c.id = i.category_id
      JOIN supplier s ON s.id = i.supplier_id
      WHERE i.barcode = ? OR i.id = ?
      LIMIT 1
    ''', [code, asId ?? -1]);

    if (res.isEmpty) return null;
    return ItemScanModel.fromRow(res.first);
  }
}
