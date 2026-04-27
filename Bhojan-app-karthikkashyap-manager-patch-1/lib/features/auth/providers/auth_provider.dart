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
      : super(const AuthState(status: AuthStatus.unauthenticated));

  // ── Registration (EP-01) ──────────────────────────────────────────

  /// Returns the OTP reference on success, null on error.
  Future<OtpReferenceResponse?> register(RegisterRequest request) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final result = await _service.register(request);
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return result;
    } catch (e) {
      _handleError(e);
      return null;
    }
  }

  // ── OTP Verify (EP-02) ───────────────────────────────────────────

  Future<bool> verifyOtp(OtpVerifyRequest request) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final result = await _service.verifyOtp(request);
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

  // ── Password Login (EP-03) ────────────────────────────────────────

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
        code = data['error']['code'] as String?;
        message = data['error']['message'] as String? ?? ErrorCodes.getMessage(code ?? '');
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
