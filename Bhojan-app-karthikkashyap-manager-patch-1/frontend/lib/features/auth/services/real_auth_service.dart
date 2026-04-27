import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/utils/storage_service.dart';
import 'package:flutter/foundation.dart';
import '../models/auth_response_models.dart';
import '../models/tenant_model.dart';
import '../models/user_model.dart';
import '../../profile/models/profile_model.dart';
import 'auth_service.dart';

/// Real implementation of [AuthServiceInterface].
/// Makes actual Dio HTTP calls against the staging/production API.
class RealAuthService implements AuthServiceInterface {
  final ApiClient _api;
  final StorageService _storage;

  RealAuthService(this._api, this._storage);

  // ── EP-01 ─────────────────────────────────────────────────────────

  @override
  Future<OtpReferenceResponse> register(RegisterRequest request) async {
    final payload = request.toJson();
    debugPrint('[DBG-H7] register request path=${ApiEndpoints.register} payload=$payload');
    try {
      final response = await _api.post(ApiEndpoints.register, data: payload);
      debugPrint('[DBG-H7] register response status=${response.statusCode} body=${response.data}');
      return OtpReferenceResponse.fromJson(response.data['data']);
    } catch (e) {
      debugPrint('[DBG-H7] register error=$e');
      rethrow;
    }
  }

  // ── EP-02 ─────────────────────────────────────────────────────────

  @override
  Future<AuthTokenResponse> verifyOtp(OtpVerifyRequest request) async {
    final payload = request.toJson();
    debugPrint('[DBG-H8] verifyOtp request path=${ApiEndpoints.otpVerify} payload=$payload');
    try {
      final response = await _api.post(ApiEndpoints.otpVerify, data: payload);
      debugPrint('[DBG-H8] verifyOtp response status=${response.statusCode} body=${response.data}');
      final data = response.data['data'];
      await _storage.saveTokens(data['access_token'], data['refresh_token']);
      return AuthTokenResponse.fromJson(data);
    } catch (e) {
      debugPrint('[DBG-H8] verifyOtp error=$e');
      rethrow;
    }
  }

  // ── EP-03 Password Login ──────────────────────────────────────────

  @override
  Future<AuthTokenResponse> loginWithPassword(PasswordLoginRequest request) async {
    final response = await _api.post(ApiEndpoints.loginPassword, data: request.toJson());
    final data = response.data['data'];
    await _storage.saveTokens(data['access_token'], data['refresh_token']);
    return AuthTokenResponse.fromJson(data);
  }

  // ── EP-03b Login OTP Request ──────────────────────────────────────

  @override
  Future<OtpReferenceResponse> requestLoginOtp(String phone) async {
    final payload = {'phone': phone};
    debugPrint('[DBG-H9] loginOtpRequest request path=${ApiEndpoints.loginOtpRequest} payload=$payload');
    try {
      final response = await _api.post(ApiEndpoints.loginOtpRequest, data: payload);
      debugPrint('[DBG-H9] loginOtpRequest response status=${response.statusCode} body=${response.data}');
      return OtpReferenceResponse.fromJson(response.data['data']);
    } catch (e) {
      debugPrint('[DBG-H9] loginOtpRequest error=$e');
      rethrow;
    }
  }

  // ── EP-04 ─────────────────────────────────────────────────────────

  @override
  Future<AuthTokenResponse> refreshToken(String refreshToken) async {
    final response = await _api.post(ApiEndpoints.tokenRefresh, data: {'refresh_token': refreshToken});
    final data = response.data['data'];
    await _storage.saveTokens(data['access_token'], data['refresh_token']);
    return AuthTokenResponse.fromJson(data);
  }

  // ── EP-05 ─────────────────────────────────────────────────────────

  @override
  Future<void> logout(String refreshToken) async {
    try {
      await _api.post(ApiEndpoints.logout, data: {'refresh_token': refreshToken});
    } catch (_) {
      // Proceed to clear even if API fails.
    }
    await _storage.clearAll();
  }

  // ── EP-06 ─────────────────────────────────────────────────────────

  @override
  Future<ProfileModel> getProfile() async {
    final response = await _api.get(ApiEndpoints.getProfile);
    return ProfileModel.fromJson(response.data['data']);
  }

  // ── EP-07 ─────────────────────────────────────────────────────────

  @override
  Future<ProfileModel> updateProfile(Map<String, dynamic> fields) async {
    final response = await _api.put(ApiEndpoints.updateProfile, data: fields);
    return ProfileModel.fromJson(response.data['data']['profile']);
  }

  // ── EP-09 ─────────────────────────────────────────────────────────

  @override
  Future<OtpReferenceResponse> requestPasswordReset(PasswordResetRequest request) async {
    final response = await _api.post(ApiEndpoints.passwordResetRequest, data: request.toJson());
    return OtpReferenceResponse.fromJson(response.data['data']);
  }

  // ── EP-10 ─────────────────────────────────────────────────────────

  @override
  Future<void> verifyPasswordReset(PasswordResetVerifyRequest request) async {
    await _api.post(ApiEndpoints.passwordResetVerify, data: request.toJson());
  }

  // ── EP-11 ─────────────────────────────────────────────────────────

  @override
  Future<ContactChangeResponse> requestContactChange(ContactChangeRequest request) async {
    final response = await _api.post(ApiEndpoints.contactChange, data: request.toJson());
    return ContactChangeResponse.fromJson(response.data['data']);
  }

  // ── EP-12 ─────────────────────────────────────────────────────────

  @override
  Future<AuthTokenResponse> verifyContactChange(ContactVerifyRequest request) async {
    final response = await _api.post(ApiEndpoints.contactVerify, data: request.toJson());
    final data = response.data['data'];
    await _storage.saveTokens(data['access_token'], data['refresh_token']);
    return AuthTokenResponse.fromJson(data);
  }

  // ── EP-13 ─────────────────────────────────────────────────────────

  @override
  Future<void> deleteAccount(String otp, String? reason) async {
    await _api.delete(ApiEndpoints.deleteAccount, data: {
      'otp': otp,
      if (reason != null) 'reason': reason,
    });
    await _storage.clearAll();
  }

  // ── EP-14 ─────────────────────────────────────────────────────────

  @override
  Future<AuthTokenResponse> upgradeToEmployee(UpgradeToEmployeeRequest request) async {
    final response = await _api.post(ApiEndpoints.upgradeToEmployee, data: request.toJson());
    final data = response.data['data'];
    await _storage.saveTokens(data['access_token'], data['refresh_token']);
    return AuthTokenResponse.fromJson(data);
  }

  // ── EP-35 ─────────────────────────────────────────────────────────

  @override
  Future<List<TenantModel>> getTenants() async {
    final response = await _api.get(ApiEndpoints.tenants);
    final list = response.data['data'] as List;
    return list.map((e) => TenantModel.fromJson(e)).toList();
  }

  // ── EP-37 ─────────────────────────────────────────────────────────

  @override
  Future<TenantValidateResponse> validateTenant(TenantValidateRequest request) async {
    final response = await _api.post(ApiEndpoints.tenantsValidate, data: request.toJson());
    return TenantValidateResponse.fromJson(response.data['data']);
  }
}
