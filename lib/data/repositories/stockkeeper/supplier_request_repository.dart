import 'package:sqflite/sqflite.dart';
import 'package:pos_system/data/db/database_helper.dart';
import 'package:pos_system/data/models/stockkeeper/supplier_request_model.dart';

class SupplierRequestRepository {
  SupplierRequestRepository._();
  static final SupplierRequestRepository instance = SupplierRequestRepository._();

  Future<Database> get _db async => DatabaseHelper.instance.database;

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
        'updated_at': now,
        'status': status,
      });

      for (final l in lines) {
        await tx.insert('supplier_request_item', l.toInsertMap(reqId));
      }

      return _getByIdTx(tx, reqId);
    });
  }

  /// Insert a single line into an existing request.
  Future<int> addLine({
    required int requestId,
    required CreateSupplierRequestLine line,
  }) async {
    final db = await _db;
    return db.insert('supplier_request_item', line.toInsertMap(requestId));
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
      final raw = query!.trim();
      final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
      final q = '%$raw%';
      final qDigits = '%$digits%';
      where.add('(s.name LIKE ? OR CAST(r.id AS TEXT) LIKE ?)');
      args..add(q)..add(qDigits);
    }

    final rows = await db.rawQuery('''
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
    ''', args);

    return rows.map(SupplierRequestRecord.fromHeaderMap).toList();
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

    final items = lineRows.map(SupplierRequestLine.fromMap).toList();

    return SupplierRequestRecord(
      id: (h['id'] as num).toInt(),
      supplierId: (h['supplier_id'] as num).toInt(),
      supplierName: (h['supplier_name'] as String?) ?? 'Supplier',
      createdAt: (h['created_at'] as num).toInt(),
      status: (h['status'] as String?) ?? 'PENDING',
      items: items,
    );
  }

  /// List items that belong to the supplier of this request,
  /// including current stock and whether they are already added to the request.
  ///
  /// Returns a list of mutable maps with keys:
  /// - item_id (int)
  /// - name (String)
  /// - reorder_level (int)
  /// - current_stock (int)
  /// - already_added (int: 0/1)
  Future<List<Map<String, Object?>>> listItemsForRequest({
    required int requestId,
    String? query,
    int? limit,
    int? offset,
  }) async {
    final db = await _db;

    final where = <String>[];
    final args = <Object?>[];

    // match the supplier from the request
    where.add('i.supplier_id = (SELECT supplier_id FROM supplier_request WHERE id = ?)');
    args.add(requestId);

    if ((query ?? '').trim().isNotEmpty) {
      final q = '%${query!.trim()}%';
      where.add('(i.name LIKE ? OR i.barcode LIKE ?)');
      args..add(q)..add(q);
    }

    // Request id used twice in SELECT (EXISTS and supplier_id subselect)
    final sql = '''
      SELECT
        i.id AS item_id,
        i.name,
        i.reorder_level,
        COALESCE((SELECT SUM(st.quantity) FROM stock st WHERE st.item_id = i.id), 0) AS current_stock,
        CASE WHEN EXISTS(
          SELECT 1 FROM supplier_request_item sri
          WHERE sri.request_id = ? AND sri.item_id = i.id
        ) THEN 1 ELSE 0 END AS already_added
      FROM item i
      WHERE ${where.join(' AND ')}
      ORDER BY i.name COLLATE NOCASE ASC
      ${limit != null ? 'LIMIT $limit' : ''}
      ${offset != null ? 'OFFSET $offset' : ''}
    ''';

    final rows = await db.rawQuery(sql, [requestId, ...args]);

    // return a MUTABLE copy (so UI can safely edit/filter)
    return rows.map((e) => Map<String, Object?>.from(e)).toList(growable: true);
  }

  // ---------------- UPDATE ----------------

  Future<int> setStatus(int requestId, String status) async {
    const allowed = {'PENDING', 'ACCEPTED', 'REJECTED', 'RESENT'};
    final normalized = status.toUpperCase();
    if (!allowed.contains(normalized)) {
      throw ArgumentError('Invalid status: $status');
    }

    final db = await _db;
    return db.update(
      'supplier_request',
      {
        'status': normalized,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [requestId],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> updateLineQuantity({
    required int lineId,
    required int quantity,
  }) async {
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
