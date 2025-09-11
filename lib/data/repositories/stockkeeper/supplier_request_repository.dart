import 'package:sqflite/sqflite.dart';
import 'package:pos_system/data/db/database_helper.dart';
import 'package:pos_system/data/models/stockkeeper/supplier_request_model.dart';

typedef Row = Map<String, Object?>;

class SupplierRequestRepository {
  SupplierRequestRepository._();
  static final SupplierRequestRepository instance = SupplierRequestRepository._();

  Future<Database> get _db => DatabaseHelper.instance.database;

  // ---------------- CREATE ----------------

  /// Creates a new supplier request + its lines.
  Future<SupplierRequestRecord> create({
    required int supplierId,
    required List<CreateSupplierRequestLine> lines,
    int? createdAtMs,
    String status = 'PENDING',
  }) async {
    final db = await _db;
    final now = createdAtMs ?? DateTime.now().millisecondsSinceEpoch;

    return await db.transaction<SupplierRequestRecord>((tx) async {
      final reqId = await tx.insert('supplier_request', {
        'supplier_id': supplierId,
        'created_at': now,
        'status': status,
      });

      for (final l in lines) {
        await tx.insert('supplier_request_item', l.toInsertMap(reqId));
      }

      // return freshly loaded full record
      return _getByIdTx(tx, reqId);
    });
  }

  // ---------------- READ ----------------

  /// Returns a paged / filtered list of request *headers* (no items).
  Future<List<SupplierRequestRecord>> list({
    String? query,          // matches supplier name or REQ-XXXX id
    int? startMs,           // inclusive
    int? endMs,             // inclusive
    int? limit,
    int? offset,
  }) async {
    final db = await _db;

    final where = <String>[];
    final args = <Object?>[];

    if (startMs != null) {
      where.add('r.created_at >= ?');
      args.add(startMs);
    }
    if (endMs != null) {
      where.add('r.created_at <= ?');
      args.add(endMs);
    }
    if ((query ?? '').trim().isNotEmpty) {
      final q = '%${query!.trim()}%';
      // allow search by supplier name or REQ-XXXX numeric part
      where.add('(s.name LIKE ? OR CAST(r.id AS TEXT) LIKE ?)');
      args..add(q)..add(q.replaceAll(RegExp(r'[^0-9%]'), ''));
    }

    final sql = '''
      SELECT
        r.id,
        r.supplier_id,
        s.name AS supplier_name,
        r.created_at,
        r.status,
        COUNT(ri.id) AS items_count
      FROM supplier_request r
      JOIN supplier s ON s.id = r.supplier_id
      LEFT JOIN supplier_request_item ri ON ri.request_id = r.id
      ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
      GROUP BY r.id
      ORDER BY r.created_at DESC, r.id DESC
      ${limit != null ? 'LIMIT $limit' : ''}
      ${offset != null ? 'OFFSET $offset' : ''}
    ''';

    final rows = await db.rawQuery(sql, args);
    return rows.map((r) => SupplierRequestRecord(
      id: (r['id'] as int),
      supplierId: (r['supplier_id'] as int),
      supplierName: (r['supplier_name'] as String?) ?? 'Supplier',
      createdAt: (r['created_at'] as int),
      status: (r['status'] as String?) ?? 'PENDING',
      items: const <SupplierRequestLine>[],  // header-only
    )).toList();
  }

  /// Returns full request with lines (includes itemName + currentStock).
  Future<SupplierRequestRecord?> getById(int id) async {
    final db = await _db;
    try {
      return await _getByIdTx(db, id);
    } catch (_) {
      return null;
    }
  }

  // Internal: same as getById but can run inside a transaction
  Future<SupplierRequestRecord> _getByIdTx(DatabaseExecutor tx, int id) async {
    final headerRows = await tx.rawQuery('''
      SELECT r.id, r.supplier_id, s.name AS supplier_name, r.created_at, r.status
      FROM supplier_request r
      JOIN supplier s ON s.id = r.supplier_id
      WHERE r.id = ?
      LIMIT 1
    ''', [id]);

    if (headerRows.isEmpty) {
      throw StateError('Supplier request $id not found');
    }

    final h = headerRows.first;

    // Lines + computed current stock
    final lineRows = await tx.rawQuery('''
      SELECT
        sri.id,
        sri.item_id,
        i.name AS item_name,
        sri.requested_amount,
        sri.quantity,
        sri.unit_price,
        sri.sale_price,
        COALESCE((
          SELECT SUM(st.quantity)
          FROM stock st
          WHERE st.item_id = sri.item_id
        ), 0) AS current_stock
      FROM supplier_request_item sri
      JOIN item i ON i.id = sri.item_id
      WHERE sri.request_id = ?
      ORDER BY sri.id ASC
    ''', [id]);

    final items = lineRows.map((r) => SupplierRequestLine(
      id: r['id'] as int,
      itemId: r['item_id'] as int,
      itemName: (r['item_name'] as String?) ?? 'Item',
      currentStock: (r['current_stock'] as num?)?.toInt() ?? 0,
      requestedAmount: (r['requested_amount'] as num).toInt(),
      quantity: (r['quantity'] as num).toInt(),
      unitPrice: (r['unit_price'] as num).toDouble(),
      salePrice: (r['sale_price'] as num).toDouble(),
    )).toList();

    return SupplierRequestRecord(
      id: h['id'] as int,
      supplierId: h['supplier_id'] as int,
      supplierName: (h['supplier_name'] as String?) ?? 'Supplier',
      createdAt: h['created_at'] as int,
      status: (h['status'] as String?) ?? 'PENDING',
      items: items,
    );
  }

  // ---------------- UPDATE ----------------

  Future<int> setStatus(int requestId, String status) async {
    final db = await _db;
    return db.update(
      'supplier_request',
      {'status': status},
      where: 'id = ?',
      whereArgs: [requestId],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> updateLineQuantity({required int lineId, required int quantity}) async {
    final db = await _db;
    return db.update(
      'supplier_request_item',
      {'quantity': quantity},
      where: 'id = ?',
      whereArgs: [lineId],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // ---------------- DELETE ----------------

  Future<int> deleteLine(int lineId) async {
    final db = await _db;
    return db.delete('supplier_request_item', where: 'id = ?', whereArgs: [lineId]);
  }

  Future<int> deleteRequest(int requestId) async {
    final db = await _db;
    // will cascade to lines
    return db.delete('supplier_request', where: 'id = ?', whereArgs: [requestId]);
  }
}
