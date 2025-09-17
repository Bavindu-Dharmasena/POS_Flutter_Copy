import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:pos_system/data/db/database_helper.dart';
import 'package:pos_system/data/models/manager/adduser/user_model.dart';

class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  DatabaseHelper get _dbHelper => DatabaseHelper.instance;

  // ---- hashing (same as DatabaseHelper) -------------------------------------
  String _hash(String s) => sha256.convert(utf8.encode(s)).toString();

  // ---- Create ---------------------------------------------------------------
  /// Create a user. If [plainPassword] is provided, it will be sha256-hashed.
  /// Otherwise, [user.passwordHash] is used as-is.
  Future<int> create(User user, {String? plainPassword}) async {
    final db = await _dbHelper.database;

    // Unique email pre-check (optional but nice UX)
    final exists = await emailExists(user.email);
    if (exists) {
      throw Exception('Email already exists');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final toInsert = user.copyWith(
      createdAt: user.createdAt == 0 ? now : user.createdAt,
      updatedAt: now,
      passwordHash: plainPassword != null ? _hash(plainPassword.trim()) : user.passwordHash,
      email: user.email.toLowerCase(),
    );

    return db.insert(
      'user',
      toInsert.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // ---- Read -----------------------------------------------------------------
  Future<User?> findById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'user',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return User.fromMap(rows.first);
    }

  Future<User?> findByEmail(String email) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'user',
      where: 'LOWER(email) = ?',
      whereArgs: [email.toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return User.fromMap(rows.first);
  }

  /// List users with optional search (matches name/email/contact) and role filter.
  Future<List<User>> list({
    String? search,
    String? role,  // Admin | Manager | Cashier | StockKeeper
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _dbHelper.database;

    final where = <String>[];
    final args = <Object?>[];

    if (search != null && search.trim().isNotEmpty) {
      where.add('(name LIKE ? OR email LIKE ? OR contact LIKE ?)');
      final like = '%${search.trim()}%';
      args.addAll([like, like, like]);
    }
    if (role != null && role.trim().isNotEmpty) {
      where.add('role = ?');
      args.add(role.trim());
    }

    final rows = await db.query(
      'user',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'id DESC',
      limit: limit,
      offset: offset,
    );

    return rows.map(User.fromMap).toList();
  }

  Future<bool> emailExists(String email, {int? excludeUserId}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'user',
      columns: const ['id'],
      where: excludeUserId == null
          ? 'LOWER(email) = ?'
          : 'LOWER(email) = ? AND id != ?',
      whereArgs: excludeUserId == null
          ? [email.toLowerCase()]
          : [email.toLowerCase(), excludeUserId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  // ---- Update ---------------------------------------------------------------
  /// Update a user. If [newPlainPassword] is provided, it will be hashed and updated.
  Future<int> update(User user, {String? newPlainPassword}) async {
    if (user.id == null) {
      throw Exception('User id required for update');
    }
    final db = await _dbHelper.database;

    // Unique email pre-check against others
    final exists = await emailExists(user.email, excludeUserId: user.id);
    if (exists) {
      throw Exception('Email already exists');
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    final values = user.copyWith(
      updatedAt: now,
      passwordHash: newPlainPassword != null
          ? _hash(newPlainPassword.trim())
          : user.passwordHash,
      email: user.email.toLowerCase(),
    ).toMap();

    return db.update(
      'user',
      values,
      where: 'id = ?',
      whereArgs: [user.id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // ---- Delete ---------------------------------------------------------------
  /// Delete by id. NOTE: payment.user_id has FK ON DELETE RESTRICT.
  /// If this user is referenced by payments, SQLite will throw a foreign key error.
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.delete('user', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Auth helper ----------------------------------------------------------
  /// Returns the user if email+password is correct, otherwise null.
  Future<User?> verifyLogin(String email, String plainPassword) async {
    final user = await findByEmail(email);
    if (user == null) return null;
    final candidateHash = _hash(plainPassword.trim());
    return user.passwordHash == candidateHash ? user : null;
  }

  // ---- Convenience ----------------------------------------------------------
  /// Create inside a transaction (optionally do more ops atomically).
  Future<int> createInTx(User user, {String? plainPassword}) {
    return _dbHelper.runInTransaction<int>((tx) async {
      // NOTE: We could rewrite create() to accept a Transaction,
      // but for simplicity we directly use the db instance here.
      final db = tx as Database; // Transaction implements DatabaseExecutor, safe for insert
      // Run the same code path as create(), but with `db` from txn
      final now = DateTime.now().millisecondsSinceEpoch;

      // unique email check
      final rows = await db.query(
        'user',
        columns: const ['id'],
        where: 'LOWER(email) = ?',
        whereArgs: [user.email.toLowerCase()],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        throw Exception('Email already exists');
      }

      final toInsert = user.copyWith(
        createdAt: user.createdAt == 0 ? now : user.createdAt,
        updatedAt: now,
        passwordHash: plainPassword != null ? _hash(plainPassword.trim()) : user.passwordHash,
        email: user.email.toLowerCase(),
      );

      return db.insert('user', toInsert.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);
    });
  }
}
