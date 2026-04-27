import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/utils/storage_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/interceptors/auth_interceptor.dart';
import '../../../core/api/interceptors/error_interceptor.dart';
import '../models/vendor_auth_models.dart';
import '../models/vendor_profile_model.dart';
import '../services/vendor_auth_service.dart';
import '../services/mock_vendor_auth_service.dart';
import '../services/real_vendor_auth_service.dart';

// ── Core providers (reuse user app's storage; vendor gets its own API client) ──

final vendorStorageProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

final vendorApiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(vendorStorageProvider);
  final client = ApiClient();
  client.dio.interceptors.add(AuthInterceptor(storage, client.dio));
  client.dio.interceptors.add(ErrorInterceptor());
  return client;
});

/// Switches between Mock and Real based on [AppConfig.useMockServices].
final vendorAuthServiceProvider = Provider<VendorAuthServiceInterface>((ref) {
  if (AppConfig.useMockServices) {
    return MockVendorAuthService();
  }
  final apiClient = ref.watch(vendorApiClientProvider);
  final storage = ref.watch(vendorStorageProvider);
  return RealVendorAuthService(apiClient, storage);
});

// ── Vendor Auth State ───────────────────────────────────────────────

enum VendorAuthStatus { initial, loading, authenticated, unauthenticated, error }

class VendorAuthState {
  final VendorAuthStatus status;
  final VendorProfileModel? profile;
  final String? errorMessage;
  final String? errorCode;

  const VendorAuthState({
    this.status = VendorAuthStatus.initial,
    this.profile,
    this.errorMessage,
    this.errorCode,
  });

  VendorAuthState copyWith({
    VendorAuthStatus? status,
    VendorProfileModel? profile,
    String? errorMessage,
    String? errorCode,
  }) {
    return VendorAuthState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
      errorCode: errorCode,
    );
  }
}

// ── Vendor Auth Notifier ────────────────────────────────────────────

class VendorAuthNotifier extends StateNotifier<VendorAuthState> {
  final VendorAuthServiceInterface _service;
  final StorageService _storage;

  VendorAuthNotifier(this._service, this._storage) : super(const VendorAuthState());

  /// Register new vendor business
  Future<bool> register(VendorRegisterRequest request) async {
    state = state.copyWith(status: VendorAuthStatus.loading);
    try {
      await _service.register(request);
      state = state.copyWith(status: VendorAuthStatus.unauthenticated);
      return true;
    } on VendorAuthException catch (e) {
      state = state.copyWith(
        status: VendorAuthStatus.error,
        errorMessage: e.message,
        errorCode: e.code,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: VendorAuthStatus.error,
        errorMessage: 'Failed to register business. Please try again.',
        errorCode: 'INTERNAL_ERROR',
      );
      return false;
    }
  }

  /// Request OTP for login/verification
  Future<bool> requestOtp(String phone) async {
    state = state.copyWith(status: VendorAuthStatus.loading);
    try {
      await _service.requestOtp(phone);
      state = state.copyWith(status: VendorAuthStatus.unauthenticated);
      return true;
    } on VendorAuthException catch (e) {
      state = state.copyWith(
        status: VendorAuthStatus.error,
        errorMessage: e.message,
        errorCode: e.code,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: VendorAuthStatus.error,
        errorMessage: 'Failed to send OTP. Please try again.',
        errorCode: 'INTERNAL_ERROR',
      );
      return false;
    }
  }

  /// Verify OTP and login
  Future<bool> verifyOtp(VerifyOtpRequest request) async {
    state = state.copyWith(status: VendorAuthStatus.loading);
    try {
      final response = await _service.verifyOtp(request);

      await _storage.saveTokens(response.accessToken, response.refreshToken);
      await _storage.saveUserMeta(
        userId: response.user['id'] ?? '',
        role: response.user['role'] ?? 'VENDOR',
        tenantId: response.user['tenant_id'],
        isEmployee: false,
      );

      state = state.copyWith(status: VendorAuthStatus.authenticated);
      return true;
    } on VendorAuthException catch (e) {
      state = state.copyWith(
        status: VendorAuthStatus.error,
        errorMessage: e.message,
        errorCode: e.code,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: VendorAuthStatus.error,
        errorMessage: 'Failed to verify OTP. Please try again.',
        errorCode: 'INTERNAL_ERROR',
      );
      return false;
    }
  }

  /// EP-17 — Activate vendor account.
  Future<bool> activateAccount(VendorActivateRequest request) async {
    state = state.copyWith(status: VendorAuthStatus.loading);
    try {
      await _service.activateAccount(request);
      state = state.copyWith(status: VendorAuthStatus.unauthenticated);
      return true;
    } on VendorAuthException catch (e) {
      state = state.copyWith(
        status: VendorAuthStatus.error,
        errorMessage: e.message,
        errorCode: e.code,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: VendorAuthStatus.error,
        errorMessage: 'Something went wrong. Please try again.',
        errorCode: 'INTERNAL_ERROR',
      );
      return false;
    }
  }

  /// EP-18 — Vendor login.
  Future<bool> login(VendorLoginRequest request) async {
    state = state.copyWith(status: VendorAuthStatus.loading);
    try {
      final response = await _service.login(request);

      // Save tokens to storage
      await _storage.saveTokens(response.accessToken, response.refreshToken);
      await _storage.saveUserMeta(
        userId: response.user['id'] ?? '',
        role: response.user['role'] ?? 'VENDOR',
        tenantId: response.user['tenant_id'],
        isEmployee: false,
      );

      state = state.copyWith(status: VendorAuthStatus.authenticated);
      return true;
    } on VendorAuthException catch (e) {
      state = state.copyWith(
        status: VendorAuthStatus.error,
        errorMessage: e.message,
        errorCode: e.code,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: VendorAuthStatus.error,
        errorMessage: 'Something went wrong. Please try again.',
        errorCode: 'INTERNAL_ERROR',
      );
      return false;
    }
  }

  /// Load vendor profile.
  Future<void> loadProfile() async {
    try {
      final profile = await _service.getProfile();
      state = state.copyWith(status: VendorAuthStatus.authenticated, profile: profile);
    } on VendorAuthException catch (e) {
      state = state.copyWith(errorMessage: e.message, errorCode: e.code);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to load profile.');
    }
  }

  /// EP-19 — Update vendor profile.
  Future<bool> updateProfile(Map<String, dynamic> fields) async {
    try {
      final updated = await _service.updateProfile(fields);
      state = state.copyWith(profile: updated);
      return true;
    } on VendorAuthException catch (e) {
      state = state.copyWith(errorMessage: e.message, errorCode: e.code);
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update profile.');
      return false;
    }
  }

  /// EP-05 — Logout.
  Future<void> logout() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) {
        await _service.logout(refreshToken);
      }
    } catch (_) {
      // Proceed with local cleanup even if server fails.
    }
    await _storage.clearAll();
    state = const VendorAuthState(status: VendorAuthStatus.unauthenticated);
  }
}

// ── Provider ────────────────────────────────────────────────────────

final vendorAuthNotifierProvider = StateNotifierProvider<VendorAuthNotifier, VendorAuthState>((ref) {
  final service = ref.watch(vendorAuthServiceProvider);
  final storage = ref.watch(vendorStorageProvider);
  return VendorAuthNotifier(service, storage);
});
