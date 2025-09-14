import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/db/database_helper.dart';
import 'local_jwt.dart';

class LocalAuthService {
Future<Map<String, dynamic>> login(String email, String password) async {
  print('Login attempt: $email');
  
  await _enforceLockout(email);

  final Database db = await DatabaseHelper.instance.database;
  final rows = await db.query('user', where: 'email = ?', whereArgs: [email.trim()], limit: 1);
  
  print('Found ${rows.length} users with email: $email');
  if (rows.isEmpty) { 
    print('No user found with email: $email');
    await _recordFail(email); 
    throw Exception('Invalid credentials'); 
  }

  final row = rows.first;
  final storedHash = (row['password'] as String?) ?? '';
  final role = (row['role'] as String?) ?? 'Cashier';
  final foundEmail = row['email'] as String?;
  
  print('Found user: $foundEmail, role: $role');

  // Your seed uses SHA-256(password)
  final tryHash = sha256.convert(utf8.encode(password)).toString();
  print('Password hash comparison:');
  print('Stored: $storedHash');
  print('Entered: $tryHash');
  print('Match: ${tryHash == storedHash}');
  
  if (tryHash != storedHash) { 
    print('Password mismatch');
    await _recordFail(email); 
    throw Exception('Invalid credentials'); 
  }

  await _resetFail(email);
  print('Login successful');

  final token = await LocalJwt.issue(sub: email, role: role);
  return {
    'access_token': token,
    'refresh_token': 'LOCAL-${DateTime.now().microsecondsSinceEpoch}',
    'user': {'email': email, 'role': role},
    'mode': 'offline',
  };
}

  // --- simple lockout (5 fails -> 5 minutes) ---
  static const _kFail = 'auth_fail_';
  static const _kLock = 'auth_lock_';
  static const _maxFails = 5;
  static const _lockMins = 5;

  Future<void> _recordFail(String email) async {
    final sp = await SharedPreferences.getInstance();
    final n = (sp.getInt('$_kFail$email') ?? 0) + 1;
    await sp.setInt('$_kFail$email', n);
    if (n >= _maxFails) {
      await sp.setInt('$_kLock$email',
          DateTime.now().add(const Duration(minutes: _lockMins)).millisecondsSinceEpoch);
    }
  }

  Future<void> _resetFail(String email) async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('$_kFail$email');
    await sp.remove('$_kLock$email');
  }

  Future<void> _enforceLockout(String email) async {
    final sp = await SharedPreferences.getInstance();
    final until = sp.getInt('$_kLock$email');
    if (until != null && until > DateTime.now().millisecondsSinceEpoch) {
      final secs = ((until - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
      throw Exception('Too many attempts. Try again in ${secs}s');
    }
  }
}
