import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/interceptors/auth_interceptor.dart';
import '../../../../core/api/interceptors/error_interceptor.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/storage_service.dart';
import '../models/admin_auth_models.dart';
import '../services/admin_auth_service.dart';

enum AdminAuthStatus { initial, loading, otpSent, authenticated, unauthenticated, error }

class AdminAuthState {
  final AdminAuthStatus status;
  final AdminProfile? profile;
  final String? errorMessage;
  final String? emailOrPhone; // Store to pass to verify step

  const AdminAuthState({
    this.status = AdminAuthStatus.initial,
    this.profile,
    this.errorMessage,
    this.emailOrPhone,
  });

  AdminAuthState copyWith({
    AdminAuthStatus? status,
    AdminProfile? profile,
    String? errorMessage,
    String? emailOrPhone,
  }) {
    return AdminAuthState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage, // We allow setting it to null by omitting in copyWith? No, we need a way to clear it.
      // We'll just pass it explicitly or it retains the old one unless explicitly null
      emailOrPhone: emailOrPhone ?? this.emailOrPhone,
    );
  }
  
  AdminAuthState clearError() {
    return AdminAuthState(
      status: status,
      profile: profile,
      errorMessage: null,
      emailOrPhone: emailOrPhone,
    );
  }
}

final adminAuthServiceProvider = Provider<AdminAuthServiceInterface>((ref) {
  if (AppConfig.useMockServices) {
    return MockAdminAuthService();
  } else {
    final storage = StorageService.instance;
    final api = ApiClient();
    api.dio.interceptors.add(AuthInterceptor(storage, api.dio));
    api.dio.interceptors.add(ErrorInterceptor());
    return RealAdminAuthService(api, storage);
  }
});

final adminAuthNotifierProvider = StateNotifierProvider<AdminAuthNotifier, AdminAuthState>((ref) {
  final service = ref.watch(adminAuthServiceProvider);
  final storage = StorageService.instance;
  return AdminAuthNotifier(service, storage);
});

class AdminAuthNotifier extends StateNotifier<AdminAuthState> {
  final AdminAuthServiceInterface _service;
  final StorageService _storage;

  AdminAuthNotifier(this._service, this._storage) : super(const AdminAuthState()) {
    _checkAdminAuthState();
  }

  Future<void> _checkAdminAuthState() async {
    final token = await _storage.getAccessToken();
    if (token == null) {
      state = const AdminAuthState(status: AdminAuthStatus.unauthenticated);
      return;
    }
    try {
      final profile = await _service.getProfile();
      state = state.copyWith(status: AdminAuthStatus.authenticated, profile: profile);
    } catch (_) {
      await _storage.clearAll();
      state = const AdminAuthState(status: AdminAuthStatus.unauthenticated);
    }
  }

  Future<bool> requestOtp(String email) async {
    state = state.copyWith(status: AdminAuthStatus.loading).clearError();
    try {
      await _service.requestOtp(email);
      state = state.copyWith(status: AdminAuthStatus.otpSent, emailOrPhone: email);
      return true;
    } catch (e) {
      state = state.copyWith(status: AdminAuthStatus.error, errorMessage: 'Failed to send OTP.');
      return false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    final email = state.emailOrPhone;
    if (email == null) return false;

    state = state.copyWith(status: AdminAuthStatus.loading).clearError();
    try {
      final response = await _service.verifyOtp(email, otp);
      await _handleLoginSuccess(response);
      return true;
    } on AdminAuthException catch (e) {
      state = state.copyWith(status: AdminAuthStatus.error, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(status: AdminAuthStatus.error, errorMessage: 'Failed to verify OTP.');
      return false;
    }
  }

  Future<bool> ssoLogin(String provider, String idToken) async {
    state = state.copyWith(status: AdminAuthStatus.loading).clearError();
    try {
      final request = AdminSsoRequest(provider: provider, idToken: idToken);
      final response = await _service.ssoLogin(request);
      await _handleLoginSuccess(response);
      return true;
    } catch (e) {
      state = state.copyWith(status: AdminAuthStatus.error, errorMessage: 'SSO Login Failed.');
      return false;
    }
  }

  Future<void> _handleLoginSuccess(AdminLoginResponse response) async {
    await _storage.saveTokens(response.accessToken, response.refreshToken);
    await _storage.saveUserMeta(
      userId: response.user['id'] ?? '',
      role: response.user['role'] ?? 'ADMIN',
      tenantId: response.user['tenant_id'],
      isEmployee: false,
    );
    
    final profile = AdminProfile.fromJson(response.user);
    state = state.copyWith(status: AdminAuthStatus.authenticated, profile: profile).clearError();
  }

  Future<void> updateRole(String newRole) async {
    if (state.profile == null) return;
    
    state = state.copyWith(status: AdminAuthStatus.loading).clearError();
    // Simulate API delay for role switch
    await Future.delayed(const Duration(milliseconds: 500));
    
    final updatedProfile = AdminProfile(
      id: state.profile!.id,
      name: state.profile!.name,
      role: newRole,
      tenantId: newRole == 'OPS_ADMIN' ? 'tenant-infosys-001' : null,
      permissions: MockAdminAuthService.getPermissionsForRole(newRole),
    );

    // Update storage
    await _storage.saveUserMeta(
      userId: updatedProfile.id,
      role: updatedProfile.role,
      tenantId: updatedProfile.tenantId,
      isEmployee: false,
    );

    state = state.copyWith(status: AdminAuthStatus.authenticated, profile: updatedProfile).clearError();
  }

  Future<void> logout() async {
    await _service.logout();
    await _storage.clearAll();
    state = const AdminAuthState(status: AdminAuthStatus.unauthenticated);
  }
}
