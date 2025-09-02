// lib/core/services/api_client.dart
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'secure_storage_service.dart';

typedef Json = Map<String, dynamic>;

class ApiClient {
  ApiClient._(this.baseOrigin, {this.timeout = const Duration(seconds: 25)});

  /// ✅ Auto pick the right origin per platform
  factory ApiClient.auto() {
    if (kIsWeb) {
      // Flutter web runs in a browser on the same machine as your backend during dev.
      return ApiClient._(ApiConfig.localhostOrigin());
    }
    if (Platform.isAndroid) {
      // Android emulator needs 10.0.2.2 to reach your PC.
      return ApiClient._(ApiConfig.androidEmulatorOrigin());
    }
    if (Platform.isIOS || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      // Desktop or iOS simulator: localhost hits your PC directly.
      return ApiClient._(ApiConfig.localhostOrigin());
    }
    // Fallback (e.g. real device on LAN)
    return ApiClient._(ApiConfig.lanOrigin());
  }

  final String baseOrigin; // e.g. http://10.0.2.2:3001 or http://localhost:3001
  final Duration timeout;

  String get _authBase => '$baseOrigin/auth';
  final _storage = SecureStorageService.instance;

  static const bool _logEnabled = true;

  // ---- Public HTTP methods
  Future<http.Response> get(String path) => _send('GET', path);
  Future<http.Response> post(String path, {Object? body}) => _send('POST', path, body: body);
  Future<http.Response> put(String path, {Object? body}) => _send('PUT', path, body: body);
  Future<http.Response> delete(String path, {Object? body}) => _send('DELETE', path, body: body);

  // ---- Core request + refresh
  Future<http.Response> _send(String method, String path, {Object? body}) async {
    final uri = Uri.parse(baseOrigin + path);
    final access = await _storage.getAccessToken();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (access != null && access.isNotEmpty) 'Authorization': 'Bearer $access',
    };

    _log('BASE: $baseOrigin');
    _log('[$method] $uri');
    _log('Headers: ${_safeHeaders(headers)}');
    if (body != null) _log('Body: ${_encode(body)}');

    http.Response res;
    try {
      switch (method) {
        case 'GET':    res = await http.get(uri, headers: headers).timeout(timeout); break;
        case 'POST':   res = await http.post(uri, headers: headers, body: _encode(body)).timeout(timeout); break;
        case 'PUT':    res = await http.put(uri, headers: headers, body: _encode(body)).timeout(timeout); break;
        case 'DELETE': res = await http.delete(uri, headers: headers, body: _encode(body)).timeout(timeout); break;
        default: throw Exception('Unsupported method: $method');
      }
    } catch (e) {
      _log('❌ Network error: $e');
      rethrow;
    }

    _log('<- ${res.statusCode} ${res.reasonPhrase}');
    _log('Response: ${res.body}');

    if (res.statusCode == 401 && await _tryRefresh()) {
      final access2 = await _storage.getAccessToken();
      final headers2 = <String, String>{
        'Content-Type': 'application/json',
        if (access2 != null && access2.isNotEmpty) 'Authorization': 'Bearer $access2',
      };
      _log('🔁 Retrying after refresh: [$method] $uri');
      switch (method) {
        case 'GET':    return http.get(uri, headers: headers2).timeout(timeout);
        case 'POST':   return http.post(uri, headers: headers2, body: _encode(body)).timeout(timeout);
        case 'PUT':    return http.put(uri, headers: headers2, body: _encode(body)).timeout(timeout);
        case 'DELETE': return http.delete(uri, headers: headers2, body: _encode(body)).timeout(timeout);
      }
    }

    return res;
  }

  String? _encode(Object? body) =>
      body == null ? null : (body is String ? body : jsonEncode(body));

  Future<bool> _tryRefresh() async {
    final refresh = await _storage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      _log('🔒 No refresh token available.');
      return false;
    }

    final uri = Uri.parse('$_authBase/refresh');
    final payload = jsonEncode({'refresh_token': refresh});

    _log('[POST] $uri (refresh)');
    _log('Body: $payload');

    http.Response res;
    try {
      res = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: payload)
                      .timeout(timeout);
    } catch (e) {
      _log('❌ Refresh call failed: $e');
      return false;
    }

    _log('<- (refresh) ${res.statusCode}');
    _log('Response (refresh): ${res.body}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = _safeJson(res.body);
      final access = data['access_token'] as String?;
      final newRefresh = (data['refresh_token'] as String?) ?? refresh;
      final user = data['user'] as Json?;
      final role = user?['role'] as String?;
      final email = user?['email'] as String?;

      if (access != null && access.isNotEmpty) {
        await _storage.saveTokens(
          accessToken: access,
          refreshToken: newRefresh,
          role: role,
          email: email,
        );
        _log('✅ Tokens refreshed.');
        return true;
      }
    }

    _log('❌ Refresh rejected with ${res.statusCode}.');
    return false;
  }

  // ---- Auth endpoints
  Future<Json> login({required String email, required String password}) async {
    final uri = Uri.parse('$_authBase/login');
    final body = jsonEncode({'email': email, 'password': password});

    _log('[POST] $uri');
    _log('Headers: {"Content-Type":"application/json"}');
    _log('Body: $body');

    http.Response res;
    try {
      res = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: body)
                      .timeout(timeout);
    } catch (e) {
      _log('❌ Network error: $e');
      throw Exception('Network error: $e');
    }

    _log('<- ${res.statusCode} ${res.reasonPhrase}');
    _log('Response body: ${res.body}');

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Login failed (${res.statusCode}): ${res.body}');
    }

    final data = _safeJson(res.body);
    final access = data['access_token'] as String?;
    final refresh = data['refresh_token'] as String?;
    final user = data['user'] as Json?;
    final role = user?['role'] as String?;
    final emailResp = user?['email'] as String?;

    if (access == null || refresh == null) {
      throw Exception('Invalid login response: missing tokens');
    }

    await _storage.saveTokens(
      accessToken: access,
      refreshToken: refresh,
      role: role,
      email: emailResp,
    );

    return data;
  }

  Future<void> logout() async {
    try {
      await post('/auth/logout');
    } catch (e) {
      _log('Logout error (ignored): $e');
    }
  }

  // ---- Utilities
  void _log(Object msg) { if (_logEnabled) print('[ApiClient] $msg'); }

  Map<String, String> _safeHeaders(Map<String, String> headers) {
    final masked = Map<String, String>.from(headers);
    final auth = masked['Authorization'];
    if (auth != null && auth.startsWith('Bearer ')) masked['Authorization'] = 'Bearer ***';
    return masked;
  }

  Json _safeJson(String body) {
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) return parsed;
      throw const FormatException('JSON root is not an object');
    } catch (e) {
      throw Exception('Invalid JSON from server: $e\nBody: $body');
    }
  }
}
