import 'dart:convert';
import 'package:http/http.dart' as http;

class UsernameCheckResult {
  final List<String> roles;
  UsernameCheckResult({required this.roles});
}

class LoginResult {
  final String token;
  final String role;
  LoginResult({required this.token, required this.role});
}

class AuthRepository {
  /// Adjust these for your setup
  /// For Android emulator (talking to host machine backend):
  static const String _androidEmulatorHost = "10.0.2.2"; // special alias for localhost
  /// For real device on same WiFi:
  static const String _lanIp = "192.168.1.100"; // change to your PC's LAN IP
  /// For iOS simulator or desktop/web:
  static const String _localhost = "localhost";

  /// Pick one depending on where you run the app
  final String baseUrl =
      "http://$_androidEmulatorHost:8080/api/auth"; // change port if needed

  /// Step 1: Check username and get roles
  Future<UsernameCheckResult> checkUsername(String username) async {
    final uri = Uri.parse('$baseUrl/check-username?username=$username');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final roles = List<String>.from(data['roles'] ?? []);
      return UsernameCheckResult(roles: roles);
    } else if (res.statusCode == 404) {
      throw Exception("User not found");
    } else {
      throw Exception("Error checking username: ${res.statusCode}");
    }
  }

  /// Step 2: Login
  Future<LoginResult> login({
    required String username,
    required String password,
    String? role,
  }) async {
    final uri = Uri.parse('$baseUrl/login');
    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "password": password,
        "role": role,
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final token = data['token'];
      final userRole = data['role'];

      if (token == null || userRole == null) {
        throw Exception("Invalid response from server");
      }

      return LoginResult(token: token, role: userRole);
    } else if (res.statusCode == 401) {
      throw Exception("Invalid credentials");
    } else {
      throw Exception("Login failed: ${res.statusCode}");
    }
  }
}
