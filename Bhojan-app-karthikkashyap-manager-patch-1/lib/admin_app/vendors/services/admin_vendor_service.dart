import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/admin_vendor_models.dart';

class AdminVendorService {
  final ApiClient _api;

  AdminVendorService(this._api);

  /// EP-27: GET /admin/vendors — List all vendors with optional search & filter
  Future<List<AdminVendor>> listVendors({String? search, String? status}) async {
    try {
      final response = await _api.get(
        ApiEndpoints.vendors,
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null) 'status': status,
        },
      );
      final list = response.data['data'] as List;
      return list.map((j) => AdminVendor.fromJson(j)).toList();
    } on DioException catch (e) {
      throw _parseException(e);
    }
  }

  /// EP-27: GET /admin/vendors/:id — Get vendor detail
  Future<AdminVendor> getVendor(String id) async {
    try {
      final response = await _api.get('${ApiEndpoints.vendors}/$id');
      return AdminVendor.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _parseException(e);
    }
  }

  /// EP-27: POST /admin/vendors — Create new vendor
  Future<AdminVendor> createVendor(AdminCreateVendorRequest request) async {
    try {
      final response = await _api.post(ApiEndpoints.vendors, data: request.toJson());
      return AdminVendor.fromJson(response.data['data']);
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
