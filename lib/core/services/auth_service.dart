// // lib/core/services/auth_service.dart
// import 'package:flutter/foundation.dart';
// import 'api_client.dart';
// import 'secure_storage_service.dart';

// class User {
//   final String email;
//   final String role;
//   final String accessToken;
//   User(this.email, this.role, this.accessToken);
// }

// class AuthService with ChangeNotifier {
//   AuthService({ApiClient? api}) : _api = api ?? ApiClient.auto();

//   final ApiClient _api;
//   final _storage = SecureStorageService.instance;

//   User? _currentUser;
//   User? get currentUser => _currentUser;

//   Future<void> login(String email, String password) async {
//     final resp = await _api.login(email: email, password: password);
//     final user = (resp['user'] as Map?) ?? {};
//     final access = resp['access_token'] as String? ?? '';
//     final role = (user['role'] as String?) ?? '';
//     if (access.isEmpty) throw Exception('No access token returned from server.');
//     _currentUser = User(email, role, access);
//     notifyListeners();
//   }

//   Future<bool> hydrate() async {
//     final access = await _storage.getAccessToken();
//     final email = await _storage.getEmail();
//     final role  = await _storage.getRole();
//     if (access != null && email != null && role != null) {
//       _currentUser = User(email, role, access);
//       notifyListeners();
//       return true;
//     }
//     return false;
//   }

//   Future<void> logout() async {
//     try { await _api.logout(); } finally {
//       _currentUser = null;
//       await _storage.clear();
//       notifyListeners();
//     }
//   }
// }

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api_client.dart';
import 'secure_storage_service.dart';
import 'local_auth_service.dart';

/// ⬅️ Set true for now while backend is not hosted.
/// Later set to false (or read from a .env) to prefer online.
const bool kPreferOfflineDev = true;

class User {
  final String email;
  final String role;
  final String name;
  final String userId;
  final String accessToken;
  final bool offline;
  User(
    this.email,
    this.role,
    this.name,
    this.userId,
    this.accessToken, {
    this.offline = false,
  });
}

class AuthService with ChangeNotifier {
  AuthService({ApiClient? api})
    : _api = api ?? ApiClient.auto(),
      _local = LocalAuthService();

  final ApiClient _api;
  final LocalAuthService _local;
  final _storage = SecureStorageService.instance;

  User? _currentUser;
  User? get currentUser => _currentUser;

  Future<void> login(String email, String password) async {
    // --- Force OFFLINE path in dev if desired ---
    if (kPreferOfflineDev) {
      final resp = await _local.login(email, password);
      await _save(resp, preferred: 'offline');
      return;
    }

    // --- ONLINE first ---
    try {
      final resp = await _api.login(email: email, password: password);
      await _save(resp, preferred: 'online');
      return;
    } on TimeoutException catch (_) {
      debugPrint('[AuthService] Online timeout -> offline fallback');
    } on SocketException catch (_) {
      debugPrint('[AuthService] No network -> offline fallback');
    } catch (e) {
      // only fallback for network errors bubbled by ApiClient
      final msg = e.toString();
      if (!msg.contains('Network error')) rethrow;
      debugPrint('[AuthService] Network error -> offline fallback');
    }

    // --- OFFLINE fallback (SQLite) ---
    final resp = await _local.login(email, password);
    await _save(resp, preferred: 'offline');
  }

  // Future<void> _save(Map<String, dynamic> resp, {required String preferred}) async {
  //   final user = (resp['user'] as Map?) ?? {};
  //   final role = (user['role'] as String?) ?? 'Cashier';
  //   final email = (user['email'] as String?) ?? '';
  //   final name = (user['name'] as String?) ?? '';
  //   final userId = (user['id'] as String?) ?? '';
  //   final access = (resp['access_token'] as String?) ?? '';
  //   final refresh = (resp['refresh_token'] as String?) ?? 'local-refresh';

  //   if (access.isEmpty) throw Exception('Invalid auth response: no access token');
  //   print("Login successful Methana: $email • role=$role • name=$name • id=$userId • mode=$preferred");

  //   await _storage.saveTokens(
  //     accessToken: access,
  //     refreshToken: refresh,
  //     role: role,
  //     email: email,
  //     name: name,
  //     userId: userId,
  //   );
  //   await _storage.setAuthMode(preferred);

  //   _currentUser = User(email, role, name, userId, access, offline: preferred == 'offline');
  //   debugPrint('[AuthService] Logged in as $email • role=$role • mode=$preferred');
  //   notifyListeners();
  // }

  // Helpers (put inside AuthService class, private)
  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map)
      return Map<String, dynamic>.from(
        v.map((k, v) => MapEntry(k.toString(), v)),
      );
    return <String, dynamic>{};
  }

  String _pickString(
    Map<String, dynamic> m,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;
      final s = v.toString();
      if (s.isNotEmpty) return s;
    }
    return fallback;
  }

  Map<String, dynamic> _extractUser(Map<String, dynamic> resp) {
    // Try common places: resp.user, resp.data.user, resp.profile, etc.
    final user = _asMap(resp['user']).isNotEmpty
        ? _asMap(resp['user'])
        : _asMap(_asMap(resp['data'])['user']).isNotEmpty
        ? _asMap(_asMap(resp['data'])['user'])
        : _asMap(resp['profile']);
    return user;
  }

  String _extractAccessToken(Map<String, dynamic> resp) {
    // Try multiple common token keys/locations
    final data = _asMap(resp['data']);
    return _pickString(
      {
        'access_token': resp['access_token'],
        'accessToken': resp['accessToken'],
        'token': resp['token'],
        'jwt': resp['jwt'],
        'data.access_token': data['access_token'],
        'data.token': data['token'],
      },
      [
        'access_token',
        'accessToken',
        'token',
        'jwt',
        'data.access_token',
        'data.token',
      ],
    );
  }

  String _extractRefreshToken(Map<String, dynamic> resp) {
    final data = _asMap(resp['data']);
    return _pickString(
      {
        'refresh_token': resp['refresh_token'],
        'refreshToken': resp['refreshToken'],
        'data.refresh_token': data['refresh_token'],
        'data.refreshToken': data['refreshToken'],
      },
      [
        'refresh_token',
        'refreshToken',
        'data.refresh_token',
        'data.refreshToken',
      ],
      fallback: 'local-refresh',
    );
  }

  Future<void> _save(
    Map<String, dynamic> resp, {
    required String preferred,
  }) async {
    // Defensive copy/cast
    final map = _asMap(resp);

    // --- User extraction (supports multiple shapes/keys)
    final user = _extractUser(map);

    final role = _pickString(user, ['role', 'user_role'], fallback: 'Cashier');
    final email = _pickString(user, ['email', 'user_email']);
    final name = _pickString(user, [
      'name',
      'full_name',
      'displayName',
      'username',
    ]);
    // Accept id as int or string, and common key variants
    final rawId = user['id'] ?? user['user_id'] ?? user['uid'];
    final userId = rawId == null ? '' : rawId.toString();

    // --- Tokens
    var access = _extractAccessToken(map);
    final refresh = _extractRefreshToken(map);

    // If we’re offline and no token provided, synthesize one so dev works.
    if (access.isEmpty && preferred == 'offline') {
      access =
          'offline-${email.isEmpty ? 'user' : email}-${DateTime.now().millisecondsSinceEpoch}';
    }

    // Still empty? Then the server response is truly invalid.
    if (access.isEmpty) {
      debugPrint(
        '[AuthService] ERROR: No access token in response. resp=$resp',
      );
      throw Exception('Invalid auth response: no access token');
    }

    // Helpful log for debugging shapes:
    debugPrint(
      '[AuthService] Parsed user -> email=$email, role=$role, name=$name, id=$userId, mode=$preferred',
    );

    // Persist
    await _storage.saveTokens(
      accessToken: access,
      refreshToken: refresh,
      role: role,
      email: email,
      name: name,
      userId: userId,
    );
    await _storage.setAuthMode(preferred);

    _currentUser = User(
      email,
      role,
      name,
      userId,
      access,
      offline: preferred == 'offline',
    );
    debugPrint(
      '[AuthService] Logged in as $email • role=$role • mode=$preferred',
    );
    notifyListeners();
  }

  Future<bool> hydrate() async {
    final access = await _storage.getAccessToken();
    final email = await _storage.getEmail();
    final role = await _storage.getRole();
    final name = await _storage.getName() ?? '';
    final userId = await _storage.getUserId() ?? '';
    if (access != null && email != null && role != null) {
      final mode = (await _storage.getAuthMode()) ?? 'online';
      _currentUser = User(
        email,
        role,
        name,
        userId,
        access,
        offline: mode == 'offline',
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } finally {
      _currentUser = null;
      await _storage.clear();
      notifyListeners();
    }
  }
}
