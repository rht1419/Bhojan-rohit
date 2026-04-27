import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/utils/storage_service.dart';
import '../models/vendor_auth_models.dart';
import '../models/vendor_profile_model.dart';
import 'vendor_auth_service.dart';
import 'mock_vendor_auth_service.dart';

/// Real implementation of [VendorAuthServiceInterface].
/// Makes actual HTTP calls using Dio via [ApiClient].
class RealVendorAuthService implements VendorAuthServiceInterface {
  final ApiClient _api;
  final StorageService _storage;

  RealVendorAuthService(this._api, this._storage);

  // ── Registration & OTP (New Flow) ─────────────────────────────────

  @override
  Future<void> register(VendorRegisterRequest request) async {
    try {
      await _api.dio.post(ApiEndpoints.vendorSelfRegister, data: request.toJson());
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<void> requestOtp(String phone) async {
    try {
      await _api.dio.post(ApiEndpoints.vendorRequestOtp, data: {'phone': phone});
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<VendorLoginResponse> verifyOtp(VerifyOtpRequest request) async {
    try {
      final response = await _api.dio.post(ApiEndpoints.vendorVerifyOtp, data: request.toJson());
      final data = response.data['data'];
      final result = VendorLoginResponse.fromJson(data);

      await _storage.saveTokens(result.accessToken, result.refreshToken);
      await _storage.saveUserMeta(
        userId: result.user['id'] ?? '',
        role: result.user['role'] ?? 'VENDOR',
        tenantId: result.user['tenant_id'],
        isEmployee: false,
      );

      return result;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  // ── EP-17 ─────────────────────────────────────────────────────────

  @override
  Future<void> activateAccount(VendorActivateRequest request) async {
    try {
      await _api.dio.post(ApiEndpoints.vendorActivate, data: request.toJson());
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  // ── EP-18 ─────────────────────────────────────────────────────────

  @override
  Future<VendorLoginResponse> login(VendorLoginRequest request) async {
    try {
      final response = await _api.dio.post(ApiEndpoints.vendorLogin, data: request.toJson());
      final data = response.data['data'];
      final result = VendorLoginResponse.fromJson(data);

      // Save tokens and vendor metadata to secure storage
      await _storage.saveTokens(result.accessToken, result.refreshToken);
      await _storage.saveUserMeta(
        userId: result.user['id'] ?? '',
        role: result.user['role'] ?? 'VENDOR',
        tenantId: result.user['tenant_id'],
        isEmployee: false,
      );

      return result;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow; // unreachable but satisfies compiler
    }
  }

  // ── Get Profile ───────────────────────────────────────────────────

  @override
  Future<VendorProfileModel> getProfile() async {
    try {
      final response = await _api.dio.get(ApiEndpoints.getProfile);
      final data = response.data['data'];
      // Merge user and profile objects
      final Map<String, dynamic> merged = {};
      if (data['user'] != null) merged.addAll(Map<String, dynamic>.from(data['user']));
      if (data['vendor_profile'] != null) merged.addAll(Map<String, dynamic>.from(data['vendor_profile']));
      if (data['profile'] != null) merged.addAll(Map<String, dynamic>.from(data['profile']));
      return VendorProfileModel.fromJson(merged);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  // ── EP-19 ─────────────────────────────────────────────────────────

  @override
  Future<VendorProfileModel> updateProfile(Map<String, dynamic> fields) async {
    try {
      final response = await _api.dio.put(ApiEndpoints.vendorProfile, data: fields);
      final data = response.data['data'];
      return VendorProfileModel.fromJson(data['vendor_profile'] ?? data);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  // ── EP-04 ─────────────────────────────────────────────────────────

  @override
  Future<VendorLoginResponse> refreshToken(String refreshToken) async {
    try {
      final response = await _api.dio.post(
        ApiEndpoints.tokenRefresh,
        data: {'refresh_token': refreshToken},
      );
      final data = response.data['data'];
      final result = VendorLoginResponse.fromJson(data);

      await _storage.saveTokens(result.accessToken, result.refreshToken);

      return result;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  // ── EP-05 ─────────────────────────────────────────────────────────

  @override
  Future<void> logout(String refreshToken) async {
    try {
      await _api.dio.post(ApiEndpoints.logout, data: {'refresh_token': refreshToken});
    } on DioException catch (_) {
      // Logout should succeed even on error — clear local storage anyway.
    }
    await _storage.clearAll();
  }

  // ── Error handler ─────────────────────────────────────────────────

  void _handleDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['error'] != null) {
      final error = data['error'];
      dynamic rawMsg = error['message'];
      String message;
      if (rawMsg is List) {
        message = rawMsg.join('\n');
      } else if (rawMsg is String) {
        message = rawMsg;
      } else {
        message = 'Something went wrong.';
      }
      throw VendorAuthException(
        code: error['code'] ?? 'INTERNAL_ERROR',
        message: message,
        httpStatus: e.response?.statusCode ?? 500,
      );
    }
    throw VendorAuthException(
      code: 'INTERNAL_ERROR',
      message: e.message ?? 'Network error. Please check your connection.',
      httpStatus: e.response?.statusCode ?? 500,
    );
  }
}
