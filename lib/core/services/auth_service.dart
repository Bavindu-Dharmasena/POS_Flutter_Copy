import 'package:flutter/material.dart';

class User {
  final String username;
  final String role;
  final String token;

  User(this.username, this.role, this.token);
}

class AuthService with ChangeNotifier {
  User? _currentUser;

  // Seed data for local login
  final Map<String, Map<String, String>> _seedUsers = {
    'cashier': {'password': 'cash123', 'role': 'Cashier'},
    'stock': {'password': 'stock123', 'role': 'StockKeeper'},
    'manager': {'password': 'manager123', 'role': 'Manager'},
    'admin': {'password': 'admin123', 'role': 'Admin'},
  };

  User? get currentUser => _currentUser;

  /// Step 1: Simulate username check
  Future<List<String>> checkUsername(String username) async {
    await Future.delayed(const Duration(milliseconds: 500)); // simulate network delay
    if (_seedUsers.containsKey(username)) {
      return [_seedUsers[username]!['role']!];
    }
    throw Exception("User not found");
  }

  /// Step 2: Simulate login
  Future<bool> login(String username, String password, {String? role}) async {
    await Future.delayed(const Duration(milliseconds: 500)); // simulate network delay
    final user = _seedUsers[username];
    if (user != null && user['password'] == password) {
      _currentUser = User(username, user['role']!, 'fake-jwt-token');
      notifyListeners();
      return true;
    }
    throw Exception("Invalid credentials");
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
