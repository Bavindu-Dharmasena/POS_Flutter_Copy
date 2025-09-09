import 'package:sqflite/sqflite.dart';
import 'package:pos_system/data/db/database_helper.dart';
import 'package:pos_system/data/models/stockkeeper/item_scan_model.dart';

class ItemLookupRepository {
  final Future<Database> _db = DatabaseHelper.instance.database;

  /// Find an item by barcode OR numeric item id.
  Future<ItemScanModel?> findByBarcodeOrId(String code) async {
    final db = await _db;
    final trimmed = code.trim();
    final id = int.tryParse(trimmed) ?? -1;

    final rows = await db.rawQuery('''
      SELECT 
        i.id,
        i.name,
        i.barcode,
        i.reorder_level,
        COALESCE(c.category, '')           AS category,
        COALESCE(s.name, '')               AS supplier,
        COALESCE(SUM(st.quantity), 0)      AS current_stock,
        COALESCE(MAX(st.sell_price), 0.0)  AS price
      FROM item i
      LEFT JOIN category c ON c.id = i.category_id
      LEFT JOIN supplier s ON s.id = i.supplier_id
      LEFT JOIN stock st   ON st.item_id = i.id
      WHERE i.barcode = ? OR i.id = ?
      GROUP BY i.id, i.name, i.barcode, i.reorder_level, c.category, s.name
      LIMIT 1
    ''', [trimmed, id]);

    if (rows.isEmpty) return null;
    return ItemScanModel.fromMap(rows.first);
  }
}
