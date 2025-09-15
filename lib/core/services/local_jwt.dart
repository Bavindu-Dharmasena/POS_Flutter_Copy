import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'secure_storage_service.dart';

/// OFFLINE-ONLY JWT. Never accept on server.
class LocalJwt {
  static const _kSecretKey = 'local_jwt_secret_v1';

  static String _b64(Object v) =>
      base64Url.encode(utf8.encode(v is String ? v : jsonEncode(v))).replaceAll('=', '');

  static Future<List<int>> _secret() async {
    final s = SecureStorageService.instance;
    var b64 = await s.getCustom(_kSecretKey);
    if (b64 == null || b64.isEmpty) {
      final r = Random.secure();
      final bytes = List<int>.generate(32, (_) => r.nextInt(256));
      b64 = base64UrlEncode(bytes);
      await s.setCustom(_kSecretKey, b64);
    }
    return base64Url.decode(b64);
  }

  static Future<String> issue({required String sub, required String role, Duration ttl = const Duration(hours: 1)}) async {
    final header = {'alg':'HS256','typ':'JWT','iss':'pos-app-local'};
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final payload = {'sub':sub,'role':role,'iat':now,'exp':now+ttl.inSeconds,'offline':true,'mode':'offline'};
    final h = _b64(header), p = _b64(payload);
    final input = '$h.$p';
    final key = await _secret();
    final sig = Hmac(sha256, key).convert(utf8.encode(input));
    final sgn = base64Url.encode(sig.bytes).replaceAll('=', '');
    return '$input.$sgn';
  }
}
