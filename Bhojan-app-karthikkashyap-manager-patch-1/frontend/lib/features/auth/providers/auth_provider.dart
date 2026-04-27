import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/interceptors/auth_interceptor.dart';
import '../../../core/api/interceptors/error_interceptor.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/error_codes.dart';
import '../../../core/utils/storage_service.dart';
import '../models/auth_response_models.dart';
import '../models/tenant_model.dart';
import '../models/user_model.dart';
import '../../profile/models/profile_model.dart';
import '../services/auth_service.dart';
import '../services/mock_auth_service.dart';
import '../services/real_auth_service.dart';

// ── Core providers ──────────────────────────────────────────────────

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final client = ApiClient();
  client.dio.interceptors.add(AuthInterceptor(storage, client.dio));
  client.dio.interceptors.add(ErrorInterceptor());
  return client;
});

/// Switches between Mock and Real based on [AppConfig.useMockServices].
final authServiceProvider = Provider<AuthServiceInterface>((ref) {
  if (AppConfig.useMockServices) {
    return MockAuthService();
  }
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(storageServiceProvider);
  return RealAuthService(apiClient, storage);
});

// ── Auth State ──────────────────────────────────────────────────────

enum AuthStatus { initial, unauthenticated, authenticated, loading, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final String? errorCode;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.errorCode,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    String? errorCode,
  }) {
    return AuthState(
      status:       status       ?? this.status,
      user:         user         ?? this.user,
      errorMessage: errorMessage,
      errorCode:    errorCode,
    );
  }
}

// ── Auth Notifier ───────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthServiceInterface _service;
  final StorageService _storage;

  AuthNotifier(this._service, this._storage)
      : super(const AuthState(status: AuthStatus.initial)) {
    _checkAuthState();
  }

  /// Reads stored tokens on startup and restores auth state.
  Future<void> _checkAuthState() async {
    final token = await _storage.getAccessToken();
    if (token == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final profile = await _service.getProfile();
      final user = UserModel(
        id: profile.id,
        phone: profile.phone,
        email: profile.email,
        fullName: profile.fullName,
        role: profile.role,
        tenantId: profile.tenantId,
        isEmployee: profile.isEmployee,
        employeeId: profile.employeeId,
        lastLoginAt: profile.lastLoginAt,
      );
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      await _storage.clearAll();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  // ── Registration (EP-01) ──────────────────────────────────────────

  /// Returns the OTP reference on success, null on error.
  Future<OtpReferenceResponse?> register(RegisterRequest request) async {
    // #region agent log H15 notifier register entry
    print('[DBG-H15] notifier_register userType=${request.userType} phone=${request.phone}');
    // #endregion
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final result = await _service.register(request);
      // #region agent log H15 notifier register success
      print('[DBG-H15] notifier_register success otpRef=${result.otpReference}');
      // #endregion
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return result;
    } catch (e) {
      // #region agent log H15 notifier register error
      print('[DBG-H15] notifier_register error=$e');
      // #endregion
      _handleError(e);
      return null;
    }
  }

  // ── OTP Verify (EP-02) ───────────────────────────────────────────

  Future<bool> verifyOtp(OtpVerifyRequest request) async {
    // #region agent log H16 notifier verify entry
    print('[DBG-H16] notifier_verifyOtp phone=${request.phone} otpLen=${request.otp.length}');
    // #endregion
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final result = await _service.verifyOtp(request);
      // #region agent log H16 notifier verify success
      print('[DBG-H16] notifier_verifyOtp success userId=${result.user['id']}');
      // #endregion
      final user = UserModel.fromJson(result.user);
      await _storage.saveTokens(result.accessToken, result.refreshToken);
      await _storage.saveUserMeta(
        userId: user.id,
        role: user.role,
        tenantId: user.tenantId,
        isEmployee: user.isEmployee,
      );
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      // #region agent log H16 notifier verify error
      print('[DBG-H16] notifier_verifyOtp error=$e');
      // #endregion
      _handleError(e);
      return false;
    }
  }

  // ── Password Login (EP-03) ────────────────────────────────────────

  Future<OtpReferenceResponse?> requestLoginOtp(String phone) async {
    // #region agent log H17 notifier login-otp entry
    print('[DBG-H17] notifier_requestLoginOtp phone=$phone');
    // #endregion
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final result = await _service.requestLoginOtp(phone);
      // #region agent log H17 notifier login-otp success
      print('[DBG-H17] notifier_requestLoginOtp success otpRef=${result.otpReference}');
      // #endregion
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return result;
    } catch (e) {
      // #region agent log H17 notifier login-otp error
      print('[DBG-H17] notifier_requestLoginOtp error=$e');
      // #endregion
      _handleError(e);
      return null;
    }
  }

  Future<bool> loginWithPassword(PasswordLoginRequest request) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final result = await _service.loginWithPassword(request);
      final user = UserModel.fromJson(result.user);
      await _storage.saveTokens(result.accessToken, result.refreshToken);
      await _storage.saveUserMeta(
        userId: user.id,
        role: user.role,
        tenantId: user.tenantId,
        isEmployee: user.isEmployee,
      );
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  // ── Logout (EP-05) ───────────────────────────────────────────────

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    final rt = await _storage.getRefreshToken();
    if (rt != null) {
      try { await _service.logout(rt); } catch (_) {}
    }
    await _storage.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  // ── Password Reset (EP-09) ────────────────────────────────────────

  Future<OtpReferenceResponse?> requestPasswordReset(String phone) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final result = await _service.requestPasswordReset(PasswordResetRequest(phone: phone));
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return result;
    } catch (e) {
      _handleError(e);
      return null;
    }
  }

  // ── Password Reset Verify (EP-10) ─────────────────────────────────

  Future<bool> verifyPasswordReset(PasswordResetVerifyRequest request) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _service.verifyPasswordReset(request);
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  // ── Upgrade to Employee (EP-14) ───────────────────────────────────

  Future<bool> upgradeToEmployee(UpgradeToEmployeeRequest request) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final result = await _service.upgradeToEmployee(request);
      final user = UserModel.fromJson(result.user);
      await _storage.saveTokens(result.accessToken, result.refreshToken);
      await _storage.saveUserMeta(
        userId: user.id,
        role: user.role,
        tenantId: user.tenantId,
        isEmployee: user.isEmployee,
      );
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  // ── Delete Account (EP-13) ────────────────────────────────────────

  Future<bool> deleteAccount(String otp, String? reason) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _service.deleteAccount(otp, reason);
      await _storage.clearAll();
      state = const AuthState(status: AuthStatus.unauthenticated);
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  // ── Error helper ──────────────────────────────────────────────────

  void clearError() {
    state = state.copyWith(errorMessage: null, errorCode: null);
  }

  void _handleError(dynamic e) {
    String? code;
    String message = 'Something went wrong. Please try again.';

    if (e is DioException && e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      if (data['success'] == false && data['error'] != null) {
        final rawCode = data['error']['code'];
        code = rawCode?.toString();
        
        dynamic rawMsg = data['error']['message'];
        if (rawMsg is List) {
          message = rawMsg.join('\n');
        } else if (rawMsg != null) {
          message = rawMsg.toString();
        } else {
          message = ErrorCodes.getMessage(code ?? '');
        }
      }
    } else {
      message = e.toString();
    }

    state = state.copyWith(
      status: AuthStatus.error,
      errorMessage: code != null ? ErrorCodes.getMessage(code) : message,
      errorCode: code,
    );
  }
}

// ── Provider ────────────────────────────────────────────────────────

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authServiceProvider),
    ref.watch(storageServiceProvider),
  );
});
