// lib/core/config/api_config.dart
class ApiConfig {
  // 👉 Set this to your PC's LAN IP when testing on a real phone (same Wi-Fi).
  // Windows: ipconfig | Mac/Linux: ifconfig
  static const String _lanIp = '192.168.1.100'; // change me
  static const int _port = 3001;

  // Android emulator → host machine
  static String androidEmulatorOrigin() => 'http://10.0.2.2:$_port';

  // iOS simulator / Windows / Mac / Linux desktop builds
  static String localhostOrigin() => 'http://localhost:$_port';

  // Real phone on same Wi-Fi as your PC
  static String lanOrigin() => 'http://$_lanIp:$_port';
}
