import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kRole = 'auth_role';
  static const _kEmail = 'auth_email';

  final _secure = const FlutterSecureStorage();

  bool get _canUseSecure => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? role,
    String? email,
  }) async {
    if (_canUseSecure) {
      await _secure.write(key: _kAccess, value: accessToken);
      await _secure.write(key: _kRefresh, value: refreshToken);
      if (role != null) await _secure.write(key: _kRole, value: role);
      if (email != null) await _secure.write(key: _kEmail, value: email);
    } else {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kAccess, accessToken);
      await sp.setString(_kRefresh, refreshToken);
      if (role != null) await sp.setString(_kRole, role);
      if (email != null) await sp.setString(_kEmail, email);
    }
  }

  Future<String?> getAccessToken() async =>
      _canUseSecure ? _secure.read(key: _kAccess)
                    : (await SharedPreferences.getInstance()).getString(_kAccess);

  Future<String?> getRefreshToken() async =>
      _canUseSecure ? _secure.read(key: _kRefresh)
                    : (await SharedPreferences.getInstance()).getString(_kRefresh);

  Future<String?> getRole() async =>
      _canUseSecure ? _secure.read(key: _kRole)
                    : (await SharedPreferences.getInstance()).getString(_kRole);

  Future<String?> getEmail() async =>
      _canUseSecure ? _secure.read(key: _kEmail)
                    : (await SharedPreferences.getInstance()).getString(_kEmail);

  Future<void> clear() async {
    if (_canUseSecure) {
      await _secure.deleteAll();
    } else {
      final sp = await SharedPreferences.getInstance();
      await sp.remove(_kAccess);
      await sp.remove(_kRefresh);
      await sp.remove(_kRole);
      await sp.remove(_kEmail);
    }
  }
}
