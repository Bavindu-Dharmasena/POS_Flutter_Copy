import '../../core/services/api_client.dart';
import '../../core/services/secure_storage_service.dart';

class LogoutService {
  LogoutService(this._api);
  final ApiClient _api;

  Future<void> signOut() async {
    try {
      await _api.logout();
    } finally {
      await SecureStorageService.instance.clear();
    }
  }
}
