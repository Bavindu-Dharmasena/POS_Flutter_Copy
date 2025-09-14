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
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const _dbName = 'pos.db';
  static const _dbVersion = 12;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, _dbName);

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
    // -------- Root tables --------
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

    // -------- Dependent tables --------
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
      CREATE TABLE invoice (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  batch_id         TEXT    NOT NULL,
  item_id          INTEGER NOT NULL,
  quantity         INTEGER NOT NULL,
  unit_saled_price           REAL    NOT NULL,
  sale_invoice_id  TEXT    NOT NULL,
  FOREIGN KEY (item_id)         REFERENCES item(id)                 ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (sale_invoice_id) REFERENCES payment(sale_invoice_id) ON DELETE CASCADE  ON UPDATE CASCADE
);
    ''');
    await db.execute(
      'CREATE INDEX idx_invoice_sale_invoice_id ON invoice(sale_invoice_id);'
    );

    await db.execute('''
      CREATE TABLE payment (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  amount           REAL    NOT NULL,
  remain_amount    REAL    NOT NULL,
  date             INTEGER NOT NULL,        -- epoch millis
  file_name        TEXT    NOT NULL,
  type             TEXT    NOT NULL,
  sale_invoice_id  TEXT    NOT NULL,        -- TEXT
  user_id          INTEGER NOT NULL,
  customer_contact TEXT,
  UNIQUE (sale_invoice_id),
  FOREIGN KEY (user_id)           REFERENCES user(id)           ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (customer_contact)  REFERENCES customer(contact)  ON DELETE SET NULL   ON UPDATE CASCADE
);
    ''');
    await db.execute(
      'CREATE INDEX idx_payment_sale_invoice_id ON payment(sale_invoice_id);'
    );
    await db.execute('CREATE INDEX idx_item_category ON item(category_id);');
    await db.execute('CREATE INDEX idx_item_supplier ON item(supplier_id);');
    await db.execute('CREATE INDEX idx_stock_item ON stock(item_id);');
    await db.execute('CREATE INDEX idx_stock_supplier ON stock(supplier_id);');
    await db.execute('CREATE INDEX idx_payment_user ON payment(user_id);');

    // -------- Seed data (in one transaction; parents first) --------
    await db.transaction((txn) async {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Users (explicit IDs 1 & 2 so later FKs match)
      await txn.insert('user', {
        'id': 1,
        'name': 'Cashier 1',
        'email': 'cashier1@demo.lk',
        'contact': '0770000001',
        'password': 'hashed_pw_1',
        'role': 'Cashier',
        'color_code': '#000000',
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('user', {
        'id': 2,
        'name': 'Cashier 2',
        'email': 'cashier2@demo.lk',
        'contact': '0770000002',
        'password': 'hashed_pw_2',
        'role': 'Cashier',
        'color_code': '#000000',
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      // Customers (contacts must exist for FK)
      await txn.insert('customer', {
        'id': 1,
        'name': 'John',
        'contact': '0771234567',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('customer', {
        'id': 2,
        'name': 'Jane',
        'contact': '0779876543',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      // Supplier
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

      // Categories (fix duplicate id)
      await txn.insert('category', {
        'id': 1,
        'category': 'Beverages',
        'color_code': '#FF5733',
        'category_image': 'beverages.png',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('category', {
        'id': 2,
        'category': 'Snacks',
        'color_code': '#33FF57',
        'category_image': 'snacks.png',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('category', {
        'id': 3,
        'category': 'Stationery',
        'color_code': '#3357FF',
        'category_image': 'household.png',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      // ===== More Categories =====
      await txn.insert('category', {
        'id': 4,
        'category': 'Dairy',
        'color_code': '#FFE082',
        'category_image': 'dairy.png',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('category', {
        'id': 5,
        'category': 'Bakery',
        'color_code': '#FBC02D',
        'category_image': 'bakery.png',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('category', {
        'id': 6,
        'category': 'Frozen',
        'color_code': '#80DEEA',
        'category_image': 'frozen.png',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('category', {
        'id': 7,
        'category': 'Produce',
        'color_code': '#81C784',
        'category_image': 'produce.png',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('category', {
        'id': 8,
        'category': 'Household',
        'color_code': '#90A4AE',
        'category_image': 'household.png',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('category', {
        'id': 9,
        'category': 'Personal Care',
        'color_code': '#B39DDB',
        'category_image': 'personal_care.png',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('category', {
        'id': 10,
        'category': 'Baby',
        'color_code': '#F48FB1',
        'category_image': 'baby.png',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      // Items
      await txn.insert('item', {
        'id': 1,
        'name': 'Coca Cola 500ml',
        'barcode': 'BARC0001',
        'category_id': 1,
        'supplier_id': 1,
        'color_code': '#FF0000',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('item', {
        'id': 2,
        'name': 'Potato Chips 100g',
        'barcode': 'BARC0002',
        'category_id': 2,
        'supplier_id': 1,
        'color_code': '#FFD700',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('item', {
        'id': 3,
        'name': 'A4 Paper Ream',
        'barcode': 'BARC0003',
        'category_id': 3,
        'supplier_id': 1,
        'color_code': '#FFFFFF',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('item', {
        'id': 4,
        'name': 'Fresh Milk 1L',
        'barcode': 'BARC0004',
        'category_id': 4, // Dairy
        'supplier_id': 1,
        'color_code': '#FFF9C4',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('item', {
        'id': 5,
        'name': 'Cheddar Cheese 200g',
        'barcode': 'BARC0005',
        'category_id': 4, // Dairy
        'supplier_id': 1,
        'color_code': '#FFECB3',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('item', {
        'id': 6,
        'name': 'White Bread Loaf',
        'barcode': 'BARC0006',
        'category_id': 5, // Bakery
        'supplier_id': 1,
        'color_code': '#FFE0B2',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('item', {
        'id': 7,
        'name': 'Chocolate Donut',
        'barcode': 'BARC0007',
        'category_id': 5, // Bakery
        'supplier_id': 1,
        'color_code': '#D7CCC8',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('item', {
        'id': 8,
        'name': 'Frozen Peas 500g',
        'barcode': 'BARC0008',
        'category_id': 6, // Frozen
        'supplier_id': 1,
        'color_code': '#A5D6A7',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('item', {
        'id': 9,
        'name': 'Vanilla Ice Cream 1L',
        'barcode': 'BARC0009',
        'category_id': 6, // Frozen
        'supplier_id': 1,
        'color_code': '#FFFDE7',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('item', {
        'id': 10,
        'name': 'Bananas 1kg',
        'barcode': 'BARC0010',
        'category_id': 7, // Produce
        'supplier_id': 1,
        'color_code': '#FFF59D',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('item', {
        'id': 11,
        'name': 'Tomatoes 500g',
        'barcode': 'BARC0011',
        'category_id': 7, // Produce
        'supplier_id': 1,
        'color_code': '#FF8A80',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('item', {
        'id': 12,
        'name': 'Laundry Detergent 1kg',
        'barcode': 'BARC0012',
        'category_id': 8, // Household
        'supplier_id': 1,
        'color_code': '#B0BEC5',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('item', {
        'id': 13,
        'name': 'Dishwashing Liquid 500ml',
        'barcode': 'BARC0013',
        'category_id': 8, // Household
        'supplier_id': 1,
        'color_code': '#B2EBF2',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('item', {
        'id': 14,
        'name': 'Shampoo 400ml',
        'barcode': 'BARC0014',
        'category_id': 9, // Personal Care
        'supplier_id': 1,
        'color_code': '#CE93D8',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('item', {
        'id': 15,
        'name': 'Baby Diapers M (20 pcs)',
        'barcode': 'BARC0015',
        'category_id': 10, // Baby
        'supplier_id': 1,
        'color_code': '#F8BBD0',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      // Stock
      await txn.insert('stock', {
        'batch_id': 'BATCH-COCA-002',
        'item_id': 1,
        'quantity': 100,
        'unit_price': 50,
        'sell_price': 65,
        'discount_amount': 0,
        'supplier_id': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('stock', {
        'batch_id': 'BATCH-CHIPS-001',
        'item_id': 2,
        'quantity': 200,
        'unit_price': 80,
        'sell_price': 100,
        'discount_amount': 0,
        'supplier_id': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('stock', {
        'batch_id': 'BATCH-CHIPS-002',
        'item_id': 2,
        'quantity': 200,
        'unit_price': 80,
        'sell_price': 100,
        'discount_amount': 0,
        'supplier_id': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('stock', {
        'batch_id': 'BATCH-PAPER-001',
        'item_id': 3,
        'quantity': 50,
        'unit_price': 400,
        'sell_price': 480,
        'discount_amount': 0,
        'supplier_id': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('stock', {
        'batch_id': 'BATCH-PAPER-002',
        'item_id': 3,
        'quantity': 50,
        'unit_price': 400,
        'sell_price': 480,
        'discount_amount': 0,
        'supplier_id': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      // ===== More Stock Batches (unique batch_id + valid item_id + supplier_id) =====
      await txn.insert('stock', {
        'batch_id': 'BATCH-MILK-001',
        'item_id': 4,
        'quantity': 120,
        'unit_price': 220.0,
        'sell_price': 260.0,
        'discount_amount': 0,
        'supplier_id': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('stock', {
        'batch_id': 'BATCH-MILK-002',
        'item_id': 4,
        'quantity': 150,
        'unit_price': 215.0,
        'sell_price': 255.0,
        'discount_amount': 10.0,
        'supplier_id': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('stock', {
        'batch_id': 'BATCH-CHED-001',
        'item_id': 5,
        'quantity': 80,
        'unit_price': 650.0,
        'sell_price': 740.0,
        'discount_amount': 0,
        'supplier_id': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('stock', {
        'batch_id': 'BATCH-CHED-002',
        'item_id': 5,
        'quantity': 60,
        'unit_price': 640.0,
        'sell_price': 735.0,
        'discount_amount': 15.0,
        'supplier_id': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('stock', {
        'batch_id': 'BATCH-BREAD-001',
        'item_id': 6,
        'quantity': 90,
        'unit_price': 120.0,
        'sell_price': 160.0,
        'discount_amount': 0,
        'supplier_id': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('stock', {
        'batch_id': 'BATCH-DONUT-001',
        'item_id': 7,
        'quantity': 150,
        'unit_price': 60.0,
        'sell_price': 100.0,
        'discount_amount': 5.0,
        'supplier_id': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('stock', {
        'batch_id': 'BATCH-PEAS-001',
        'item_id': 8,
        'quantity': 200,
        'unit_price': 240.0,
        'sell_price': 300.0,
        'discount_amount': 0,
        'supplier_id': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('stock', {
        'batch_id': 'BATCH-PEAS-002',
        'item_id': 8,
        'quantity': 220,
        'unit_price': 235.0,
        'sell_price': 295.0,
        'discount_amount': 10.0,
        'supplier_id': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('stock', {
        'batch_id': 'BATCH-ICE-001',
        'item_id': 9,
        'quantity': 100,
        'unit_price': 850.0,
        'sell_price': 980.0,
        'discount_amount': 0,
        'supplier_id': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('stock', {
        'batch_id': 'BATCH-ICE-002',
        'item_id': 9,
        'quantity': 120,
        'unit_price': 840.0,
        'sell_price': 970.0,
        'discount_amount': 20.0,
        'supplier_id': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('stock', {
        'batch_id': 'BATCH-BAN-001',
        'item_id': 10,
        'quantity': 180,
        'unit_price': 140.0,
        'sell_price': 200.0,
        'discount_amount': 0,
        'supplier_id': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('stock', {
        'batch_id': 'BATCH-TOM-001',
        'item_id': 11,
        'quantity': 160,
        'unit_price': 180.0,
        'sell_price': 240.0,
        'discount_amount': 0,
        'supplier_id': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('stock', {
        'batch_id': 'BATCH-LAUN-001',
        'item_id': 12,
        'quantity': 90,
        'unit_price': 900.0,
        'sell_price': 1050.0,
        'discount_amount': 50.0,
        'supplier_id': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('stock', {
        'batch_id': 'BATCH-DISH-001',
        'item_id': 13,
        'quantity': 120,
        'unit_price': 280.0,
        'sell_price': 360.0,
        'discount_amount': 0,
        'supplier_id': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('stock', {
        'batch_id': 'BATCH-SHAM-001',
        'item_id': 14,
        'quantity': 110,
        'unit_price': 520.0,
        'sell_price': 640.0,
        'discount_amount': 0,
        'supplier_id': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('stock', {
        'batch_id': 'BATCH-BABY-001',
        'item_id': 15,
        'quantity': 140,
        'unit_price': 1150.0,
        'sell_price': 1350.0,
        'discount_amount': 0,
        'supplier_id': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      // Extra duplicates/variants for better coverage
      await txn.insert('stock', {
        'batch_id': 'BATCH-BREAD-002',
        'item_id': 6,
        'quantity': 110,
        'unit_price': 118.0,
        'sell_price': 158.0,
        'discount_amount': 5.0,
        'supplier_id': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('stock', {
        'batch_id': 'BATCH-DONUT-002',
        'item_id': 7,
        'quantity': 130,
        'unit_price': 62.0,
        'sell_price': 102.0,
        'discount_amount': 0.0,
        'supplier_id': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('stock', {
        'batch_id': 'BATCH-BAN-002',
        'item_id': 10,
        'quantity': 160,
        'unit_price': 138.0,
        'sell_price': 198.0,
        'discount_amount': 0.0,
        'supplier_id': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('stock', {
        'batch_id': 'BATCH-TOM-002',
        'item_id': 11,
        'quantity': 150,
        'unit_price': 182.0,
        'sell_price': 238.0,
        'discount_amount': 5.0,
        'supplier_id': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('stock', {
        'batch_id': 'BATCH-PEAS-003',
        'item_id': 8,
        'quantity': 180,
        'unit_price': 238.0,
        'sell_price': 298.0,
        'discount_amount': 10.0,
        'supplier_id': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);


      // Payments (children, last)
      await txn.insert('payment', {
        'id': 1,
        'amount': 1500.00,
        'remain_amount': 500.00,
        'date': now,
        'file_name': 'receipt1.pdf',
        'type': 'Cash',
        'sale_invoice_id': 1, // exists
        'user_id': 1, // exists
        'customer_contact': '0771234567', // exists
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('payment', {
        'id': 2,
        'amount': 2500.50,
        'remain_amount': 0.00,
        'date': now - const Duration(days: 1).inMilliseconds,
        'file_name': 'receipt2.pdf',
        'type': 'Card',
        'sale_invoice_id': 2,
        'user_id': 1,
        'customer_contact': '0779876543',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('payment', {
        'id': 3,
        'amount': 350.75,
        'remain_amount': 50.00,
        'date': now - const Duration(days: 2).inMilliseconds,
        'file_name': 'receipt3.pdf',
        'type': 'Cash',
        'sale_invoice_id': 3,
        'user_id': 2,
        'customer_contact': null,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    });
  }

 @override
FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 3) {
    await db.execute('PRAGMA foreign_keys = OFF;');
    await db.transaction((txn) async {
      // --- rebuild PAYMENT ---
      await txn.execute('''
        CREATE TABLE payment_new (
          id               INTEGER PRIMARY KEY AUTOINCREMENT,
          amount           REAL    NOT NULL,
          remain_amount    REAL    NOT NULL,
          date             INTEGER NOT NULL,
          file_name        TEXT    NOT NULL,
          type             TEXT    NOT NULL,
          sale_invoice_id  TEXT    NOT NULL,
          user_id          INTEGER NOT NULL,
          customer_contact TEXT,
          UNIQUE (sale_invoice_id),
          FOREIGN KEY (user_id)           REFERENCES user(id)           ON DELETE RESTRICT ON UPDATE CASCADE,
          FOREIGN KEY (customer_contact)  REFERENCES customer(contact)  ON DELETE SET NULL   ON UPDATE CASCADE
        );
      ''');

      await txn.execute('''
        INSERT OR IGNORE INTO payment_new
          (id, amount, remain_amount, date, file_name, type, sale_invoice_id, user_id, customer_contact)
        SELECT id, amount, remain_amount, date, file_name, type, sale_invoice_id, user_id, customer_contact
        FROM payment;
      ''');

      // --- rebuild INVOICE (FK -> payment.sale_invoice_id) ---
      await txn.execute('''
        CREATE TABLE invoice_new (
          id               INTEGER PRIMARY KEY AUTOINCREMENT,
          batch_id         TEXT    NOT NULL,
          item_id          INTEGER NOT NULL,
          quantity         INTEGER NOT NULL,
          unit_saled_price           REAL    NOT NULL,
          sale_invoice_id  TEXT    NOT NULL,
          FOREIGN KEY (item_id)         REFERENCES item(id)                 ON DELETE RESTRICT ON UPDATE CASCADE,
          FOREIGN KEY (sale_invoice_id) REFERENCES payment(sale_invoice_id) ON DELETE CASCADE  ON UPDATE CASCADE
        );
      ''');

      await txn.execute('''
        INSERT OR IGNORE INTO invoice_new
          (id, batch_id, item_id, quantity, sale_invoice_id)
        SELECT id, batch_id, item_id, quantity, sale_invoice_id
        FROM invoice;
      ''');

      // Swap
      await txn.execute('DROP TABLE IF EXISTS invoice;');
      await txn.execute('DROP TABLE IF EXISTS payment;');
      await txn.execute('ALTER TABLE payment_new RENAME TO payment;');
      await txn.execute('ALTER TABLE invoice_new RENAME TO invoice;');

      // Indexes
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_payment_sale_invoice_id ON payment(sale_invoice_id);');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_invoice_sale_invoice_id ON invoice(sale_invoice_id);');

      // If a 'sale' table exists, drop it
      await txn.execute('DROP TABLE IF EXISTS sale;');
    });
    await db.execute('PRAGMA foreign_keys = ON;');
  }
}


  Future<T> runInTransaction<T>(
    Future<T> Function(Transaction tx) action,
  ) async {
    final db = await database;
    return db.transaction<T>(action);
  }
}
