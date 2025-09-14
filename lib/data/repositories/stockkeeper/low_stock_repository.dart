import 'package:sqflite/sqflite.dart';
import 'package:pos_system/data/db/database_helper.dart';
import 'package:pos_system/data/models/stockkeeper/low_stock_models.dart';

/// UI product used by low_stock.dart
class LowStockProduct {
  final int id;            // item.id
  final String name;       // item.name
  final String category;   // derived — optional, keep empty if you don’t join category table
  final int currentStock;  // SUM(stock.quantity)
  final int minStock;      // item.reorder_level
  final int maxStock;      // derived: reorder_level * 5 (fallback)
  final double price;      // latest stock.sell_price (fallback 0)
  final String supplier;   // supplier.name

  const LowStockProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.minStock,
    required this.maxStock,
    required this.price,
    required this.supplier,
  });

  bool get isLowStock => currentStock > 0 && currentStock <= minStock;
}

/// Repository for Low Stock page
class LowStockRepository {
  LowStockRepository._();
  static final LowStockRepository instance = LowStockRepository._();

  Future<Database> get _db => DatabaseHelper.instance.database;

  /// Returns only low-stock rows (currentStock > 0 && <= reorder_level).
  /// Pass [search] to filter by item/category names and [supplierName] to filter by supplier.
  Future<List<LowStockProduct>> fetchLowStock({
    String? search,
    String? supplierName,
  }) async {
    final db = await _db;

    final like = (search ?? '').trim();
    final hasSearch = like.isNotEmpty;
    final hasSupp = (supplierName ?? '').trim().isNotEmpty && supplierName != 'All';

    // Using scalar subqueries to get latest prices for each item.
    final rows = await db.rawQuery('''
      SELECT
        i.id                     AS item_id,
        i.name                   AS item_name,
        i.reorder_level          AS min_stock,
        COALESCE(SUM(st.quantity), 0) AS current_stock,
        s.name                   AS supplier_name,
        -- latest prices
        COALESCE((
          SELECT st2.sell_price FROM stock st2
          WHERE st2.item_id = i.id
          ORDER BY st2.id DESC LIMIT 1
        ), 0) AS sell_price
      FROM item i
      JOIN supplier s ON s.id = i.supplier_id
      LEFT JOIN stock st ON st.item_id = i.id
      WHERE
        (${hasSearch ? 'i.name LIKE ?' : '1=1'})
        AND (${hasSupp ? 's.name = ?' : '1=1'})
      GROUP BY i.id
      HAVING current_stock > 0 AND current_stock <= i.reorder_level
      ORDER BY i.name COLLATE NOCASE;
    ''', [
      if (hasSearch) '%$like%',
      if (hasSupp) supplierName,
    ]);

    // Map to UI model
    return rows.map((r) {
      final min = (r['min_stock'] as int?) ?? 0;
      final max = (min * 5); // simple derived max
      return LowStockProduct(
        id: (r['item_id'] as int),
        name: (r['item_name'] as String? ?? ''),
        category: '', // not joined here; add if you want
        currentStock: (r['current_stock'] as int?) ?? 0,
        minStock: min,
        maxStock: max,
        price: (r['sell_price'] as num?)?.toDouble() ?? 0,
        supplier: (r['supplier_name'] as String? ?? ''),
      );
    }).toList();
  }

  /// Creates supplier requests grouped by supplier.
  /// For each item in [selections], we:
  ///   - discover its supplier_id
  ///   - get latest unit/sale prices (fallback 0)
  ///   - insert header row into supplier_request (per supplier)
  ///   - insert line rows into supplier_request_item
  ///
  /// Returns map {supplierId: requestId}.
  Future<Map<int, int>> createRequestsFromSelections(
    List<LowStockSelection> selections,
  ) async {
    if (selections.isEmpty) return {};

    final db = await _db;

    // Lookup supplier + latest prices for all selected items
    final itemIds = selections.map((e) => e.itemId).toList();
    final placeholders = List.filled(itemIds.length, '?').join(',');
    final metaRows = await db.rawQuery('''
      SELECT
        i.id            AS item_id,
        i.supplier_id   AS supplier_id,
        COALESCE((
          SELECT st2.unit_price FROM stock st2
          WHERE st2.item_id = i.id
          ORDER BY st2.id DESC LIMIT 1
        ), 0) AS unit_price,
        COALESCE((
          SELECT st3.sell_price FROM stock st3
          WHERE st3.item_id = i.id
          ORDER BY st3.id DESC LIMIT 1
        ), 0) AS sell_price
      FROM item i
      WHERE i.id IN ($placeholders);
    ''', itemIds);

    // Build quick lookup
    final metaByItemId = {
      for (final r in metaRows) (r['item_id'] as int): _ItemMeta(
        supplierId: (r['supplier_id'] as int),
        unitPrice: (r['unit_price'] as num?)?.toDouble() ?? 0,
        salePrice: (r['sell_price'] as num?)?.toDouble() ?? 0,
      )
    };

    final now = DateTime.now().millisecondsSinceEpoch;
    final requestIds = <int, int>{}; // supplierId -> requestId

    await db.transaction((tx) async {
      // group selections by supplier
      final grouped = <int, List<LowStockSelection>>{};
      for (final sel in selections) {
        final meta = metaByItemId[sel.itemId];
        if (meta == null) continue; // item might have been deleted
        grouped.putIfAbsent(meta.supplierId, () => []).add(sel);
      }

      for (final entry in grouped.entries) {
        final supplierId = entry.key;
        final items = entry.value;

        // create header
        final requestId = await tx.insert('supplier_request', {
          'supplier_id': supplierId,
          'created_at': now,
          'status': 'PENDING',
        });
        requestIds[supplierId] = requestId;

        // insert lines
        for (final sel in items) {
          final meta = metaByItemId[sel.itemId]!;
          await tx.insert('supplier_request_item', {
            'request_id': requestId,
            'item_id': sel.itemId,
            'requested_amount': sel.quantity, // using typed qty for both
            'quantity': sel.quantity,
            'unit_price': meta.unitPrice,
            'sale_price': meta.salePrice,
          });
        }
      }
    });

    return requestIds;
  }
}

class _ItemMeta {
  final int supplierId;
  final double unitPrice;
  final double salePrice;
  _ItemMeta({required this.supplierId, required this.unitPrice, required this.salePrice});
}
