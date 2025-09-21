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

  /// Bump this when schema changes (triggers onUpgrade).
  static const _dbVersion = 2; // 👈 bumped to 2

  Database? _db;
  Future<Database> get database async => _db ??= await _initDB();

  Future<Database> _initDB() async {
    final String dbPath = kIsWeb ? _dbName : p.join(await getDatabasesPath(), _dbName);

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

  // Helper to hash passwords
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  FutureOr<void> _onCreate(Database db, int version) async {
    // 1) user
    await db.execute('''
      CREATE TABLE user (
        id                 INTEGER PRIMARY KEY AUTOINCREMENT,
        name               TEXT    NOT NULL,
        email              TEXT    NOT NULL UNIQUE,
        contact            TEXT    NOT NULL,
        password           TEXT    NOT NULL,
        role               TEXT    NOT NULL DEFAULT 'Cashier'
                           CHECK (role IN ('Admin','Manager','Cashier','StockKeeper')),
        color_code         TEXT    NOT NULL DEFAULT '#000000',
        created_at         INTEGER NOT NULL,
        updated_at         INTEGER NOT NULL,
        refresh_token_hash TEXT
      );
    ''');

    // 2) customer
    await db.execute('''
      CREATE TABLE customer (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        name     TEXT    NOT NULL,
        contact  TEXT    NOT NULL UNIQUE
      );
    ''');

    // 3) supplier
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

    // 4) category
    await db.execute('''
      CREATE TABLE category (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        category       TEXT    NOT NULL,
        color_code     TEXT    NOT NULL,
        category_image TEXT
      );
    ''');

    // 5) item
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
        created_by    INTEGER,                          -- 👈 NEW (nullable in SQLite to allow simple migration)
        FOREIGN KEY (category_id) REFERENCES category(id) ON DELETE RESTRICT ON UPDATE CASCADE,
        FOREIGN KEY (supplier_id) REFERENCES supplier(id) ON DELETE RESTRICT ON UPDATE CASCADE,
        FOREIGN KEY (created_by)  REFERENCES user(id)     ON DELETE SET NULL  ON UPDATE CASCADE
      );
    ''');

    // 6) stock
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

    // 7) payment
    await db.execute('''
      CREATE TABLE payment (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        amount           REAL    NOT NULL,
        remain_amount    REAL    NOT NULL,
        date             INTEGER NOT NULL,
        file_name        TEXT    NOT NULL,
        type             TEXT    NOT NULL,
        sale_invoice_id  TEXT    NOT NULL,
        user_id          INTEGER NOT NULL,
        customer_contact TEXT,
        discount_type    TEXT    NOT NULL DEFAULT 'no'
                           CHECK (discount_type IN ('no','percentage','amount')),
        discount_value   REAL    NOT NULL DEFAULT 0,
        UNIQUE (sale_invoice_id),
        FOREIGN KEY (user_id)           REFERENCES user(id)           ON DELETE RESTRICT ON UPDATE CASCADE,
        FOREIGN KEY (customer_contact)  REFERENCES customer(contact)  ON DELETE SET NULL   ON UPDATE CASCADE
      );
    ''');

    // 8) invoice
    await db.execute('''
      CREATE TABLE invoice (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        batch_id         TEXT    NOT NULL,
        item_id          INTEGER NOT NULL,
        quantity         INTEGER NOT NULL,
        unit_saled_price REAL    NOT NULL,
        sale_invoice_id  TEXT    NOT NULL,
        FOREIGN KEY (item_id)         REFERENCES item(id)                 ON DELETE RESTRICT ON UPDATE CASCADE,
        FOREIGN KEY (sale_invoice_id) REFERENCES payment(sale_invoice_id) ON DELETE CASCADE  ON UPDATE CASCADE
      );
    ''');

    // 9) supplier_request
    await db.execute('''
      CREATE TABLE supplier_request (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        supplier_id INTEGER NOT NULL,
        status      TEXT NOT NULL DEFAULT 'PENDING'
                     CHECK (status IN ('PENDING','ACCEPTED','REJECTED','RESENT')),
        created_at  INTEGER NOT NULL,
        updated_at  INTEGER NOT NULL,
        FOREIGN KEY (supplier_id) REFERENCES supplier(id)
          ON DELETE RESTRICT ON UPDATE CASCADE
      );
    ''');

    // 10) supplier_request_item
    await db.execute('''
      CREATE TABLE supplier_request_item (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        request_id       INTEGER NOT NULL,
        item_id          INTEGER NOT NULL,
        requested_amount INTEGER NOT NULL DEFAULT 0,
        quantity         INTEGER NOT NULL DEFAULT 0,
        unit_price       REAL    NOT NULL DEFAULT 0,
        sale_price       REAL    NOT NULL DEFAULT 0,
        FOREIGN KEY (request_id) REFERENCES supplier_request(id)
          ON DELETE CASCADE ON UPDATE CASCADE,
        FOREIGN KEY (item_id)    REFERENCES item(id)
          ON DELETE RESTRICT ON UPDATE CASCADE
      );
    ''');

    // Indexes
    await db.execute('CREATE INDEX idx_item_category           ON item(category_id);');
    await db.execute('CREATE INDEX idx_item_supplier           ON item(supplier_id);');
    await db.execute('CREATE INDEX idx_item_created_by         ON item(created_by);'); // 👈 NEW
    await db.execute('CREATE INDEX idx_stock_item              ON stock(item_id);');
    await db.execute('CREATE INDEX idx_stock_supplier          ON stock(supplier_id);');
    await db.execute('CREATE INDEX idx_payment_user            ON payment(user_id);');
    await db.execute('CREATE INDEX idx_payment_sale_invoice_id ON payment(sale_invoice_id);');
    await db.execute('CREATE INDEX idx_invoice_sale_invoice_id ON invoice(sale_invoice_id);');
    await db.execute('CREATE INDEX idx_req_supplier            ON supplier_request(supplier_id);');
    await db.execute('CREATE INDEX idx_ri_request              ON supplier_request_item(request_id);');
    await db.execute('CREATE INDEX idx_ri_item                 ON supplier_request_item(item_id);');

    // Seed data
    await db.transaction((txn) async {
      final now = DateTime.now().millisecondsSinceEpoch;

      await txn.insert('user', {
        'id': 1,
        'name': 'Cashier 1',
        'email': 'cashier1@demo.lk',
        'contact': '0770000001',
        'password': _hashPassword('password1'),
        'role': 'Cashier',
        'color_code': '#000000',
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('user', {
        'id': 2,
        'name': 'Manager',
        'email': 'manager@demo.lk',
        'contact': '0770000002',
        'password': _hashPassword('password2'),
        'role': 'Manager',
        'color_code': '#000000',
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('user', {
        'id': 3,
        'name': 'Stockkeeper',
        'email': 'stock@demo.lk',
        'contact': '0770000003',
        'password': _hashPassword('stock123'),
        'role': 'StockKeeper',
        'color_code': '#FF0000',
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('customer', {
        'id': 1,
        'name': 'John Doe',
        'contact': '0771234567',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await txn.insert('customer', {
        'id': 2,
        'name': 'Jane Smith',
        'contact': '0779876543',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('supplier', {
        'id': 1,
        'name': 'Default Supplier',
        'contact': '+94 77 000 0000',
        'email': 'supplier@demo.lk',
        'address': 'Colombo',
        'brand': 'Generic',
        'color_code': '#000000',
        'location': 'LK',
        'status': 'ACTIVE',
        'preferred': 1,
        'payment_terms': 'NET 30',
        'notes': 'Seed supplier',
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      // Categories (same as before)
      await txn.insert('category', {
        'id': 1,
        'category': 'Beverages',
        'color_code': '#FF5733',
        'category_image': 'beverages.png',
      });
      await txn.insert('category', {
        'id': 2,
        'category': 'Snacks',
        'color_code': '#33FF57',
        'category_image': 'snacks.png',
      });
      await txn.insert('category', {
        'id': 3,
        'category': 'Stationery',
        'color_code': '#3357FF',
        'category_image': 'stationery.png',
      });
      await txn.insert('category', {
        'id': 4,
        'category': 'Dairy',
        'color_code': '#FFE082',
        'category_image': 'dairy.png',
      });
      await txn.insert('category', {
        'id': 5,
        'category': 'Bakery',
        'color_code': '#FBC02D',
        'category_image': 'bakery.png',
      });
      await txn.insert('category', {
        'id': 6,
        'category': 'Frozen',
        'color_code': '#80DEEA',
        'category_image': 'frozen.png',
      });
      await txn.insert('category', {
        'id': 7,
        'category': 'Produce',
        'color_code': '#81C784',
        'category_image': 'produce.png',
      });
      await txn.insert('category', {
        'id': 8,
        'category': 'Household',
        'color_code': '#90A4AE',
        'category_image': 'household.png',
      });
      await txn.insert('category', {
        'id': 9,
        'category': 'Personal Care',
        'color_code': '#B39DDB',
        'category_image': 'personal_care.png',
      });
      await txn.insert('category', {
        'id': 10,
        'category': 'Baby',
        'color_code': '#F48FB1',
        'category_image': 'baby.png',
      });

      // Items (seed) — with created_by = 3 (Stockkeeper)
      Future<void> seedItem(Map<String, Object?> row) async {
        await txn.insert('item', row, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      await seedItem({
        'id': 1,
        'name': 'Coca Cola 500ml',
        'barcode': 'BARC0001',
        'category_id': 1,
        'supplier_id': 1,
        'color_code': '#FF0000',
        'created_by': 3,
      });
      await seedItem({
        'id': 2,
        'name': 'Potato Chips 100g',
        'barcode': 'BARC0002',
        'category_id': 2,
        'supplier_id': 1,
        'color_code': '#FFD700',
        'created_by': 3,
      });
      await seedItem({
        'id': 3,
        'name': 'A4 Paper Ream',
        'barcode': 'BARC0003',
        'category_id': 3,
        'supplier_id': 1,
        'color_code': '#FFFFFF',
        'created_by': 3,
      });
      await seedItem({
        'id': 4,
        'name': 'Fresh Milk 1L',
        'barcode': 'BARC0004',
        'category_id': 4,
        'supplier_id': 1,
        'color_code': '#FFF9C4',
        'created_by': 3,
      });
      await seedItem({
        'id': 5,
        'name': 'Cheddar Cheese 200g',
        'barcode': 'BARC0005',
        'category_id': 4,
        'supplier_id': 1,
        'color_code': '#FFECB3',
        'created_by': 3,
      });
      await seedItem({
        'id': 6,
        'name': 'White Bread Loaf',
        'barcode': 'BARC0006',
        'category_id': 5,
        'supplier_id': 1,
        'color_code': '#FFE0B2',
        'created_by': 3,
      });
      await seedItem({
        'id': 7,
        'name': 'Chocolate Donut',
        'barcode': 'BARC0007',
        'category_id': 5,
        'supplier_id': 1,
        'color_code': '#D7CCC8',
        'created_by': 3,
      });
      await seedItem({
        'id': 8,
        'name': 'Frozen Peas 500g',
        'barcode': 'BARC0008',
        'category_id': 6,
        'supplier_id': 1,
        'color_code': '#A5D6A7',
        'created_by': 3,
      });
      await seedItem({
        'id': 9,
        'name': 'Vanilla Ice Cream 1L',
        'barcode': 'BARC0009',
        'category_id': 6,
        'supplier_id': 1,
        'color_code': '#FFFDE7',
        'created_by': 3,
      });
      await seedItem({
        'id': 10,
        'name': 'Bananas 1kg',
        'barcode': 'BARC0010',
        'category_id': 7,
        'supplier_id': 1,
        'color_code': '#FFF59D',
        'created_by': 3,
      });
      await seedItem({
        'id': 11,
        'name': 'Tomatoes 500g',
        'barcode': 'BARC0011',
        'category_id': 7,
        'supplier_id': 1,
        'color_code': '#FF8A80',
        'created_by': 3,
      });
      await seedItem({
        'id': 12,
        'name': 'Laundry Detergent 1kg',
        'barcode': 'BARC0012',
        'category_id': 8,
        'supplier_id': 1,
        'color_code': '#B0BEC5',
        'created_by': 3,
      });
      await seedItem({
        'id': 13,
        'name': 'Dishwashing Liquid 500ml',
        'barcode': 'BARC0013',
        'category_id': 8,
        'supplier_id': 1,
        'color_code': '#B2EBF2',
        'created_by': 3,
      });
      await seedItem({
        'id': 14,
        'name': 'Shampoo 400ml',
        'barcode': 'BARC0014',
        'category_id': 9,
        'supplier_id': 1,
        'color_code': '#CE93D8',
        'created_by': 3,
      });
      await seedItem({
        'id': 15,
        'name': 'Baby Diapers M (20 pcs)',
        'barcode': 'BARC0015',
        'category_id': 10,
        'supplier_id': 1,
        'color_code': '#F8BBD0',
        'created_by': 3,
      });

      // Payments (unchanged)
      await txn.insert('payment', {
        'id': 1,
        'amount': 1500.00,
        'remain_amount': 500.00,
        'date': now,
        'file_name': 'receipt1.pdf',
        'type': 'Cash',
        'sale_invoice_id': 'puka-001',
        'user_id': 1,
        'customer_contact': '0771234567',
        'discount_type': 'no',
        'discount_value': 0.0,
      });
      await txn.insert('payment', {
        'id': 2,
        'amount': 2500.50,
        'remain_amount': 0.00,
        'date': now - const Duration(days: 1).inMilliseconds,
        'file_name': 'receipt2.pdf',
        'type': 'Card',
        'sale_invoice_id': 'INV-002',
        'user_id': 1,
        'customer_contact': '0779876543',
        'discount_type': 'no',
        'discount_value': 0.0,
      });
      await txn.insert('payment', {
        'id': 3,
        'amount': 350.75,
        'remain_amount': 50.00,
        'date': now - const Duration(days: 2).inMilliseconds,
        'file_name': 'receipt3.pdf',
        'type': 'Cash',
        'sale_invoice_id': 'INV-003',
        'user_id': 2,
        'customer_contact': null,
        'discount_type': 'no',
        'discount_value': 0.0,
      });

      // Invoices (unchanged)
      await txn.insert('invoice', {
        'batch_id': 'BATCH-COCA-002',
        'item_id': 1,
        'quantity': 10,
        'unit_saled_price': 65.0,
        'sale_invoice_id': 'puka-001',
      });
      await txn.insert('invoice', {
        'batch_id': 'BATCH-CHIPS-001',
        'item_id': 2,
        'quantity': 5,
        'unit_saled_price': 100.0,
        'sale_invoice_id': 'puka-001',
      });
      await txn.insert('invoice', {
        'batch_id': 'BATCH-PAPER-001',
        'item_id': 3,
        'quantity': 2,
        'unit_saled_price': 480.0,
        'sale_invoice_id': 'INV-002',
      });

      // Stock (unchanged)
      await txn.insert('stock', {
        'batch_id': 'BATCH001',
        'item_id': 1,
        'quantity': 50,
        'unit_price': 80.00,
        'sell_price': 120.00,
        'discount_amount': 0,
        'supplier_id': 1,
      });
      await txn.insert('stock', {
        'batch_id': 'BATCH002',
        'item_id': 1,
        'quantity': 50,
        'unit_price': 80.00,
        'sell_price': 120.00,
        'discount_amount': 10.00,
        'supplier_id': 1,
      });
      await txn.insert('stock', {
        'batch_id': 'BATCH002',
        'item_id': 2,
        'quantity': 40,
        'unit_price': 60.00,
        'sell_price': 100.00,
        'discount_amount': 0,
        'supplier_id': 1,
      });
      await txn.insert('stock', {
        'batch_id': 'BATCH003',
        'item_id': 3,
        'quantity': 30,
        'unit_price': 450.00,
        'sell_price': 600.00,
        'discount_amount': 50.00,
        'supplier_id': 1,
      });
      await txn.insert('stock', {
        'batch_id': 'BATCH004',
        'item_id': 4,
        'quantity': 100,
        'unit_price': 180.00,
        'sell_price': 250.00,
        'discount_amount': 0,
        'supplier_id': 1,
      });
      await txn.insert('stock', {
        'batch_id': 'BATCH005',
        'item_id': 5,
        'quantity': 20,
        'unit_price': 400.00,
        'sell_price': 550.00,
        'discount_amount': 20.00,
        'supplier_id': 1,
      });
      await txn.insert('stock', {
        'batch_id': 'BATCH006',
        'item_id': 6,
        'quantity': 70,
        'unit_price': 100.00,
        'sell_price': 160.00,
        'discount_amount': 0,
        'supplier_id': 1,
      });
      await txn.insert('stock', {
        'batch_id': 'BATCH007',
        'item_id': 7,
        'quantity': 50,
        'unit_price': 80.00,
        'sell_price': 120.00,
        'discount_amount': 10.00,
        'supplier_id': 1,
      });
      await txn.insert('stock', {
        'batch_id': 'BATCH008',
        'item_id': 8,
        'quantity': 60,
        'unit_price': 200.00,
        'sell_price': 300.00,
        'discount_amount': 0,
        'supplier_id': 1,
      });
      await txn.insert('stock', {
        'batch_id': 'BATCH009',
        'item_id': 9,
        'quantity': 25,
        'unit_price': 450.00,
        'sell_price': 600.00,
        'discount_amount': 50.00,
        'supplier_id': 1,
      });
      await txn.insert('stock', {
        'batch_id': 'BATCH010',
        'item_id': 10,
        'quantity': 80,
        'unit_price': 120.00,
        'sell_price': 180.00,
        'discount_amount': 0,
        'supplier_id': 1,
      });
      await txn.insert('stock', {
        'batch_id': 'BATCH011',
        'item_id': 11,
        'quantity': 90,
        'unit_price': 80.00,
        'sell_price': 130.00,
        'discount_amount': 0,
        'supplier_id': 1,
      });
      await txn.insert('stock', {
        'batch_id': 'BATCH012',
        'item_id': 12,
        'quantity': 35,
        'unit_price': 600.00,
        'sell_price': 800.00,
        'discount_amount': 0,
        'supplier_id': 1,
      });
      await txn.insert('stock', {
        'batch_id': 'BATCH013',
        'item_id': 13,
        'quantity': 45,
        'unit_price': 150.00,
        'sell_price': 250.00,
        'discount_amount': 20.00,
        'supplier_id': 1,
      });
      await txn.insert('stock', {
        'batch_id': 'BATCH014',
        'item_id': 14,
        'quantity': 50,
        'unit_price': 300.00,
        'sell_price': 450.00,
        'discount_amount': 30.00,
        'supplier_id': 1,
      });
      await txn.insert('stock', {
        'batch_id': 'BATCH015',
        'item_id': 15,
        'quantity': 20,
        'unit_price': 700.00,
        'sell_price': 950.00,
        'discount_amount': 50.00,
        'supplier_id': 1,
      });
    });
  }

  @override
  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // v1 -> v2: add created_by to item and index it
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE item ADD COLUMN created_by INTEGER;');
      // Backfill existing rows to a sensible default (Stockkeeper = 3 if exists, else 1)
      final countStockkeeper = Sqflite.firstIntValue(
            await db.rawQuery("SELECT COUNT(*) FROM user WHERE id = 3"),
          ) ??
          0;
      final defaultCreator = (countStockkeeper ?? 0) > 0 ? 3 : 1;
      await db.rawUpdate('UPDATE item SET created_by = ? WHERE created_by IS NULL;', [defaultCreator]);

      await db.execute('CREATE INDEX IF NOT EXISTS idx_item_created_by ON item(created_by);');
    }
  }

  Future<void> clearDatabase() async {
    final dbPath = p.join(await getDatabasesPath(), _dbName);
    await deleteDatabase(dbPath);
    _db = null;
  }

  Future<void> resetDatabase() async {
    final path = p.join(await getDatabasesPath(), _dbName);
    await deleteDatabase(path);
    _db = null;
  }

  Future<T> runInTransaction<T>(Future<T> Function(Transaction tx) action) async {
    final db = await database;
    return db.transaction<T>(action);
  }
}
