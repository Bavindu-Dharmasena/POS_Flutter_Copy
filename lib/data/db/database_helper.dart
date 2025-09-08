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

  // Bump version if you change schema or want to trigger seeding on existing installs

  static const _dbVersion = 3;

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

    // ---- Users seed (hashed) ----
    {
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
        await db.insert('user', u);
      }
    }

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


    // ✅ Seed 5 items (+ needed categories/suppliers/stock) on first DB create
    await _seedInitialData(db);
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // If upgrading to v3 or later, seed only if no items exist (avoids duplicates).
    if (oldVersion < 3) {
      final cnt = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM item'),
      ) ?? 0;
      if (cnt == 0) {
        await _seedInitialData(db);
      }
    }

    // ---- BASIC INVENTORY SEED (supplier + categories + items + stock) ----
    {
      final now = DateTime.now().millisecondsSinceEpoch;

      final supplierId = await db.insert('supplier', {
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

      final catBeverages = await db.insert('category', {
        'category': 'Beverages',
        'color_code': '#FF5733',
        'category_image': null,
      });
      final catSnacks = await db.insert('category', {
        'category': 'Snacks',
        'color_code': '#33FF57',
        'category_image': null,
      });
      final catStationery = await db.insert('category', {
        'category': 'Stationery',
        'color_code': '#3357FF',
        'category_image': null,
      });

      final itemCoke = await db.insert('item', {
        'name': 'Coca Cola 500ml',
        'barcode': 'BARC0001',
        'category_id': catBeverages,
        'supplier_id': supplierId,
        'reorder_level': 10,
        'color_code': '#FF0000',
      });
      final itemChips = await db.insert('item', {
        'name': 'Potato Chips 100g',
        'barcode': 'BARC0002',
        'category_id': catSnacks,
        'supplier_id': supplierId,
        'reorder_level': 20,
        'color_code': '#FFD700',
      });
      final itemPaper = await db.insert('item', {
        'name': 'A4 Paper Ream',
        'barcode': 'BARC0003',
        'category_id': catStationery,
        'supplier_id': supplierId,
        'reorder_level': 5,
        'color_code': '#FFFFFF',
      });

      await db.insert('stock', {
        'batch_id': 'BATCH-COCA-001',
        'item_id': itemCoke,
        'quantity': 120,
        'unit_price': 50.0,
        'sell_price': 65.0,
        'discount_amount': 0.0,
        'supplier_id': supplierId,
      });
      await db.insert('stock', {
        'batch_id': 'BATCH-CHIPS-001',
        'item_id': itemChips,
        'quantity': 200,
        'unit_price': 80.0,
        'sell_price': 100.0,
        'discount_amount': 0.0,
        'supplier_id': supplierId,
      });
      await db.insert('stock', {
        'batch_id': 'BATCH-PAPER-001',
        'item_id': itemPaper,
        'quantity': 100,
        'unit_price': 400.0,
        'sell_price': 480.0,
        'discount_amount': 0.0,
        'supplier_id': supplierId,
      });
    }
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // migrations go here

  }

  Future<T> runInTransaction<T>(Future<T> Function(Transaction tx) action) async {
    final db = await database;
    return db.transaction<T>(action);
  }

  // -------------------- SEEDER --------------------
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

      // ---------- 5 Items ----------
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
        'reorder_level': 6,
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

      // ---------- Stock (batches) ----------
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
    });
  }
}
