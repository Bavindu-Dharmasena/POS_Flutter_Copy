import '../../db/database_helper.dart';
import '../../models/cashier/cashier.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

class CashierRepository {
  final _table = 'todos';

  Future<List<Map<String, dynamic>>> getCategoriesWithItemsAndBatches() async {
    final db = await DatabaseHelper.instance.database;

    // Flat query (joins category, item, stock) with quantity > 0
    final res = await db.rawQuery('''
    SELECT
      c.id          AS category_id,
      c.category    AS category,
      c.color_code  AS categoryColor,
      c.category_image,
      i.id          AS item_id,
      i.barcode     AS itemcode,
      i.name        AS itemName,
      i.color_code  AS itemColor,
      s.batch_id    AS batchID,
      s.unit_price  AS pprice,
      s.sell_price  AS price,
      s.quantity,
      s.discount_amount
    FROM category c
    JOIN item i ON i.category_id = c.id
    JOIN stock s ON s.item_id = i.id
    WHERE s.quantity > 0
    ORDER BY c.id, i.id, s.id
  ''');

    // Group into nested JSON
    final Map<int, Map<String, dynamic>> categoryMap = {};

    for (final row in res) {
      final catId = row['category_id'] as int;

      // Category
      categoryMap.putIfAbsent(
        catId,
        () => {
          'id': catId,
          'category': row['category'],
          'colorCode': row['categoryColor'],
          'categoryImage': row['category_image'],
          'items': <Map<String, dynamic>>[],
        },
      );

      // Safe cast
      final List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(
        categoryMap[catId]!['items'],
      );

      // Item
      final itemId = row['item_id'] as int;
      var item = items.firstWhere(
        (it) => it['id'] == itemId,
        orElse: () {
          final newItem = {
            'id': itemId,
            'itemcode': row['itemcode'],
            'name': row['itemName'],
            'colorCode': row['itemColor'],
            'batches': <Map<String, dynamic>>[],
          };
          items.add(newItem);
          return newItem;
        },
      );

      // Batch
      (item['batches'] as List<Map<String, dynamic>>).add({
        'batchID': row['batchID'],
        'pprice': row['pprice'],
        'price': row['price'],
        'quantity': row['quantity'],
        'discountAmount': row['discount_amount'],
      });

      // Save back updated items
      categoryMap[catId]!['items'] = items;
    }
    return categoryMap.values.toList();
  }

  Future<List<Map<String, dynamic>>> getAllPayments() async {
    final db = await DatabaseHelper.instance.database;

    // Query all rows in the payment table
    final List<Map<String, dynamic>> results = await db.query(
      'payment',
      orderBy: 'date DESC', // optional: newest first
    );

    return results;
  }

  // CashierRepository.insertPayment
  Future<int> insertPayment(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.instance.database;

    final int dateMillis = data['date'] is int
        ? data['date'] as int
        : DateTime.parse((data['date'] as String)).millisecondsSinceEpoch;

    final row = {
      'amount': (data['amount'] as num).toDouble(),
      'remain_amount': (data['remain_amount'] as num).toDouble(),
      'date': dateMillis,
      'file_name': data['file_name'] ?? data['fileName'],
      'type': data['type'],
      'sale_invoice_id': (data['sale_invoice_id'] ?? data['salesInvoiceId'])
          .toString(),
      'user_id': data['user_id'],
      'customer_contact': data['customer_contact'],
      'discount_type': data['discount_type'] ?? 'no',
      'discount_value': (data['discount_value'] as num?)?.toDouble() ?? 0.0,
    };

    // Keep abort if you want UNIQUE(sale_invoice_id) to throw on duplicates
    return db.insert(
      'payment',
      row,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // CashierRepository.insertInvoices
  Future<void> insertInvoices(Map<String, dynamic> payload) async {
    final db = await DatabaseHelper.instance.database;

    final String saleId =
        (payload['saleInvoiceId'] ?? payload['sale_invoice_id']).toString();
    final List invoices = (payload['invoices'] as List?) ?? const [];

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final inv in invoices) {
        final dynamic itemIdRaw = inv['itemId'] ?? inv['item_id'];
        final int? itemId = itemIdRaw is int
            ? itemIdRaw
            : int.tryParse('${itemIdRaw ?? ""}');
        if (itemId == null) continue;

        final int qty = inv['quantity'] is num
            ? (inv['quantity'] as num).toInt()
            : int.tryParse('${inv['quantity']}') ?? 0;
        final double finalUnitPrice = inv['unit_saled_price'];

        batch.insert('invoice', {
          'batch_id': (inv['batchId'] ?? inv['batch_id']).toString(),
          'item_id': itemId,
          'quantity': qty,
          'unit_saled_price': finalUnitPrice,
          'sale_invoice_id': saleId, // FK → payment(sale_invoice_id)
        }, conflictAlgorithm: ConflictAlgorithm.abort);
      }
      await batch.commit(noResult: true);
    });
  }

  /// Returns:
  /// [
  ///   { "sale_invoice_id": "...", "payment_amount": ..., "payment_remain_amount": ...,
  ///     "payment_type": "...", "payment_file_name": "...", "payment_date": 1234567890,
  ///     "payment_user_id": 2, "customer_contact": "..." },
  ///   { "invoice_id": ..., "batch_id": "...", "item_id": ..., "quantity": ...,
  ///     "item_name": "...", "item_barcode": "...", "unit_price": ...,
  ///     "sell_price": ..., "discount_amount": ..., "final_unit_price": ..., "line_total": ... },
  ///   ...
  /// ]
  Future<List<Map<String, dynamic>>> getSaleBundleList(
    String saleInvoiceId,
  ) async {
    final Database db = await DatabaseHelper.instance.database;

    // 1) Fetch payment header (parent)
    final List<Map<String, Object?>> pRows = await db.query(
      'payment',
      columns: [
        'sale_invoice_id',
        'amount',
        'remain_amount',
        'type',
        'file_name',
        'date',
        'user_id',
        'customer_contact',
        'discount_type',
        'discount_value',
      ],
      where: 'sale_invoice_id = ?',
      whereArgs: [saleInvoiceId],
      limit: 1,
    );

    if (pRows.isEmpty) {
      // No such sale_invoice_id
      return <Map<String, dynamic>>[];
    }

    final Map<String, Object?> p = pRows.first;

    // Build the header map as the first element
    final Map<String, dynamic> header = {
      "sale_invoice_id": p["sale_invoice_id"]?.toString(),
      "payment_amount": (p["amount"] as num?)?.toDouble() ?? 0.0,
      "payment_remain_amount": (p["remain_amount"] as num?)?.toDouble() ?? 0.0,
      "payment_type": p["type"]?.toString(),
      "payment_file_name": p["file_name"]?.toString(),
      "payment_date": p["date"] is int
          ? p["date"] as int
          : int.tryParse("${p["date"]}") ?? 0,
      "payment_user_id": p["user_id"] is int
          ? p["user_id"] as int
          : int.tryParse("${p["user_id"]}") ?? 0,
      "customer_contact": p["customer_contact"]?.toString(),
      "discount_type": p["discount_type"]?.toString() ?? 'no',
      "discount_value": (p["discount_value"] as num?)?.toDouble() ?? 0.0,
    };

    // 2) Fetch invoice lines (children) with joined details
    const String linesSql = '''
    SELECT
      inv.id                AS invoice_id,
      inv.batch_id          AS batch_id,
      inv.item_id           AS item_id,
      inv.quantity          AS quantity,
      inv.unit_saled_price   AS unit_saled_price,
      i.name                AS item_name,
      i.barcode             AS item_barcode,

      s.unit_price          AS unit_price,
      s.sell_price          AS sell_price,
      s.discount_amount     AS discount_amount,

      (COALESCE(s.sell_price, 0) - COALESCE(s.discount_amount, 0))                 AS final_unit_price,
      (COALESCE(s.sell_price, 0) - COALESCE(s.discount_amount, 0)) * inv.quantity  AS line_total
    FROM invoice AS inv
    LEFT JOIN item AS i
      ON i.id = inv.item_id
    LEFT JOIN stock AS s
      ON s.batch_id = inv.batch_id AND s.item_id = inv.item_id
    WHERE inv.sale_invoice_id = ?
    ORDER BY inv.id ASC;
  ''';

    final List<Map<String, Object?>> rows = await db.rawQuery(linesSql, [
      saleInvoiceId,
    ]);

    // Normalize numeric types to double/int as needed
    final List<Map<String, dynamic>> lineMaps = rows.map((r) {
      final qtyNum = r['quantity'] as num? ?? 0;
      return {
        "invoice_id": r["invoice_id"] is int
            ? r["invoice_id"] as int
            : int.tryParse("${r["invoice_id"]}") ?? 0,
        "batch_id": r["batch_id"]?.toString(),
        "item_id": r["item_id"] is int
            ? r["item_id"] as int
            : int.tryParse("${r["item_id"]}") ?? 0,
        "quantity": qtyNum.toInt(),
        "saled_unit_price": (r["unit_saled_price"] as num?)?.toDouble() ?? 0.0,

        "item_name": r["item_name"]?.toString(),
        "item_barcode": r["item_barcode"]?.toString(),

        "unit_price": (r["unit_price"] as num?)?.toDouble() ?? 0.0,
        "sell_price": (r["sell_price"] as num?)?.toDouble() ?? 0.0,
        "discount_amount": (r["discount_amount"] as num?)?.toDouble() ?? 0.0,

        "final_unit_price": (r["final_unit_price"] as num?)?.toDouble() ?? 0.0,
        "line_total": (r["line_total"] as num?)?.toDouble() ?? 0.0,
      };
    }).toList();

    // 3) Return: header first, then lines
    return <Map<String, dynamic>>[header, ...lineMaps];
  }

  Future<int> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> toggleDone(int id, bool isDone) async {
    final db = await DatabaseHelper.instance.database;
    return db.update(
      _table,
      {'is_done': isDone ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAll() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(_table);
  }
}

class StockApplyResult {
  final List<Map<String, dynamic>> updated;   // rows successfully deducted
  final List<Map<String, dynamic>> warnings;  // insufficient stock or bad input
  final List<Map<String, dynamic>> missing;   // no stock row found

  StockApplyResult({
    required this.updated,
    required this.warnings,
    required this.missing,
  });

  bool get allOk => warnings.isEmpty && missing.isEmpty;

  Map<String, dynamic> toJson() => {
    "updated": updated,
    "warnings": warnings,
    "missing": missing,
  };
}


Future<StockApplyResult> updateStockFromInvoicesPayload(
  Map<String, dynamic> payload, {
  bool allOrNothing = false, // set true to rollback if any line fails
}) async {
  final db = await DatabaseHelper.instance.database;

  final updated = <Map<String, dynamic>>[];
  final warnings = <Map<String, dynamic>>[];
  final missing  = <Map<String, dynamic>>[];

  // Expecting: { saleInvoiceId?: string, invoices: [ {...}, {...} ] }
  final List invoices = (payload['invoices'] as List?) ?? const [];

  // Run everything in ONE transaction so it’s atomic when allOrNothing=true
  try {
    await db.transaction((txn) async {
      for (final raw in invoices) {
        final inv = (raw as Map).map((k, v) => MapEntry('$k', v));

        // accept both camelCase and snake_case
        String batchId = (inv['batch_id'] ?? inv['batchId'] ?? '').toString().trim();
        final dynamic itemIdRaw = inv['item_id'] ?? inv['itemId'];
        final int itemId = itemIdRaw is int ? itemIdRaw : int.tryParse('${itemIdRaw ?? ''}') ?? 0;
        final int qtyReq = inv['quantity'] is num
            ? (inv['quantity'] as num).toInt()
            : int.tryParse('${inv['quantity']}') ?? 0;

        if (batchId.isEmpty || itemId <= 0 || qtyReq <= 0) {
          warnings.add({
            "batch_id": batchId,
            "item_id": itemId,
            "requested": qtyReq,
            "available": null,
            "reason": "invalid_input",
          });
          continue;
        }

        // Try atomic deduct only if enough stock
        final int affected = await txn.rawUpdate(
          '''
          UPDATE stock
          SET quantity = quantity - ?
          WHERE batch_id = ? AND item_id = ? AND quantity >= ?
          ''',
          [qtyReq, batchId, itemId, qtyReq],
        );

        if (affected == 1) {
          updated.add({
            "batch_id": batchId,
            "item_id": itemId,
            "deducted": qtyReq,
          });
        } else {
          // See what went wrong: missing row or insufficient stock
          final rows = await txn.rawQuery(
            'SELECT quantity FROM stock WHERE batch_id = ? AND item_id = ? LIMIT 1',
            [batchId, itemId],
          );
          if (rows.isEmpty) {
            missing.add({
              "batch_id": batchId,
              "item_id": itemId,
              "requested": qtyReq,
              "reason": "not_found",
            });
          } else {
            final int avail = (rows.first['quantity'] as num?)?.toInt() ?? 0;
            warnings.add({
              "batch_id": batchId,
              "item_id": itemId,
              "requested": qtyReq,
              "available": avail,
              "reason": "insufficient_stock",
            });
          }
        }
      }

      // If you want all-or-nothing, rollback when any issue exists
      if (allOrNothing && (warnings.isNotEmpty || missing.isNotEmpty)) {
        throw Exception('ROLLBACK_STOCK_UPDATE');
      }
    });
  } catch (_) {
    // Transaction rolled back if allOrNothing=true and there were issues.
    // We still return the collected warnings/missing so you can display them.

  }

  return StockApplyResult(updated: updated, warnings: warnings, missing: missing);
}
