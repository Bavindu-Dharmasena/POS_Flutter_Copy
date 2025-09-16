// lib/data/repositories/manager/creditor_account_repository.dart
import 'package:pos_system/data/db/database_helper.dart';
import 'package:sqflite/sqflite.dart';

import 'package:pos_system/data/models/manager/creditor_account.dart';
import 'package:pos_system/data/models/manager/creditor_payment.dart';

class CreditorAccountRepository {
  CreditorAccountRepository._();
  static final CreditorAccountRepository instance = CreditorAccountRepository._();

  static const _tAccount = 'creditor_account';
  static const _tPayment = 'creditor_payment';

  Future<Database> get _db async {
    final db = await DatabaseHelper.instance.database;

    // Ensure necessary tables exist (no change to DatabaseHelper)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tAccount (
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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tPayment (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        creditor_id  TEXT    NOT NULL,
        amount       REAL    NOT NULL,
        paid_at      INTEGER NOT NULL,
        note         TEXT,
        FOREIGN KEY (creditor_id) REFERENCES $_tAccount(id)
          ON DELETE CASCADE ON UPDATE CASCADE
      );
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pay_creditor ON $_tPayment(creditor_id, paid_at DESC);',
    );

    return db;
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<List<CreditorAccount>> getAll() async {
    final db = await _db;
    final rows = await db.query(_tAccount, orderBy: 'updated_at DESC');
    return rows.map(CreditorAccount.fromMap).toList();
  }

  Future<CreditorAccount> create(CreditorAccount c) async {
    final db = await _db;
    final id = c.id.isEmpty ? await _generateId(db) : c.id;
    final now = DateTime.now().millisecondsSinceEpoch;
    final data = c
        .copyWith(id: id, createdAt: c.createdAt == 0 ? now : c.createdAt, updatedAt: now)
        .toMap();
    await db.insert(_tAccount, data, conflictAlgorithm: ConflictAlgorithm.abort);
    final read = await db.query(_tAccount, where: 'id=?', whereArgs: [id], limit: 1);
    return CreditorAccount.fromMap(read.first);
  }

  Future<int> update(CreditorAccount c) async {
    final db = await _db;
    final v = c.copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch).toMap();
    return db.update(_tAccount, v, where: 'id=?', whereArgs: [c.id]);
  }

  Future<int> markPaid(String id) async {
    final db = await _db;
    final row = await db.query(_tAccount, where: 'id=?', whereArgs: [id], limit: 1);
    if (row.isEmpty) return 0;
    final cur = CreditorAccount.fromMap(row.first);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (cur.dueAmount > 0) {
      await db.insert(_tPayment, {
        'creditor_id': cur.id,
        'amount': cur.dueAmount,
        'paid_at': now,
        'note': 'Full settlement',
      });
    }

    return db.update(
      _tAccount,
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

  /// Add a partial payment (or full). Clamps to current due.
  Future<CreditorAccount?> addPayment({
    required String creditorId,
    required double amount,
    String? note,
    DateTime? paidAt,
  }) async {
    if (amount <= 0) return null;
    final db = await _db;

    return db.transaction<CreditorAccount?>((tx) async {
      final row = await tx.query(_tAccount, where: 'id=?', whereArgs: [creditorId.trim()], limit: 1);
      if (row.isEmpty) return null;
      final cur = CreditorAccount.fromMap(row.first);

      final nowMs = (paidAt ?? DateTime.now()).millisecondsSinceEpoch;
      final pay = amount > cur.dueAmount ? cur.dueAmount : amount;
      final newDue = (cur.dueAmount - pay).clamp(0, double.infinity);
      final newPaid = cur.paidAmount + pay;

      await tx.insert(_tPayment, {
        'creditor_id': cur.id,
        'amount': pay,
        'paid_at': nowMs,
        'note': note,
      });

      await tx.update(
        _tAccount,
        {
          'due_amount': newDue,
          'paid_amount': newPaid,
          'overdue_days': newDue == 0 ? 0 : cur.overdueDays,
          'updated_at': nowMs,
        },
        where: 'id=?',
        whereArgs: [cur.id],
      );

      final out = await tx.query(_tAccount, where: 'id=?', whereArgs: [cur.id], limit: 1);
      return out.isEmpty ? null : CreditorAccount.fromMap(out.first);
    });
  }

  Future<List<CreditorPayment>> getPayments(String creditorId, {int limit = 50}) async {
    final db = await _db;
    final rows = await db.query(
      _tPayment,
      where: 'creditor_id=?',
      whereArgs: [creditorId.trim()],
      orderBy: 'paid_at DESC',
      limit: limit,
    );
    return rows.map(CreditorPayment.fromMap).toList();
  }

  // ---------------------------------------------------------------------------
  // Seed (optional helper)
  // ---------------------------------------------------------------------------

  Future<void> seedIfEmpty() async {
    final db = await _db;
    final c = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $_tAccount')) ?? 0;
    if (c > 0) return;

    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final samples = <CreditorAccount>[
      CreditorAccount(
        id: _makeIdFromMs(nowMs - 20000),
        name: 'Amal Perera',
        company: 'ABC Traders',
        phone: '+94 71 234 5678',
        email: 'amal@abc.lk',
        lastInvoiceDate: now.subtract(const Duration(days: 18)),
        dueAmount: 125000,
        paidAmount: 80000,
        overdueDays: 18,
        createdAt: nowMs,
        updatedAt: nowMs,
      ),
      CreditorAccount(
        id: _makeIdFromMs(nowMs - 10000),
        name: 'Nimal Silva',
        company: 'Colombo Suppliers',
        phone: '+94 77 222 3344',
        email: 'nimal@col.lk',
        lastInvoiceDate: now.subtract(const Duration(days: 5)),
        dueAmount: 0,
        paidAmount: 450000,
        overdueDays: 0,
        createdAt: nowMs,
        updatedAt: nowMs,
      ),
    ];

    for (final s in samples) {
      await create(s);
    }
  }

  // ---------------------------------------------------------------------------
  // Small helpers
  // ---------------------------------------------------------------------------

  Future<String> _generateId(Database db) async {
    // simple unique-ish id: CR + last 6 of epoch
    final ms = DateTime.now().millisecondsSinceEpoch % 1000000;
    return 'CR${ms.toString().padLeft(6, '0')}';
  }

  String _makeIdFromMs(int ms) => 'CR${(ms % 1000000).toString().padLeft(6, '0')}';
}
