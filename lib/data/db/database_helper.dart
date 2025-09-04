// import 'dart:async';
// import 'package:path/path.dart' as p;
// import 'package:path_provider/path_provider.dart';
// import 'package:sqflite/sqflite.dart';

// class DatabaseHelper {
//   DatabaseHelper._internal();
//   static final DatabaseHelper instance = DatabaseHelper._internal();

//   static const _dbName = 'app.db';
//   static const _dbVersion = 1;

//   Database? _db;

//   Future<Database> get database async {
//     if (_db != null) return _db!;
//     _db = await _initDB();
//     return _db!;
//   }

//   Future<Database> _initDB() async {
//     final dir = await getApplicationDocumentsDirectory();
//     final dbPath = p.join(dir.path, _dbName);

//     return await openDatabase(
//       dbPath,
//       version: _dbVersion,
//       onCreate: _onCreate,
//       onConfigure: (db) async {
//         await db.execute('PRAGMA foreign_keys = ON');
//       },
//     );
//   }

//   FutureOr<void> _onCreate(Database db, int version) async {
//     await db.execute('''
//       CREATE TABLE todos (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         title TEXT NOT NULL,
//         description TEXT,
//         is_done INTEGER NOT NULL DEFAULT 0,
//         created_at INTEGER NOT NULL
//       );
//     ''');
//     // Seed example
//     await db.insert('todos', {
//       'title': 'Welcome to SQLite CRUD',
//       'description': 'Tap to edit, swipe to delete, check to complete.',
//       'is_done': 0,
//       'created_at': DateTime.now().millisecondsSinceEpoch,
//     });
//   }
// }

//---------------------------------------------------------------------

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const _dbName = 'pos.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    // On web, the factory stores in IndexedDB and only needs a name.
    // On mobile/desktop, use getDatabasesPath().
    final String dbPath = kIsWeb ? _dbName : p.join(await getDatabasesPath(), _dbName);

    return await openDatabase(
      dbPath,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    // === keep your existing schema & seed exactly as you already wrote ===
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

    await db.execute('''
      CREATE TABLE customer (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        name     TEXT    NOT NULL,
        contact  TEXT    NOT NULL UNIQUE
      );
    ''');

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
        status         TEXT    CHECK (status IN ('ACTIVE','INACTIVE','PENDING')),
        preferred      INTEGER NOT NULL DEFAULT 0,
        payment_terms  TEXT,
        notes          TEXT,
        created_at     INTEGER NOT NULL,
        updated_at     INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE category (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        category       TEXT    NOT NULL,
        color_code     TEXT    NOT NULL,
        category_image TEXT
      );
    ''');

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

    await db.execute('''
      CREATE TABLE sale (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        date     INTEGER NOT NULL,
        total    REAL    NOT NULL,
        user_id  INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE RESTRICT ON UPDATE CASCADE
      );
    ''');

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
    await db.execute('CREATE INDEX idx_invoice_sale_invoice_id ON invoice(sale_invoice_id);');

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
    await db.execute('CREATE INDEX idx_payment_sale_invoice_id ON payment(sale_invoice_id);');

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

    await db.execute('CREATE INDEX idx_item_category ON item(category_id);');
    await db.execute('CREATE INDEX idx_item_supplier ON item(supplier_id);');
    await db.execute('CREATE INDEX idx_stock_item ON stock(item_id);');
    await db.execute('CREATE INDEX idx_stock_supplier ON stock(supplier_id);');
    await db.execute('CREATE INDEX idx_sale_user ON sale(user_id);');
    await db.execute('CREATE INDEX idx_payment_user ON payment(user_id);');

    // ---- seed (unchanged) ----
    final now = DateTime.now().millisecondsSinceEpoch;
    final supplierId1 = await db.insert('supplier', {
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
    });

    await db.insert('category', {'id': 1, 'category': 'Beverages',  'color_code': '#FF5733', 'category_image': 'beverages.png'});
    await db.insert('category', {'id': 2, 'category': 'Snacks',     'color_code': '#33FF57', 'category_image': 'snacks.png'});
    await db.insert('category', {'id': 3, 'category': 'Stationery', 'color_code': '#3357FF', 'category_image': 'household.png'});

    await db.insert('item', {'id': 1, 'name': 'Coca Cola 500ml',     'barcode': 'BARC0001', 'category_id': 1, 'supplier_id': supplierId1, 'color_code': '#FF0000'});
    await db.insert('item', {'id': 2, 'name': 'Potato Chips 100g',   'barcode': 'BARC0002', 'category_id': 2, 'supplier_id': supplierId1, 'color_code': '#FFD700'});
    await db.insert('item', {'id': 3, 'name': 'A4 Paper Ream',       'barcode': 'BARC0003', 'category_id': 3, 'supplier_id': supplierId1, 'color_code': '#FFFFFF'});

    await db.insert('stock', {'batch_id': 'BATCH-COCA-002', 'item_id': 1, 'quantity': 100, 'unit_price': 50,  'sell_price': 65,  'discount_amount': 0, 'supplier_id': supplierId1});
    await db.insert('stock', {'batch_id': 'BATCH-CHIPS-001','item_id': 2, 'quantity': 200, 'unit_price': 80,  'sell_price': 100, 'discount_amount': 0, 'supplier_id': supplierId1});
    await db.insert('stock', {'batch_id': 'BATCH-CHIPS-002','item_id': 2, 'quantity': 200, 'unit_price': 80,  'sell_price': 100, 'discount_amount': 0, 'supplier_id': supplierId1});
    await db.insert('stock', {'batch_id': 'BATCH-PAPER-001','item_id': 3, 'quantity': 50,  'unit_price': 400, 'sell_price': 480, 'discount_amount': 0, 'supplier_id': supplierId1});
    await db.insert('stock', {'batch_id': 'BATCH-PAPER-002','item_id': 3, 'quantity': 50,  'unit_price': 400, 'sell_price': 480, 'discount_amount': 0, 'supplier_id': supplierId1});
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // migrations go here when you bump _dbVersion
  }

  Future<T> runInTransaction<T>(Future<T> Function(Transaction tx) action) async {
    final db = await database;
    return db.transaction<T>(action);
  }
}
