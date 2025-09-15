import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const _dbName = 'possystem.db';
  /// Bump to trigger a fresh onCreate (dev). Keep 1 if you don't need migrations.
  static const _dbVersion = 1;

  Database? _db;
  Future<Database> get database async => _db ??= await _initDB();

  Future<Database> _initDB() async {
    final String dbPath = kIsWeb ? _dbName : p.join(await getDatabasesPath(), _dbName);

    return openDatabase(
      dbPath,
      version: _dbVersion,
      onConfigure: (db) async {
        // Enforce FKs
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Helper: SHA-256 hash (use if you seed users later)
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

    // 7) payment (before invoice because invoice FK references sale_invoice_id)
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

    // Indexes
    await db.execute('CREATE INDEX idx_item_category             ON item(category_id);');
    await db.execute('CREATE INDEX idx_item_supplier             ON item(supplier_id);');
    await db.execute('CREATE INDEX idx_stock_item                ON stock(item_id);');
    await db.execute('CREATE INDEX idx_stock_supplier            ON stock(supplier_id);');
    await db.execute('CREATE INDEX idx_payment_user              ON payment(user_id);');
    await db.execute('CREATE INDEX idx_payment_sale_invoice_id   ON payment(sale_invoice_id);');
    await db.execute('CREATE INDEX idx_invoice_sale_invoice_id   ON invoice(sale_invoice_id);');
    await db.execute('CREATE INDEX idx_req_supplier              ON supplier_request(supplier_id);');
    await db.execute('CREATE INDEX idx_ri_request                ON supplier_request_item(request_id);');
    await db.execute('CREATE INDEX idx_ri_item                   ON supplier_request_item(item_id);');
  }

  @override
  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Keep empty for now (you asked for no migration logic yet).
    // When you need to migrate, implement ALTER TABLE / rebuild here and bump _dbVersion.
  }

  // Utility to run a whole action in a transaction
  Future<T> runInTransaction<T>(Future<T> Function(Transaction tx) action) async {
    final db = await database;
    return db.transaction<T>(action);
  }
}
