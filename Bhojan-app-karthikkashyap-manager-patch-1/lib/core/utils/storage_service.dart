import '../constants/app_constants.dart';

/// Secure token & user-metadata storage.
///
/// Currently uses an in-memory map for web/dev.
/// For production Android/iOS builds, swap the backing store to
/// `flutter_secure_storage` by uncommenting the real implementation below.
class StorageService {
  StorageService._privateConstructor();
  static final StorageService instance = StorageService._privateConstructor();

  final Map<String, String> _store = {};

  // ── Tokens ────────────────────────────────────────────────────────

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    _store[AppConstants.tokenKey] = accessToken;
    _store[AppConstants.refreshTokenKey] = refreshToken;
  }

  Future<String?> getAccessToken() async => _store[AppConstants.tokenKey];

  Future<String?> getRefreshToken() async => _store[AppConstants.refreshTokenKey];

  Future<void> clearTokens() async {
    _store.remove(AppConstants.tokenKey);
    _store.remove(AppConstants.refreshTokenKey);
  }

  // ── User metadata ────────────────────────────────────────────────

  Future<void> saveUserMeta({
    required String userId,
    required String role,
    String? tenantId,
    required bool isEmployee,
  }) async {
    _store[AppConstants.userIdKey] = userId;
    _store[AppConstants.userRoleKey] = role;
    _store[AppConstants.isEmployeeKey] = isEmployee.toString();
    if (tenantId != null) {
      _store[AppConstants.tenantIdKey] = tenantId;
    }
  }

  Future<String?> getUserId() async => _store[AppConstants.userIdKey];
  Future<String?> getUserRole() async => _store[AppConstants.userRoleKey];
  Future<String?> getTenantId() async => _store[AppConstants.tenantIdKey];
  Future<bool> getIsEmployee() async => _store[AppConstants.isEmployeeKey] == 'true';

  // ── Full clear (on logout / account deletion) ────────────────────

  Future<void> clearAll() async {
    _store.clear();
  }
}
