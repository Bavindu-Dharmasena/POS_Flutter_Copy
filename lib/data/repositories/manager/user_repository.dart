import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import '../../db/database_helper.dart';

class UserRepository {
  final Future<Database> _db = DatabaseHelper.instance.database;

  Future<List<UserRow>> listUsers() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT name, email, role, color_code, created_at
      FROM user
      ORDER BY created_at DESC
    ''');
    return rows.map((m) => UserRow.fromMap(m)).toList();
  }

  /// Returns the stored password hash (or null if no user/email).
  Future<String?> getPasswordHashByEmail(String email) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT password FROM user WHERE email = ?',
      [email.trim()],
    );
    if (rows.isEmpty) return null;
    return rows.first['password'] as String?;
  }

  /// Change password by email (SHA-256). Returns detailed result.
  Future<PasswordChangeResult> changePasswordByEmail({
    required String email,
    required String newPassword,
  }) async {
    final db = await _db;
    final trimmed = email.trim();

    final before = await getPasswordHashByEmail(trimmed);

    final now = DateTime.now().millisecondsSinceEpoch;
    final hashed = sha256.convert(utf8.encode(newPassword)).toString();

    final count = await db.update(
      'user',
      {'password': hashed, 'updated_at': now},
      where: 'email = ?',
      whereArgs: [trimmed],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    final after = await getPasswordHashByEmail(trimmed);

    return PasswordChangeResult(
      matchedRows: count,
      beforeHash: before,
      afterHash: after,
      expectedHash: hashed,
      email: trimmed,
    );
  }
}

class PasswordChangeResult {
  final int matchedRows; // 0 if email not found
  final String? beforeHash; // stored before update
  final String? afterHash; // stored after update
  final String expectedHash; // the hash we wrote
  final String email;
  const PasswordChangeResult({
    required this.matchedRows,
    required this.beforeHash,
    required this.afterHash,
    required this.expectedHash,
    required this.email,
  });
}

class UserRow {
  final String name;
  final String email;
  final String role;
  final String colorCode;
  final int createdAt;

  UserRow({
    required this.name,
    required this.email,
    required this.role,
    required this.colorCode,
    required this.createdAt,
  });

  factory UserRow.fromMap(Map<String, Object?> m) => UserRow(
    name: (m['name'] as String?) ?? '',
    email: (m['email'] as String?) ?? '',
    role: (m['role'] as String?) ?? 'Cashier',
    colorCode: (m['color_code'] as String?) ?? '#7C3AED',
    createdAt: (m['created_at'] as int?) ?? 0,
  );
}
