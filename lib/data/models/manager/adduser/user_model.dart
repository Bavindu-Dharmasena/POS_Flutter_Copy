import 'package:flutter/foundation.dart';

/// Mirrors the `user` table in SQLite.
/// Columns:
/// id | name | email | contact | password | role | color_code | created_at | updated_at | refresh_token_hash
@immutable
class User {
  final int? id;
  final String name;
  final String email;          // UNIQUE
  final String contact;
  final String passwordHash;   // already hashed (sha256)
  final String role;           // Admin | Manager | Cashier | StockKeeper
  final String colorCode;      // #RRGGBB
  final int createdAt;         // epoch ms
  final int updatedAt;         // epoch ms
  final String? refreshTokenHash;

  const User({
    this.id,
    required this.name,
    required this.email,
    required this.contact,
    required this.passwordHash,
    required this.role,
    required this.colorCode,
    required this.createdAt,
    required this.updatedAt,
    this.refreshTokenHash,
  });

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? contact,
    String? passwordHash,
    String? role,
    String? colorCode,
    int? createdAt,
    int? updatedAt,
    String? refreshTokenHash,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      contact: contact ?? this.contact,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      colorCode: colorCode ?? this.colorCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      refreshTokenHash: refreshTokenHash ?? this.refreshTokenHash,
    );
  }

  factory User.fromMap(Map<String, Object?> map) {
    return User(
      id: (map['id'] as num?)?.toInt(),
      name: (map['name'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      contact: (map['contact'] ?? '') as String,
      passwordHash: (map['password'] ?? '') as String,
      role: (map['role'] ?? 'Cashier') as String,
      colorCode: (map['color_code'] ?? '#000000') as String,
      createdAt: (map['created_at'] as num).toInt(),
      updatedAt: (map['updated_at'] as num).toInt(),
      refreshTokenHash: map['refresh_token_hash'] as String?,
    );
  }

  Map<String, Object?> toMap({bool includeId = false}) {
    final m = <String, Object?>{
      'name': name,
      'email': email.toLowerCase(),
      'contact': contact,
      'password': passwordHash,
      'role': role,
      'color_code': colorCode,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'refresh_token_hash': refreshTokenHash,
    };
    if (includeId && id != null) m['id'] = id;
    return m;
  }
}
