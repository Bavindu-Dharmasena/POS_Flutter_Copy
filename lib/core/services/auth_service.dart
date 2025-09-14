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

import 'api_client.dart';
import 'secure_storage_service.dart';
import 'local_auth_service.dart';

/// ⬅️ Set true for now while backend is not hosted.
/// Later set to false (or read from a .env) to prefer online.
const bool kPreferOfflineDev = true;

class User {
  final String email;
  final String role;
  final String accessToken;
  final bool offline;
  User(this.email, this.role, this.accessToken, {this.offline = false});
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
      debugPrint('[AuthService] Using OFFLINE login (dev flag).');
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

  Future<void> _save(Map<String, dynamic> resp, {required String preferred}) async {
    final user = (resp['user'] as Map?) ?? {};
    final role = (user['role'] as String?) ?? 'Cashier';
    final email = (user['email'] as String?) ?? '';
    final access = (resp['access_token'] as String?) ?? '';
    final refresh = (resp['refresh_token'] as String?) ?? 'local-refresh';

    if (access.isEmpty) throw Exception('Invalid auth response: no access token');

    await _storage.saveTokens(
      accessToken: access,
      refreshToken: refresh,
      role: role,
      email: email,
    );
    await _storage.setAuthMode(preferred);

    _currentUser = User(email, role, access, offline: preferred == 'offline');
    debugPrint('[AuthService] Logged in as $email • role=$role • mode=$preferred');
    notifyListeners();
  }

  Future<bool> hydrate() async {
    final access = await _storage.getAccessToken();
    final email = await _storage.getEmail();
    final role  = await _storage.getRole();
    if (access != null && email != null && role != null) {
      final mode = (await _storage.getAuthMode()) ?? 'online';
      _currentUser = User(email, role, access, offline: mode == 'offline');
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    try { await _api.logout(); } finally {
      _currentUser = null;
      await _storage.clear();
      notifyListeners();
    }
  }
}
