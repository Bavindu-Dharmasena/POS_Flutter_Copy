import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

class User {
  final int id;
  final String username;
  final String role;

  User({required this.id, required this.username, required this.role});
}

class AuthService with ChangeNotifier {
  final storage = const FlutterSecureStorage();
  final Dio dio = Dio();

  User? _currentUser;
  String? _accessToken; // stored in memory only

  final String _baseUrl = dotenv.get('API_BASE_URL'); // From .env file

  User? get currentUser => _currentUser;
  String? get accessToken => _accessToken;

  AuthService() {
    dio.options = BaseOptions(
      baseUrl: _baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      responseType: ResponseType.json,
    );
  }

  /// Login method
  Future<bool> login(String username, String password) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {'email': username, 'password': password},
      );

      if (response.statusCode == 201) {
        final data = response.data;

        // Store access token in memory (short-lived)
        _accessToken = data['access_token'];

        // Store refresh token securely (long-lived)
        final refreshToken = data['refresh_token'];
        if (refreshToken != null) {
          await storage.write(key: 'refresh_token', value: refreshToken);
        }

        // Set current user
        _currentUser = User(
          id: data['user']['id'],
          username: data['user']['email'],
          role: data['user']['role'],
        );

        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  /// Automatically log in user using refresh token
  Future<bool> autoLogin() async {
    final refreshToken = await storage.read(key: 'refresh_token');

    if (refreshToken != null) {
      try {
        // Request new access token using refresh token
        final response = await dio.post('/auth/refresh', data: {
          'refresh_token': refreshToken,
        });

        if (response.statusCode == 200) {
          final data = response.data;

          _accessToken = data['access_token']; // new access token

          // Optionally update refresh token if rotated
          if (data['refresh_token'] != null) {
            await storage.write(
                key: 'refresh_token', value: data['refresh_token']);
          }

          notifyListeners();
          return true;
        }
      } catch (e) {
        print('AutoLogin error: $e');
      }
    }

    return false;
  }

  /// Logout method
  Future<void> logout() async {
    _currentUser = null;
    _accessToken = null;
    await storage.delete(key: 'refresh_token'); // clear refresh token
    notifyListeners();
  }
}
