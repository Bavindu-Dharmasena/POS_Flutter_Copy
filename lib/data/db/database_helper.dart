import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const _dbName = 'pos.db';

  /// ⬆️ Bump to trigger migration and ensure user seeds on upgrade too.
  static const _dbVersion = 5; // was 4

  Database? _db;
  Future<Database> get database async => _db ??= await _initDB();

  Future<Database> _initDB() async {
    final String dbPath =
        kIsWeb ? _dbName : p.join(await getDatabasesPath(), _dbName);

    return openDatabase(
      dbPath,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  FutureOr<void> _onCreate(Database db, int version) async {
    // --- Users ---
    await db.execute('''
      CREATE TABLE user (
        id                 INTEGER PRIMARY KEY AUTOINCREMENT,
        name               TEXT    NOT NULL,
        email              TEXT    NOT NULL UNIQUE,
        contact            TEXT    NOT NULL,
        password           TEXT    NOT NULL,
        role               TEXT    NOT NULL DEFAULT 'Cashier' CHECK (role IN ('Admin','Manager','Cashier','StockKeeper')),
        color_code         TEXT    NOT NULL DEFAULT '#000000',
        created_at         INTEGER NOT NULL,
        updated_at         INTEGER NOT NULL,
        refresh_token_hash TEXT
      );
    ''');

    // ✅ Seed users safely (only if table empty)
    await _seedUsersIfEmpty(db);

    // --- Customer ---
    await db.execute('''
      CREATE TABLE customer (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        name     TEXT    NOT NULL,
        contact  TEXT    NOT NULL UNIQUE
      );
    ''');

    // --- Supplier ---
    await db.execute('''
      CREATE TABLE supplier (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        name           TEXT    NOT NULL,
        contact        TEXT    NOT NULL,
        email          TEXT,
        address        TEXT,
        brand          TEXT    NOT NULL,
        color_code     TEXT    NOT NULL DEFAULT '#000000',
        location       TEXT    NOT NULL,
        status         TEXT    CHECK (status IN ('ACTIVE','INACTIVE','PENDING')) DEFAULT 'ACTIVE',
        preferred      INTEGER NOT NULL DEFAULT 0,
        payment_terms  TEXT,
        notes          TEXT,
        created_at     INTEGER NOT NULL,
        updated_at     INTEGER NOT NULL
      );
    ''');

    // --- Category ---
    await db.execute('''
      CREATE TABLE category (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        category       TEXT    NOT NULL,
        color_code     TEXT    NOT NULL,
        category_image TEXT
      );
    ''');

    // --- Item ---
    await db.execute('''
      CREATE TABLE item (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        name          TEXT    NOT NULL,
        barcode       TEXT    NOT NULL UNIQUE,
        category_id   INTEGER NOT NULL,
        supplier_id   INTEGER NOT NULL,
        reorder_level INTEGER NOT NULL DEFAULT 0,
        gradient      TEXT,
        remark        TEXT,
        color_code    TEXT    NOT NULL DEFAULT '#000000',
        FOREIGN KEY (category_id) REFERENCES category(id) ON DELETE RESTRICT ON UPDATE CASCADE,
        FOREIGN KEY (supplier_id) REFERENCES supplier(id) ON DELETE RESTRICT ON UPDATE CASCADE
      );
    ''');

    // --- Stock ---
    await db.execute('''
      CREATE TABLE stock (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        batch_id        TEXT    NOT NULL,
        item_id         INTEGER NOT NULL,
        quantity        INTEGER NOT NULL,
        unit_price      REAL    NOT NULL,
        sell_price      REAL    NOT NULL,
        discount_amount REAL    NOT NULL DEFAULT 0,
        supplier_id     INTEGER NOT NULL,
        UNIQUE (batch_id, item_id),
        FOREIGN KEY (item_id)     REFERENCES item(id)     ON DELETE CASCADE ON UPDATE CASCADE,
        FOREIGN KEY (supplier_id) REFERENCES supplier(id) ON DELETE CASCADE ON UPDATE CASCADE
      );
    ''');

    // --- Sale ---
    await db.execute('''
      CREATE TABLE sale (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        date     INTEGER NOT NULL,
        total    REAL    NOT NULL,
        user_id  INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE RESTRICT ON UPDATE CASCADE
      );
    ''');

    // --- Invoice ---
    await db.execute('''
      CREATE TABLE invoice (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        batch_id         TEXT    NOT NULL,
        item_id          INTEGER NOT NULL,
        quantity         INTEGER NOT NULL,
        sale_invoice_id  INTEGER NOT NULL,
        FOREIGN KEY (item_id)         REFERENCES item(id)  ON DELETE RESTRICT ON UPDATE CASCADE,
        FOREIGN KEY (sale_invoice_id) REFERENCES sale(id)  ON DELETE CASCADE  ON UPDATE CASCADE
      );
    ''');
    await db.execute(
        'CREATE INDEX idx_invoice_sale_invoice_id ON invoice(sale_invoice_id);');

    // --- Payment ---
    await db.execute('''
      CREATE TABLE payment (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        amount           REAL    NOT NULL,
        remain_amount    REAL    NOT NULL,
        date             INTEGER NOT NULL,
        file_name        TEXT    NOT NULL,
        type             TEXT    NOT NULL,
        sale_invoice_id  INTEGER NOT NULL,
        user_id          INTEGER NOT NULL,
        customer_contact TEXT,
        FOREIGN KEY (sale_invoice_id)   REFERENCES sale(id)        ON DELETE CASCADE  ON UPDATE CASCADE,
        FOREIGN KEY (user_id)           REFERENCES user(id)        ON DELETE RESTRICT ON UPDATE CASCADE,
        FOREIGN KEY (customer_contact)  REFERENCES customer(contact) ON DELETE SET NULL ON UPDATE CASCADE
      );
    ''');
    await db.execute(
        'CREATE INDEX idx_payment_sale_invoice_id ON payment(sale_invoice_id);');

    // --- Extra supplier tables (legacy) ---
    await db.execute('''
      CREATE TABLE supplier_request_details (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        supplier_id INTEGER NOT NULL,
        FOREIGN KEY (supplier_id) REFERENCES supplier(id) ON DELETE CASCADE ON UPDATE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE supplier_transaction (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        supplier_id INTEGER NOT NULL,
        amount      REAL    NOT NULL,
        date        INTEGER NOT NULL,
        FOREIGN KEY (supplier_id) REFERENCES supplier(id) ON DELETE CASCADE ON UPDATE CASCADE
      );
    ''');

    // --- Supplier Request (header + lines) ---
    await _createSupplierRequestTables(db);

    // --- Seed inventory + supplier requests ---
    await _seedInitialData(db);
  }

  FutureOr<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    // If upgrading to v3+, seed inventory only when items table is empty.
    if (oldVersion < 3) {
      final cnt = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM item'),
          ) ??
          0;
      if (cnt == 0) {
        await _seedInitialData(db);
      }
    }

    // v4: ensure supplier_request tables exist and seed if empty
    if (oldVersion < 4) {
      await _createSupplierRequestTables(db);

      final srCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM supplier_request'),
          ) ??
          0;
      if (srCount == 0) {
        await _seedSupplierRequestsForExistingDb(db);
      }
    }

    // ✅ v5: ensure users table has seeds on existing installs
    if (oldVersion < 5) {
      await _seedUsersIfEmpty(db);
    }
  }

  // ---------------------------------------------------------------------------
  // Public helper
  // ---------------------------------------------------------------------------

  Future<T> runInTransaction<T>(
    Future<T> Function(Transaction tx) action,
  ) async {
    final db = await database;
    return db.transaction<T>(action);
  }

  // ---------------------------------------------------------------------------
  // Schema helpers
  // ---------------------------------------------------------------------------

  Future<void> _createSupplierRequestTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS supplier_request (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        supplier_id INTEGER NOT NULL,
        created_at  INTEGER NOT NULL,
        status      TEXT    NOT NULL DEFAULT 'PENDING'
          CHECK (status IN ('PENDING','ACCEPTED','REJECTED','RESENT')),
        FOREIGN KEY (supplier_id) REFERENCES supplier(id)
          ON DELETE CASCADE ON UPDATE CASCADE
      );
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_supplier_request_created_at ON supplier_request(created_at);');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_supplier_request_supplier_id ON supplier_request(supplier_id);');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS supplier_request_item (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        request_id       INTEGER NOT NULL,
        item_id          INTEGER NOT NULL,
        requested_amount INTEGER NOT NULL,
        quantity         INTEGER NOT NULL,
        unit_price       REAL    NOT NULL,
        sale_price       REAL    NOT NULL,
        FOREIGN KEY (request_id) REFERENCES supplier_request(id)
          ON DELETE CASCADE ON UPDATE CASCADE,
        FOREIGN KEY (item_id)    REFERENCES item(id)
          ON DELETE RESTRICT ON UPDATE CASCADE
      );
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sri_request_id ON supplier_request_item(request_id);');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sri_item_id ON supplier_request_item(item_id);');
  }

  // ---------------------------------------------------------------------------
  // Seeders
  // ---------------------------------------------------------------------------

  /// ✅ New: Seed default users only if table is empty.
  Future<void> _seedUsersIfEmpty(DatabaseExecutor db) async {
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM user'),
        ) ??
        0;
    if (count > 0) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    String hash(String s) => sha256.convert(utf8.encode(s)).toString();

    final users = [
      {
        'name': 'Sadeep Chathushan',
        'email': 'sadeep@aasa.lk',
        'contact': '+94 77 000 0001',
        'password': hash('Admin@123'),
        'role': 'Admin',
        'color_code': '#7C3AED',
        'created_at': now,
        'updated_at': now,
      },
      {
        'name': 'Hansima Perera',
        'email': 'hansima@aasa.lk',
        'contact': '+94 77 000 0002',
        'password': hash('Manager@123'),
        'role': 'Manager',
        'color_code': '#0EA5E9',
        'created_at': now,
        'updated_at': now,
      },
      {
        'name': 'Achintha Silva',
        'email': 'achintha@aasa.lk',
        'contact': '+94 77 000 0003',
        'password': hash('Cashier@123'),
        'role': 'Cashier',
        'color_code': '#10B981',
        'created_at': now,
        'updated_at': now,
      },
      {
        'name': 'Insaf Imran',
        'email': 'insaf@aasa.lk',
        'contact': '+94 77 000 0004',
        'password': hash('Stock@123'),
        'role': 'StockKeeper',
        'color_code': '#F59E0B',
        'created_at': now,
        'updated_at': now,
      },
    ];

    for (final u in users) {
      await db.insert(
        'user',
        u,
        conflictAlgorithm: ConflictAlgorithm.ignore, // idempotent
      );
    }
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((tx) async {
      // ---------- Categories ----------
      final beveragesId = await tx.insert('category', {
        'category': 'Beverages',
        'color_code': '#3B82F6',
        'category_image': null,
      });
      final snacksId = await tx.insert('category', {
        'category': 'Snacks',
        'color_code': '#F59E0B',
        'category_image': null,
      });
      final dairyId = await tx.insert('category', {
        'category': 'Dairy',
        'color_code': '#10B981',
        'category_image': null,
      });
      final householdId = await tx.insert('category', {
        'category': 'Household',
        'color_code': '#EF4444',
        'category_image': null,
      });
      final stationeryId = await tx.insert('category', {
        'category': 'Stationery',
        'color_code': '#6366F1',
        'category_image': null,
      });

      // ---------- Suppliers ----------
      final cocaId = await tx.insert('supplier', {
        'name': 'Coca Cola Lanka',
        'contact': '0770000000',
        'email': null,
        'address': 'Colombo 01',
        'brand': 'CocaCola',
        'color_code': '#EF4444',
        'location': 'Colombo',
        'status': 'ACTIVE',
        'preferred': 1,
        'payment_terms': 'CASH',
        'notes': null,
        'created_at': now,
        'updated_at': now,
      });

      final malibanId = await tx.insert('supplier', {
        'name': 'Maliban Foods',
        'contact': '0771111111',
        'email': null,
        'address': 'Ratmalana',
        'brand': 'Maliban',
        'color_code': '#F59E0B',
        'location': 'Colombo',
        'status': 'ACTIVE',
        'preferred': 0,
        'payment_terms': 'NET 15',
        'notes': null,
        'created_at': now,
        'updated_at': now,
      });

      final fonterraId = await tx.insert('supplier', {
        'name': 'Fonterra Lanka',
        'contact': '0772222222',
        'email': null,
        'address': 'Biyagama',
        'brand': 'Anchor',
        'color_code': '#10B981',
        'location': 'Gampaha',
        'status': 'ACTIVE',
        'preferred': 0,
        'payment_terms': 'NET 30',
        'notes': null,
        'created_at': now,
        'updated_at': now,
      });

      final hemasId = await tx.insert('supplier', {
        'name': 'Hemas',
        'contact': '0773333333',
        'email': null,
        'address': 'Colombo 02',
        'brand': 'Sunlight',
        'color_code': '#F43F5E',
        'location': 'Colombo',
        'status': 'ACTIVE',
        'preferred': 0,
        'payment_terms': 'NET 7',
        'notes': null,
        'created_at': now,
        'updated_at': now,
      });

      final atlasId = await tx.insert('supplier', {
        'name': 'Atlas',
        'contact': '0774444444',
        'email': null,
        'address': 'Peliyagoda',
        'brand': 'Atlas',
        'color_code': '#6366F1',
        'location': 'Gampaha',
        'status': 'ACTIVE',
        'preferred': 0,
        'payment_terms': 'CASH',
        'notes': null,
        'created_at': now,
        'updated_at': now,
      });

      // ---------- Items ----------
      final cokeId = await tx.insert('item', {
        'name': 'Coca Cola 500ml',
        'barcode': 'BARC0001',
        'category_id': beveragesId,
        'supplier_id': cocaId,
        'reorder_level': 10,
        'gradient': null,
        'remark': 'Popular',
        'color_code': '#EF4444',
      });

      final crackersId = await tx.insert('item', {
        'name': 'Cream Crackers 190g',
        'barcode': 'BARC0002',
        'category_id': snacksId,
        'supplier_id': malibanId,
        'reorder_level': 8,
        'gradient': null,
        'remark': 'Fast moving',
        'color_code': '#F59E0B',
      });

      final milkPowderId = await tx.insert('item', {
        'name': 'Anchor Milk Powder 400g',
        'barcode': 'BARC0003',
        'category_id': dairyId,
        'supplier_id': fonterraId,
        'reorder_level': 12,
        'gradient': null,
        'remark': 'High demand',
        'color_code': '#10B981',
      });

      final sunlightId = await tx.insert('item', {
        'name': 'Sunlight Soap 200g',
        'barcode': 'BARC0004',
        'category_id': householdId,
        'supplier_id': hemasId,
        'reorder_level': 0,
        'gradient': null,
        'remark': 'Household',
        'color_code': '#F43F5E',
      });

      final bookId = await tx.insert('item', {
        'name': 'Atlas Exercise Book 80p',
        'barcode': 'BARC0005',
        'category_id': stationeryId,
        'supplier_id': atlasId,
        'reorder_level': 5,
        'gradient': null,
        'remark': 'School',
        'color_code': '#6366F1',
      });

      // ---------- Stock ----------
      await tx.insert('stock', {
        'batch_id': 'COKE-2025-01',
        'item_id': cokeId,
        'quantity': 100,
        'unit_price': 120.0,
        'sell_price': 150.0,
        'discount_amount': 0.0,
        'supplier_id': cocaId,
      });

      await tx.insert('stock', {
        'batch_id': 'CRACK-2025-01',
        'item_id': crackersId,
        'quantity': 60,
        'unit_price': 140.0,
        'sell_price': 180.0,
        'discount_amount': 0.0,
        'supplier_id': malibanId,
      });

      await tx.insert('stock', {
        'batch_id': 'MILK-2025-01',
        'item_id': milkPowderId,
        'quantity': 40,
        'unit_price': 680.0,
        'sell_price': 850.0,
        'discount_amount': 0.0,
        'supplier_id': fonterraId,
      });

      await tx.insert('stock', {
        'batch_id': 'SUN-2025-01',
        'item_id': sunlightId,
        'quantity': 80,
        'unit_price': 180.0,
        'sell_price': 220.0,
        'discount_amount': 0.0,
        'supplier_id': hemasId,
      });

      await tx.insert('stock', {
        'batch_id': 'BOOK-2025-01',
        'item_id': bookId,
        'quantity': 120,
        'unit_price': 70.0,
        'sell_price': 100.0,
        'discount_amount': 0.0,
        'supplier_id': atlasId,
      });

      // ---------- Supplier Requests (3 demo rows) ----------
      final req1 = await tx.insert('supplier_request', {
        'supplier_id': cocaId,
        'created_at': now - const Duration(days: 1).inMilliseconds,
        'status': 'PENDING',
      });
      await tx.insert('supplier_request_item', {
        'request_id': req1,
        'item_id': cokeId,
        'requested_amount': 60,
        'quantity': 60,
        'unit_price': 120.0,
        'sale_price': 150.0,
      });

      final req2 = await tx.insert('supplier_request', {
        'supplier_id': malibanId,
        'created_at': now - const Duration(days: 5).inMilliseconds,
        'status': 'PENDING',
      });
      await tx.insert('supplier_request_item', {
        'request_id': req2,
        'item_id': crackersId,
        'requested_amount': 30,
        'quantity': 30,
        'unit_price': 140.0,
        'sale_price': 180.0,
      });

      final req3 = await tx.insert('supplier_request', {
        'supplier_id': fonterraId,
        'created_at': now - const Duration(days: 10).inMilliseconds,
        'status': 'PENDING',
      });
      await tx.insert('supplier_request_item', {
        'request_id': req3,
        'item_id': milkPowderId,
        'requested_amount': 25,
        'quantity': 25,
        'unit_price': 680.0,
        'sale_price': 850.0,
      });
    });
  }

  Future<void> _seedSupplierRequestsForExistingDb(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    int? _firstInt(List<Map<String, Object?>> rows) =>
        rows.isEmpty ? null : rows.first.values.first as int?;

    Future<int?> _lookup(DatabaseExecutor ex, String sql) async =>
        _firstInt(await ex.rawQuery(sql));

    final cocaId = await _lookup(
        db, "SELECT id FROM supplier WHERE name='Coca Cola Lanka' LIMIT 1");
    final malibanId = await _lookup(
        db, "SELECT id FROM supplier WHERE name='Maliban Foods' LIMIT 1");
    final fonterraId = await _lookup(
        db, "SELECT id FROM supplier WHERE name='Fonterra Lanka' LIMIT 1");

    final cokeId =
        await _lookup(db, "SELECT id FROM item WHERE barcode='BARC0001' LIMIT 1");
    final crackersId =
        await _lookup(db, "SELECT id FROM item WHERE barcode='BARC0002' LIMIT 1");
    final milkPowderId =
        await _lookup(db, "SELECT id FROM item WHERE barcode='BARC0003' LIMIT 1");

    await db.transaction((tx) async {
      if (cocaId != null && cokeId != null) {
        final req1 = await tx.insert('supplier_request', {
          'supplier_id': cocaId,
          'created_at': now - const Duration(days: 1).inMilliseconds,
          'status': 'PENDING',
        });
        await tx.insert('supplier_request_item', {
          'request_id': req1,
          'item_id': cokeId,
          'requested_amount': 60,
          'quantity': 60,
          'unit_price': 120.0,
          'sale_price': 150.0,
        });
      }

      if (malibanId != null && crackersId != null) {
        final req2 = await tx.insert('supplier_request', {
          'supplier_id': malibanId,
          'created_at': now - const Duration(days: 5).inMilliseconds,
          'status': 'PENDING',
        });
        await tx.insert('supplier_request_item', {
          'request_id': req2,
          'item_id': crackersId,
          'requested_amount': 30,
          'quantity': 30,
          'unit_price': 140.0,
          'sale_price': 180.0,
        });
      }

      if (fonterraId != null && milkPowderId != null) {
        final req3 = await tx.insert('supplier_request', {
          'supplier_id': fonterraId,
          'created_at': now - const Duration(days: 10).inMilliseconds,
          'status': 'PENDING',
        });
        await tx.insert('supplier_request_item', {
          'request_id': req3,
          'item_id': milkPowderId,
          'requested_amount': 25,
          'quantity': 25,
          'unit_price': 680.0,
          'sale_price': 850.0,
        });
      }
    });
  }
}
