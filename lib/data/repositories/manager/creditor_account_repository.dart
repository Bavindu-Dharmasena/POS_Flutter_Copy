// lib/data/repositories/manager/creditor_account_repository.dart
import 'package:pos_system/data/db/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:pos_system/data/models/manager/creditor_account.dart';

class CreditorAccountRepository {
  CreditorAccountRepository._();
  static final CreditorAccountRepository instance = CreditorAccountRepository._();

  static const _table = 'creditor_account';

  Future<Database> get _db async {
    final db = await DatabaseHelper.instance.database;
    // Ensure table exists even if DB version wasn't bumped yet
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_table (
        id                TEXT    PRIMARY KEY,
        name              TEXT    NOT NULL,
        company           TEXT,
        phone             TEXT,
        email             TEXT,
        last_invoice_date INTEGER NOT NULL,
        due_amount        REAL    NOT NULL DEFAULT 0,
        paid_amount       REAL    NOT NULL DEFAULT 0,
        overdue_days      INTEGER NOT NULL DEFAULT 0,
        created_at        INTEGER NOT NULL,
        updated_at        INTEGER NOT NULL
      );
    ''');
    return db;
  }

  // Basic ID generator like CR<6 digits>; you can swap with something else
  Future<String> _generateId(Database db) async {
    final ts = DateTime.now().millisecondsSinceEpoch % 1000000;
    final id = 'CR${ts.toString().padLeft(6, '0')}';
    // ensure uniqueness
    final c = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $_table WHERE id=?', [id])) ?? 0;
    return (c == 0) ? id : 'CR${(ts + 1).toString().padLeft(6, '0')}';
  }

  Future<List<CreditorAccount>> getAll() async {
    final db = await _db;
    final rows = await db.query(_table, orderBy: 'updated_at DESC');
    return rows.map(CreditorAccount.fromMap).toList();
  }

  Future<CreditorAccount> create(CreditorAccount c) async {
    final db = await _db;
    final id = c.id.isEmpty ? await _generateId(db) : c.id;
    final now = DateTime.now().millisecondsSinceEpoch;
    final toInsert = c.copyWith(
      id: id,
      createdAt: c.createdAt == 0 ? now : c.createdAt,
      updatedAt: now,
      // sensible defaults if caller omitted:
      overdueDays: c.overdueDays,
    ).toMap();
    await db.insert(_table, toInsert, conflictAlgorithm: ConflictAlgorithm.abort);
    final read = await db.query(_table, where: 'id=?', whereArgs: [id], limit: 1);
    return CreditorAccount.fromMap(read.first);
  }

  Future<int> update(CreditorAccount c) async {
    final db = await _db;
    final v = c.copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch).toMap();
    return db.update(_table, v, where: 'id=?', whereArgs: [c.id]);
  }

  Future<int> markPaid(String id) async {
    final db = await _db;
    // fetch current values
    final row = await db.query(_table, where: 'id=?', whereArgs: [id], limit: 1);
    if (row.isEmpty) return 0;
    final cur = CreditorAccount.fromMap(row.first);
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.update(
      _table,
      {
        'due_amount': 0.0,
        'paid_amount': cur.paidAmount + cur.dueAmount,
        'overdue_days': 0,
        'updated_at': now,
      },
      where: 'id=?',
      whereArgs: [id],
    );
  }

  Future<int> delete(String id) async {
    final db = await _db;
    return db.delete(_table, where: 'id=?', whereArgs: [id]);
  }

  /// Optional: seed a few rows if table empty (handy for first run)
  Future<void> seedIfEmpty() async {
    final db = await _db;
    final c = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $_table')) ?? 0;
    if (c > 0) return;

    final now = DateTime.now();
    final rows = <CreditorAccount>[
      CreditorAccount(
        id: '',
        name: 'Amal Perera',
        company: 'ABC Traders',
        phone: '+94 71 234 5678',
        email: 'amal@abc.lk',
        lastInvoiceDate: now.subtract(const Duration(days: 12)),
        dueAmount: 125000,
        paidAmount: 80000,
        overdueDays: 18,
        createdAt: 0,
        updatedAt: 0,
      ),
      CreditorAccount(
        id: '',
        name: 'Nimal Silva',
        company: 'Colombo Suppliers',
        phone: '+94 77 222 3344',
        email: 'nimal@col.lk',
        lastInvoiceDate: now.subtract(const Duration(days: 5)),
        dueAmount: 0,
        paidAmount: 450000,
        overdueDays: 0,
        createdAt: 0,
        updatedAt: 0,
      ),
    ];

    for (final r in rows) {
      await create(r);
    }
  }
}
