import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class StorageService {
  StorageService._privateConstructor();
  static final StorageService instance = StorageService._privateConstructor();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Tokens ────────────────────────────────────────────────────────

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await Future.wait([
      _storage.write(key: AppConstants.tokenKey, value: accessToken),
      _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken() => _storage.read(key: AppConstants.tokenKey);

  Future<String?> getRefreshToken() => _storage.read(key: AppConstants.refreshTokenKey);

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: AppConstants.tokenKey),
      _storage.delete(key: AppConstants.refreshTokenKey),
    ]);
  }

  // ── User metadata ────────────────────────────────────────────────

  Future<void> saveUserMeta({
    required String userId,
    required String role,
    String? tenantId,
    required bool isEmployee,
  }) async {
    await Future.wait([
      _storage.write(key: AppConstants.userIdKey, value: userId),
      _storage.write(key: AppConstants.userRoleKey, value: role),
      _storage.write(key: AppConstants.isEmployeeKey, value: isEmployee.toString()),
      if (tenantId != null)
        _storage.write(key: AppConstants.tenantIdKey, value: tenantId),
    ]);
  }

  Future<String?> getUserId() => _storage.read(key: AppConstants.userIdKey);
  Future<String?> getUserRole() => _storage.read(key: AppConstants.userRoleKey);
  Future<String?> getTenantId() => _storage.read(key: AppConstants.tenantIdKey);

  Future<bool> getIsEmployee() async {
    final val = await _storage.read(key: AppConstants.isEmployeeKey);
    return val == 'true';
  }

  // ── Full clear (on logout / account deletion) ────────────────────

  Future<void> clearAll() => _storage.deleteAll();
}
