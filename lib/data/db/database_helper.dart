import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const _dbName = 'pos.db';

  /// Bump this number when schema changes (forces onCreate/onUpgrade).
  static const _dbVersion = 1;

  Database? _db;
  Future<Database> get database async => _db ??= await _initDB();

  Future<Database> _initDB() async {
    final String dbPath = kIsWeb
        ? _dbName
        : p.join(await getDatabasesPath(), _dbName);

    return openDatabase(
      dbPath,
      version: _dbVersion,
      onConfigure: (db) async {
        // Enforce foreign keys
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
    // -------------------------------------------------------------------------
    // Tables
    // -------------------------------------------------------------------------

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
        FOREIGN KEY (category_id) REFERENCES category(id) ON DELETE RESTRICT ON UPDATE CASCADE,
        FOREIGN KEY (supplier_id) REFERENCES supplier(id) ON DELETE RESTRICT ON UPDATE CASCADE
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

    // 7) payment (before invoice)
    await db.execute('''
      CREATE TABLE payment (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        amount           REAL    NOT NULL,
        remain_amount    REAL    NOT NULL,
        date             INTEGER NOT NULL,           -- epoch millis
        file_name        TEXT    NOT NULL,
        type             TEXT    NOT NULL,
        sale_invoice_id  TEXT    NOT NULL,           -- unique bill id
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

    // 9) supplier_request (master)
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

    // 10) supplier_request_item (lines)
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

    // 11) price_rule (NEW TABLE)
    await db.execute('''
      CREATE TABLE price_rule (
        id                  TEXT    PRIMARY KEY,
        name                TEXT    NOT NULL,
        type                TEXT    NOT NULL 
                            CHECK (type IN ('PERCENTAGE_DISCOUNT','FIXED_DISCOUNT','MARKUP','BOGO')),
        scope_kind          TEXT    NOT NULL 
                            CHECK (scope_kind IN ('ALL','CATEGORY','PRODUCT','CUSTOMER_GROUP')),
        scope_value         TEXT    NOT NULL DEFAULT '',
        value               REAL    NOT NULL DEFAULT 0,
        stackable           INTEGER NOT NULL DEFAULT 1,
        active              INTEGER NOT NULL DEFAULT 1,
        priority            INTEGER NOT NULL DEFAULT 10,
        per_customer_limit  INTEGER,
        start_time          TEXT,   -- Format: "HH:MM"
        end_time            TEXT,   -- Format: "HH:MM"
        start_date          INTEGER, -- epoch millis
        end_date            INTEGER, -- epoch millis
        days_of_week        TEXT    DEFAULT '', -- comma-separated: "1,2,3" for Mon,Tue,Wed
        created_at          INTEGER NOT NULL,
        updated_at          INTEGER NOT NULL
      );
    ''');

    // -------------------------------------------------------------------------
    // Indexes
    // -------------------------------------------------------------------------
    await db.execute(
      'CREATE INDEX idx_item_category             ON item(category_id);',
    );
    await db.execute(
      'CREATE INDEX idx_item_supplier             ON item(supplier_id);',
    );
    await db.execute(
      'CREATE INDEX idx_stock_item                ON stock(item_id);',
    );
    await db.execute(
      'CREATE INDEX idx_stock_supplier            ON stock(supplier_id);',
    );
    await db.execute(
      'CREATE INDEX idx_payment_user              ON payment(user_id);',
    );
    await db.execute(
      'CREATE INDEX idx_payment_sale_invoice_id   ON payment(sale_invoice_id);',
    );
    await db.execute(
      'CREATE INDEX idx_invoice_sale_invoice_id   ON invoice(sale_invoice_id);',
    );
    await db.execute(
      'CREATE INDEX idx_req_supplier              ON supplier_request(supplier_id);',
    );
    await db.execute(
      'CREATE INDEX idx_ri_request                ON supplier_request_item(request_id);',
    );
    await db.execute(
      'CREATE INDEX idx_ri_item                   ON supplier_request_item(item_id);',
    );

    await db.execute(
      'CREATE INDEX idx_price_rule_active         ON price_rule(active);',
    );
    await db.execute(
      'CREATE INDEX idx_price_rule_priority       ON price_rule(priority);',
    );
    await db.execute(
      'CREATE INDEX idx_price_rule_scope          ON price_rule(scope_kind, scope_value);',
    );
    await db.execute(
      'CREATE INDEX idx_price_rule_dates          ON price_rule(start_date, end_date);',
    );

    // -------------------------------------------------------------------------
    // Seed data
    // -------------------------------------------------------------------------
    await db.transaction((txn) async {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Users
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

      // Customers
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

      // Categories
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

      // Items
      await txn.insert('item', {
        'id': 1,
        'name': 'Coca Cola 500ml',
        'barcode': 'BARC0001',
        'category_id': 1,
        'supplier_id': 1,
        'color_code': '#FF0000',
      });
      await txn.insert('item', {
        'id': 2,
        'name': 'Potato Chips 100g',
        'barcode': 'BARC0002',
        'category_id': 2,
        'supplier_id': 1,
        'color_code': '#FFD700',
      });
      await txn.insert('item', {
        'id': 3,
        'name': 'A4 Paper Ream',
        'barcode': 'BARC0003',
        'category_id': 3,
        'supplier_id': 1,
        'color_code': '#FFFFFF',
      });
      await txn.insert('item', {
        'id': 4,
        'name': 'Fresh Milk 1L',
        'barcode': 'BARC0004',
        'category_id': 4,
        'supplier_id': 1,
        'color_code': '#FFF9C4',
      });
      await txn.insert('item', {
        'id': 5,
        'name': 'Cheddar Cheese 200g',
        'barcode': 'BARC0005',
        'category_id': 4,
        'supplier_id': 1,
        'color_code': '#FFECB3',
      });
      await txn.insert('item', {
        'id': 6,
        'name': 'White Bread Loaf',
        'barcode': 'BARC0006',
        'category_id': 5,
        'supplier_id': 1,
        'color_code': '#FFE0B2',
      });
      await txn.insert('item', {
        'id': 7,
        'name': 'Chocolate Donut',
        'barcode': 'BARC0007',
        'category_id': 5,
        'supplier_id': 1,
        'color_code': '#D7CCC8',
      });
      await txn.insert('item', {
        'id': 8,
        'name': 'Frozen Peas 500g',
        'barcode': 'BARC0008',
        'category_id': 6,
        'supplier_id': 1,
        'color_code': '#A5D6A7',
      });
      await txn.insert('item', {
        'id': 9,
        'name': 'Vanilla Ice Cream 1L',
        'barcode': 'BARC0009',
        'category_id': 6,
        'supplier_id': 1,
        'color_code': '#FFFDE7',
      });
      await txn.insert('item', {
        'id': 10,
        'name': 'Bananas 1kg',
        'barcode': 'BARC0010',
        'category_id': 7,
        'supplier_id': 1,
        'color_code': '#FFF59D',
      });
      await txn.insert('item', {
        'id': 11,
        'name': 'Tomatoes 500g',
        'barcode': 'BARC0011',
        'category_id': 7,
        'supplier_id': 1,
        'color_code': '#FF8A80',
      });
      await txn.insert('item', {
        'id': 12,
        'name': 'Laundry Detergent 1kg',
        'barcode': 'BARC0012',
        'category_id': 8,
        'supplier_id': 1,
        'color_code': '#B0BEC5',
      });
      await txn.insert('item', {
        'id': 13,
        'name': 'Dishwashing Liquid 500ml',
        'barcode': 'BARC0013',
        'category_id': 8,
        'supplier_id': 1,
        'color_code': '#B2EBF2',
      });
      await txn.insert('item', {
        'id': 14,
        'name': 'Shampoo 400ml',
        'barcode': 'BARC0014',
        'category_id': 9,
        'supplier_id': 1,
        'color_code': '#CE93D8',
      });
      await txn.insert('item', {
        'id': 15,
        'name': 'Baby Diapers M (20 pcs)',
        'barcode': 'BARC0015',
        'category_id': 10,
        'supplier_id': 1,
        'color_code': '#F8BBD0',
      });

      // Payments
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

      // Invoices
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

      // Stock
      await txn.insert('stock', {
        'batch_id': 'BATCH001',
        'item_id': 1, // Coca Cola 500ml
        'quantity': 50,
        'unit_price': 80.00,
        'sell_price': 120.00,
        'discount_amount': 0,
        'supplier_id': 1,
      });
      await txn.insert('stock', {
        'batch_id': 'BATCH002',
        'item_id': 1, // Coca Cola 500ml
        'quantity': 50,
        'unit_price': 80.00,
        'sell_price': 120.00,
        'discount_amount': 10.00,
        'supplier_id': 1,
      });

      await txn.insert('stock', {
        'batch_id': 'BATCH002',
        'item_id': 2, // Potato Chips 100g
        'quantity': 40,
        'unit_price': 60.00,
        'sell_price': 100.00,
        'discount_amount': 0,
        'supplier_id': 1,
      });

      await txn.insert('stock', {
        'batch_id': 'BATCH003',
        'item_id': 3, // A4 Paper Ream
        'quantity': 30,
        'unit_price': 450.00,
        'sell_price': 600.00,
        'discount_amount': 50.00,
        'supplier_id': 1,
      });

      await txn.insert('stock', {
        'batch_id': 'BATCH004',
        'item_id': 4, // Fresh Milk 1L
        'quantity': 100,
        'unit_price': 180.00,
        'sell_price': 250.00,
        'discount_amount': 0,
        'supplier_id': 1,
      });

      await txn.insert('stock', {
        'batch_id': 'BATCH005',
        'item_id': 5, // Cheddar Cheese 200g
        'quantity': 20,
        'unit_price': 400.00,
        'sell_price': 550.00,
        'discount_amount': 20.00,
        'supplier_id': 1,
      });

      await txn.insert('stock', {
        'batch_id': 'BATCH006',
        'item_id': 6, // White Bread Loaf
        'quantity': 70,
        'unit_price': 100.00,
        'sell_price': 160.00,
        'discount_amount': 0,
        'supplier_id': 1,
      });

      await txn.insert('stock', {
        'batch_id': 'BATCH007',
        'item_id': 7, // Chocolate Donut
        'quantity': 50,
        'unit_price': 80.00,
        'sell_price': 120.00,
        'discount_amount': 10.00,
        'supplier_id': 1,
      });

      await txn.insert('stock', {
        'batch_id': 'BATCH008',
        'item_id': 8, // Frozen Peas 500g
        'quantity': 60,
        'unit_price': 200.00,
        'sell_price': 300.00,
        'discount_amount': 0,
        'supplier_id': 1,
      });

      await txn.insert('stock', {
        'batch_id': 'BATCH009',
        'item_id': 9, // Vanilla Ice Cream 1L
        'quantity': 25,
        'unit_price': 450.00,
        'sell_price': 600.00,
        'discount_amount': 50.00,
        'supplier_id': 1,
      });

      await txn.insert('stock', {
        'batch_id': 'BATCH010',
        'item_id': 10, // Bananas 1kg
        'quantity': 80,
        'unit_price': 120.00,
        'sell_price': 180.00,
        'discount_amount': 0,
        'supplier_id': 1,
      });

      await txn.insert('stock', {
        'batch_id': 'BATCH011',
        'item_id': 11, // Tomatoes 500g
        'quantity': 90,
        'unit_price': 80.00,
        'sell_price': 130.00,
        'discount_amount': 0,
        'supplier_id': 1,
      });

      await txn.insert('stock', {
        'batch_id': 'BATCH012',
        'item_id': 12, // Laundry Detergent 1kg
        'quantity': 35,
        'unit_price': 600.00,
        'sell_price': 800.00,
        'discount_amount': 0,
        'supplier_id': 1,
      });

      await txn.insert('stock', {
        'batch_id': 'BATCH013',
        'item_id': 13, // Dishwashing Liquid 500ml
        'quantity': 45,
        'unit_price': 150.00,
        'sell_price': 250.00,
        'discount_amount': 20.00,
        'supplier_id': 1,
      });

      await txn.insert('stock', {
        'batch_id': 'BATCH014',
        'item_id': 14, // Shampoo 400ml
        'quantity': 50,
        'unit_price': 300.00,
        'sell_price': 450.00,
        'discount_amount': 30.00,
        'supplier_id': 1,
      });

      await txn.insert('stock', {
        'batch_id': 'BATCH015',
        'item_id': 15, // Baby Diapers M (20 pcs)
        'quantity': 20,
        'unit_price': 700.00,
        'sell_price': 950.00,
        'discount_amount': 50.00,
        'supplier_id': 1,
      });

      // Price Rules (NEW SEED DATA)
      await txn.insert('price_rule', {
        'id': 'rule_001',
        'name': 'Happy Hour Drinks',
        'type': 'PERCENTAGE_DISCOUNT',
        'scope_kind': 'CATEGORY',
        'scope_value': 'Beverages',
        'value': 20.0,
        'stackable': 0,
        'active': 1,
        'priority': 10,
        'per_customer_limit': null,
        'start_time': '16:00',
        'end_time': '18:00',
        'start_date': null,
        'end_date': null,
        'days_of_week': '5,6,7', // Fri, Sat, Sun
        'created_at': now,
        'updated_at': now,
      });
      await txn.insert('price_rule', {
        'id': 'rule_004',
        'name': 'VIP Customer Markup Waiver',
        'type': 'MARKUP',
        'scope_kind': 'CUSTOMER_GROUP',
        'scope_value': 'VIP',
        'value': -5.0, // Negative markup = discount
        'stackable': 1,
        'active': 0, // Inactive for demo
        'priority': 50,
        'per_customer_limit': null,
        'start_time': null,
        'end_time': null,
        'start_date': null,
        'end_date': null,
        'days_of_week': '',
        'created_at': now,
        'updated_at': now,
      });
    });
  }

  @override
  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Empty for now; add migrations and bump _dbVersion when needed.
  }

  Future<void> clearDatabase() async {
    final dbPath = p.join(await getDatabasesPath(), _dbName);
    await deleteDatabase(dbPath); // deletes the file
    _db = null; // reset the instance
  }

  Future<void> resetDatabase() async {
    final path = p.join(await getDatabasesPath(), _dbName);
    await deleteDatabase(path);
    _db = null;
  }

  // Utility: wrap an action in a transaction
  Future<T> runInTransaction<T>(
    Future<T> Function(Transaction tx) action,
  ) async {
    final db = await database;
    return db.transaction<T>(action);
  }

  Future<void> exportDatabase() async {
    // 1. Find the actual DB file inside app's database folder
    String databasesPath = await getDatabasesPath();
    String sourcePath = p.join(databasesPath, _dbName);
    File sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      throw Exception("Database file not found at $sourcePath");
    }

    // 2. Destination: Downloads folder
    String targetPath = "/storage/emulated/0/Download/pos.db";

    // 3. Copy
    await sourceFile.copy(targetPath);

  }

  Future<void> importDatabase() async {
    // Let user pick a .db file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any, // ✅ no extension filter
    );

    if (result == null || result.files.isEmpty) {
      // user cancelled
      return;
    }

    final String? pickedPath = result.files.single.path;
    if (pickedPath == null) return;

    // Close current DB to release file lock
    if (_db != null) {
      await _db!.close();
      _db = null;
    }

    final Directory docsDir = await getApplicationDocumentsDirectory();
    final String dstPath = p.join(docsDir.path, _dbName);

    final File src = File(pickedPath);
    final File dst = File(dstPath);

    if (await dst.exists()) {
      await dst.delete();
    }
    await src.copy(dstPath);

    // Re-open the DB
    await database;
  }
}
