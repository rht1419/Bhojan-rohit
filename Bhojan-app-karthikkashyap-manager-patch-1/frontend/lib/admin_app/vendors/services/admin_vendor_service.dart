import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/admin_vendor_models.dart';

class AdminVendorService {
  final ApiClient _api;

  AdminVendorService(this._api);

  /// GET /admin/vendors?status=all|active|pending|suspended
  Future<List<AdminVendor>> listVendors({String? status}) async {
    try {
      final response = await _api.get(
        ApiEndpoints.vendors,
        queryParameters: {
          if (status != null) 'status': status,
        },
      );
      final raw = response.data;
      final list = (raw is List ? raw : raw['data'] as List);
      return list.map((j) => AdminVendor.fromJson(j as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _parseException(e);
    }
  }

  /// POST /admin/vendors/:id/complete — Complete a self-registered vendor's profile
  Future<void> completeVendorRegistration(String vendorId, CompleteVendorRequest request) async {
    try {
      await _api.post('${ApiEndpoints.vendors}/$vendorId/complete', data: request.toJson());
    } on DioException catch (e) {
      throw _parseException(e);
    }
  }

  /// Vendor detail helper.
  /// Backend does not expose GET /admin/vendors/:id, so we resolve from list.
  Future<AdminVendor> getVendor(String id) async {
    try {
      final vendors = await listVendors(status: 'all');
      return vendors.firstWhere((v) => v.id == id);
    } catch (e) {
      throw AdminVendorException(
        code: 'USER_NOT_FOUND',
        message: 'Vendor not found.',
      );
    }
  }

  /// EP-27: POST /admin/vendors — Create new vendor
  Future<void> createVendor(AdminCreateVendorRequest request) async {
    try {
      await _api.post(ApiEndpoints.vendors, data: request.toJson());
    } on DioException catch (e) {
      throw _parseException(e);
    }
  }

  /// EP-28: POST /admin/vendors/:id/suspend
  Future<void> suspendVendor(String id, String reason) async {
    try {
      await _api.post(ApiEndpoints.vendorSuspend(id), data: {'reason': reason});
    } on DioException catch (e) {
      throw _parseException(e);
    }
  }

  /// EP-29: POST /admin/vendors/:id/reactivate
  Future<void> reactivateVendor(String id, String reason) async {
    try {
      await _api.post(ApiEndpoints.vendorReactivate(id), data: {'reason': reason});
    } on DioException catch (e) {
      throw _parseException(e);
    }
  }

  Exception _parseException(DioException e) {
    final data = e.response?.data;
    String code = 'NETWORK_ERROR';
    String message = 'Failed to connect to the server.';
    if (data != null && data is Map<String, dynamic> && data['error'] != null) {
      code = data['error']['code'] ?? code;
      message = data['error']['message'] ?? message;
    }
    return AdminVendorException(code: code, message: message);
  }
}

class AdminVendorException implements Exception {
  final String code;
  final String message;
  AdminVendorException({required this.code, required this.message});

  String get userMessage {
    switch (code) {
      case 'USER_ALREADY_EXISTS':
        return 'This phone or email is already registered.';
      case 'USER_NOT_FOUND':
        return 'Vendor not found.';
      case 'TENANT_MISMATCH':
        return 'You can only manage vendors in your own tenant.';
      default:
        return message;
    }
  }

  @override
  String toString() => 'AdminVendorException($code): $message';
}
