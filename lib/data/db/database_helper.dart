import 'dart:async';
import 'dart:convert';                 // ADDED: for utf8 (hashing)
import 'package:crypto/crypto.dart';   // ADDED: for sha256
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const _dbName = 'pos.db';
  // Bump version if you change schema
  static const _dbVersion = 2;

  Database? _db;
  Future<Database> get database async => _db ??= await _initDB();

  Future<Database> _initDB() async {
    final String dbPath = kIsWeb ? _dbName : p.join(await getDatabasesPath(), _dbName);
    return openDatabase(
      dbPath,
      version: _dbVersion,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON;'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  FutureOr<void> _onCreate(Database db, int version) async {
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

    // ---- ADDED: seed default users (hashed passwords) ----
    {
      final nowUsers = DateTime.now().millisecondsSinceEpoch;
      String hash(String s) => sha256.convert(utf8.encode(s)).toString();

      final defaultUsers = [
        {
          'name': 'Sadeep Chathushan',
          'email': 'sadeep@aasa.lk',
          'contact': '+94 77 000 0001',
          'password': hash('Admin@123'),
          'role': 'Admin',
          'color_code': '#7C3AED',
          'created_at': nowUsers,
          'updated_at': nowUsers,
        },
        {
          'name': 'Hansima Perera',
          'email': 'hansima@aasa.lk',
          'contact': '+94 77 000 0002',
          'password': hash('Manager@123'),
          'role': 'Manager',
          'color_code': '#0EA5E9',
          'created_at': nowUsers,
          'updated_at': nowUsers,
        },
        {
          'name': 'Achintha Silva',
          'email': 'achintha@aasa.lk',
          'contact': '+94 77 000 0003',
          'password': hash('Cashier@123'),
          'role': 'Cashier',
          'color_code': '#10B981',
          'created_at': nowUsers,
          'updated_at': nowUsers,
        },
        {
          'name': 'Insaf Imran',
          'email': 'insaf@aasa.lk',
          'contact': '+94 77 000 0004',
          'password': hash('Stock@123'),
          'role': 'StockKeeper',
          'color_code': '#F59E0B',
          'created_at': nowUsers,
          'updated_at': nowUsers,
        },
      ];

      for (final u in defaultUsers) {
        await db.insert('user', u);
      }
    }
    // ---- END users seed ----

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
        status         TEXT    CHECK (status IN ('ACTIVE','INACTIVE','PENDING')) DEFAULT 'ACTIVE',
        preferred      INTEGER NOT NULL DEFAULT 0,
        payment_terms  TEXT,
        notes          TEXT,
        created_at     INTEGER NOT NULL,
        updated_at     INTEGER NOT NULL
      );
    ''');

    // Keep the rest of your tables if needed by other pages (safe defaults; no crashing seeds)
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

    // No image-based seeds here (avoids asset-missing crashes).
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Add migrations here when you bump versions.
  }

  Future<T> runInTransaction<T>(Future<T> Function(Transaction tx) action) async {
    final db = await database;
    return db.transaction<T>(action);
  }
}
