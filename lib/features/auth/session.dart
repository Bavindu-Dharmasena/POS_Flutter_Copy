import 'package:shared_preferences/shared_preferences.dart';

class Session {
  Session._();
  static final Session instance = Session._();

  static const _kToken = 'auth_token';
  static const _kRole = 'auth_role';

  Future<void> saveToken(String token, {String? role}) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kToken, token);
    if (role != null) await sp.setString(_kRole, role);
  }

  Future<String?> token() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kToken);
  }

  Future<String?> role() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kRole);
  }

  Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kToken);
    await sp.remove(_kRole);
  }
}
