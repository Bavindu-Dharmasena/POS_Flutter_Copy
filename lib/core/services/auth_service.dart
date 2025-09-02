// lib/core/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'secure_storage_service.dart';

class User {
  final String email;
  final String role;
  final String accessToken;
  User(this.email, this.role, this.accessToken);
}

class AuthService with ChangeNotifier {
  AuthService({ApiClient? api}) : _api = api ?? ApiClient.auto();

  final ApiClient _api;
  final _storage = SecureStorageService.instance;

  User? _currentUser;
  User? get currentUser => _currentUser;

  Future<void> login(String email, String password) async {
    final resp = await _api.login(email: email, password: password);
    final user = (resp['user'] as Map?) ?? {};
    final access = resp['access_token'] as String? ?? '';
    final role = (user['role'] as String?) ?? '';
    if (access.isEmpty) throw Exception('No access token returned from server.');
    _currentUser = User(email, role, access);
    notifyListeners();
  }

  Future<bool> hydrate() async {
    final access = await _storage.getAccessToken();
    final email = await _storage.getEmail();
    final role  = await _storage.getRole();
    if (access != null && email != null && role != null) {
      _currentUser = User(email, role, access);
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
