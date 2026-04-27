import 'dart:async';
import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/utils/storage_service.dart';
import '../models/admin_auth_models.dart';

abstract class AdminAuthServiceInterface {
  Future<void> requestOtp(String email);
  Future<AdminLoginResponse> verifyOtp(String email, String otp);
  Future<AdminLoginResponse> ssoLogin(AdminSsoRequest request);
  Future<AdminProfile> getProfile();
  Future<void> logout();
}

class MockAdminAuthService implements AdminAuthServiceInterface {
  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 1000));

  @override
  Future<void> requestOtp(String email) async {
    await _delay();
    // Simulate sending OTP. In mock, any email is accepted.
  }

  @override
  Future<AdminLoginResponse> verifyOtp(String email, String otp) async {
    await _delay();
    
    if (otp != '123456') {
      throw AdminAuthException(
        code: 'INVALID_OTP',
        message: 'Invalid OTP entered.',
        httpStatus: 401,
      );
    }

    // Determine initial role based on email if possible, else default to Ops Admin
    String role = 'OPS_ADMIN';
    if (email.contains('super')) role = 'SUPER_ADMIN';
    if (email.contains('tech')) role = 'TECH_ADMIN';
    if (email.contains('sub')) role = 'SUB_ADMIN';

    return AdminLoginResponse(
      accessToken: 'mock-admin-token-123',
      refreshToken: 'mock-admin-refresh-123',
      user: {
        'id': 'admin-uuid-001',
        'name': 'System Administrator',
        'role': role, // Will be updated during Role Selection step
        'tenant_id': role == 'OPS_ADMIN' ? 'tenant-infosys-001' : null,
        'permissions': getPermissionsForRole(role),
      },
    );
  }

  @override
  Future<AdminLoginResponse> ssoLogin(AdminSsoRequest request) async {
    await _delay();
    return AdminLoginResponse(
      accessToken: 'mock-sso-token',
      refreshToken: 'mock-sso-refresh',
      user: {
        'id': 'admin-uuid-002',
        'name': 'SSO Administrator',
        'role': 'SUPER_ADMIN',
        'tenant_id': null,
        'permissions': getPermissionsForRole('SUPER_ADMIN'),
      },
    );
  }

  @override
  Future<AdminProfile> getProfile() async {
    await _delay();
    return AdminProfile(
      id: 'admin-uuid-001',
      name: 'System Administrator',
      role: 'SUPER_ADMIN',
      permissions: getPermissionsForRole('SUPER_ADMIN'),
    );
  }

  @override
  Future<void> logout() async {
    await _delay();
  }

  static List<String> getPermissionsForRole(String role) {
    if (role == 'SUPER_ADMIN') {
      return [
        'auth_view', 'auth_edit', 
        'orders_view', 'orders_edit', 
        'vendors_view', 'vendors_edit', 
        'logs_view', 'logs_edit', 
        'config_db_view', 'config_db_edit', 
        'delegate_view', 'delegate_edit', 
        'bulk_upload_view', 'bulk_upload_edit'
      ];
    } else if (role == 'OPS_ADMIN') {
      return [
        'orders_view', 'orders_edit', 
        'vendors_view', 'vendors_edit', 
        'logs_view', // Read-only logs
        'bulk_upload_view', 'bulk_upload_edit'
      ];
    } else if (role == 'TECH_ADMIN') {
      return [
        'logs_view', 'logs_edit', 
        'config_db_view', 'config_db_edit'
      ];
    } else if (role == 'SUB_ADMIN') {
      return [
        'orders_view', 'vendors_view' // Limited view-only access
      ];
    }
    return [];
  }
}

class RealAdminAuthService implements AdminAuthServiceInterface {
  final ApiClient _api;
  final StorageService _storage;

  RealAdminAuthService(this._api, this._storage);

  @override
  Future<void> requestOtp(String email) async {
    try {
      await _api.post(ApiEndpoints.adminLogin, data: {'email': email});
    } on DioException catch (e) {
      throw _parseException(e);
    }
  }

  @override
  Future<AdminLoginResponse> verifyOtp(String email, String otp) async {
    try {
      final response = await _api.post(ApiEndpoints.adminLogin, data: {
        'email': email,
        'otp': otp,
      });
      final data = response.data['data'];
      await _storage.saveTokens(data['access_token'], data['refresh_token']);
      return AdminLoginResponse.fromJson(data);
    } on DioException catch (e) {
      throw _parseException(e);
    }
  }

  @override
  Future<AdminLoginResponse> ssoLogin(AdminSsoRequest request) async {
    // There is no explicit Admin SSO endpoint in the current contract (only User Google SSO EP-15).
    // We'll throw an unimplemented error for now, or you can point it to a real endpoint if added.
    throw UnimplementedError('Admin SSO not yet supported by backend');
  }

  @override
  Future<AdminProfile> getProfile() async {
    try {
      // EP-21 returns permissions. Let's use it for the profile
      final response = await _api.get(ApiEndpoints.adminPermissions);
      final data = response.data['data'];
      return AdminProfile(
        id: data['id'] ?? 'unknown',
        name: data['name'] ?? 'Admin',
        role: data['role'] ?? 'ADMIN',
        tenantId: data['tenant_id'],
        permissions: List<String>.from(data['permissions'] ?? []),
      );
    } on DioException catch (e) {
      throw _parseException(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) {
        await _api.post(ApiEndpoints.logout, data: {'refresh_token': refreshToken});
      }
    } catch (_) {
      // Ignore errors on logout
    } finally {
      await _storage.clearTokens();
    }
  }

  AdminAuthException _parseException(DioException e) {
    final data = e.response?.data;
    if (data != null && data is Map<String, dynamic> && data['error'] != null) {
      final error = data['error'];
      dynamic rawMsg = error['message'];
      String message;
      if (rawMsg is List) {
        message = rawMsg.join('\n');
      } else if (rawMsg is String) {
        message = rawMsg;
      } else {
        message = 'An unknown error occurred';
      }
      return AdminAuthException(
        code: error['code'] ?? 'UNKNOWN_ERROR',
        message: message,
        httpStatus: e.response?.statusCode,
      );
    }
    return AdminAuthException(
      code: 'NETWORK_ERROR',
      message: 'Failed to connect to the server',
      httpStatus: e.response?.statusCode,
    );
  }
}
