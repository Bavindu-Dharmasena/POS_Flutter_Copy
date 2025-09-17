import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unified secure storage for tokens & small key/values.
/// - Android/iOS -> FlutterSecureStorage (Keystore/Keychain)
/// - Web/Desktop  -> SharedPreferences fallback
class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  // ---- standard keys ----
  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kRole = 'auth_role';
  static const _kEmail = 'auth_email';
  static const _kMode  = 'auth_mode'; // 'online' | 'offline'
  static const _kUserId = 'userId';
  static const _kName = 'name';

  final _secure = const FlutterSecureStorage();

  bool get _canUseSecure => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // ---------------- Tokens (save/get/clear) ----------------

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? role,
    String? email,
    String? name,
    String? userId,
  }) async {
    if (_canUseSecure) {
      await _secure.write(key: _kAccess, value: accessToken);
      await _secure.write(key: _kRefresh, value: refreshToken);
      if (role != null)  await _secure.write(key: _kRole, value: role);
      if (email != null) await _secure.write(key: _kEmail, value: email);
      if (name != null)  await _secure.write(key: _kName, value: name);
      if (userId != null)    await _secure.write(key: _kUserId, value: userId.toString());
    } else {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kAccess, accessToken);
      await sp.setString(_kRefresh, refreshToken);
      if (role != null)  await sp.setString(_kRole, role);
      if (email != null) await sp.setString(_kEmail, email);
      if (name != null)  await sp.setString(_kName, name);
      if (userId != null)    await sp.setString(_kUserId, userId.toString());
    }
  }
  Future<String?> getName() async =>
      _canUseSecure
          ? _secure.read(key: _kName)
          : (await SharedPreferences.getInstance()).getString(_kName);

  Future<String?> getUserId() async =>
      _canUseSecure
          ? _secure.read(key: _kUserId)
          : (await SharedPreferences.getInstance()).getString(_kUserId);

  Future<String?> getAccessToken() async =>
      _canUseSecure
          ? _secure.read(key: _kAccess)
          : (await SharedPreferences.getInstance()).getString(_kAccess);

  Future<String?> getRefreshToken() async =>
      _canUseSecure
          ? _secure.read(key: _kRefresh)
          : (await SharedPreferences.getInstance()).getString(_kRefresh);

  Future<String?> getRole() async =>
      _canUseSecure
          ? _secure.read(key: _kRole)
          : (await SharedPreferences.getInstance()).getString(_kRole);

  Future<String?> getEmail() async =>
      _canUseSecure
          ? _secure.read(key: _kEmail)
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
      await sp.remove(_kMode);
      await sp.remove(_kName);
      await sp.remove(_kUserId);
    }
  }

  // ---------------- Generic KV (for device secret, flags, etc.) ----------------

  Future<void> setCustom(String key, String value) async {
    if (_canUseSecure) {
      await _secure.write(key: key, value: value);
    } else {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(key, value);
    }
  }

  Future<String?> getCustom(String key) async {
    if (_canUseSecure) {
      return _secure.read(key: key);
    } else {
      final sp = await SharedPreferences.getInstance();
      return sp.getString(key);
    }
  }

  // ---------------- Auth mode helper ----------------

  Future<void> setAuthMode(String mode) => setCustom(_kMode, mode);
  Future<String?> getAuthMode() => getCustom(_kMode);
}
