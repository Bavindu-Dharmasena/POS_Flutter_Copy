import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:pos_system/data/db/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class UserRepository {
  final Future<Database> _db = DatabaseHelper.instance.database;

  /// Return minimal user rows your screen needs.
  Future<List<UserRow>> listUsers() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT name, email, role, color_code, created_at
      FROM user
      ORDER BY created_at DESC
    ''');
    return rows.map((m) => UserRow.fromMap(m)).toList();
  }

  /// Change password (SHA-256) by email. Returns true if updated.
  Future<bool> changePasswordByEmail({
    required String email,
    required String newPassword,
  }) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final hashed = sha256.convert(utf8.encode(newPassword)).toString();

    final count = await db.update(
      'user',
      {'password': hashed, 'updated_at': now},
      where: 'email = ?',
      whereArgs: [email.trim()],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return count > 0;
  }
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
