import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';

class AdminEmployee {
  final String id;
  final String fullName;
  final String employeeId;
  final String email;
  final String? department;
  final String tenantId;
  final bool isActive;

  AdminEmployee({
    required this.id,
    required this.fullName,
    required this.employeeId,
    required this.email,
    this.department,
    required this.tenantId,
    required this.isActive,
  });

  factory AdminEmployee.fromJson(Map<String, dynamic> json) {
    return AdminEmployee(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      employeeId: json['employee_id'] ?? '',
      email: json['email'] ?? '',
      department: json['department'],
      tenantId: json['tenant_id'] ?? '',
      isActive: json['is_active'] ?? false,
    );
  }
}

class BulkUploadStatus {
  final String uploadId;
  final String status; // PENDING, PROCESSING, COMPLETED, FAILED
  final int totalRecords;
  final int successCount;
  final int failedCount;
  final List<Map<String, dynamic>> errorDetails;

  BulkUploadStatus({
    required this.uploadId,
    required this.status,
    required this.totalRecords,
    required this.successCount,
    required this.failedCount,
    required this.errorDetails,
  });

  factory BulkUploadStatus.fromJson(Map<String, dynamic> json) {
    return BulkUploadStatus(
      uploadId: json['upload_id'] ?? '',
      status: json['status'] ?? 'PENDING',
      totalRecords: json['total_records'] ?? 0,
      successCount: json['success_count'] ?? 0,
      failedCount: json['failed_count'] ?? 0,
      errorDetails: List<Map<String, dynamic>>.from(json['error_details'] ?? []),
    );
  }
}

class AdminEmployeeService {
  final ApiClient _api;

  AdminEmployeeService(this._api);

  /// EP-24: POST /admin/employees/bulk-upload — Upload CSV
  Future<BulkUploadStatus> bulkUpload({
    required List<int> fileBytes,
    required String fileName,
    String? tenantId,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
        if (tenantId != null) 'tenant_id': tenantId,
      });
      final response = await _api.post(ApiEndpoints.bulkUpload, data: formData);
      return BulkUploadStatus.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _parseException(e);
    }
  }

  /// EP-25: GET /admin/employees/bulk-upload/:id — Poll upload status
  Future<BulkUploadStatus> getBulkUploadStatus(String uploadId) async {
    try {
      final response = await _api.get('${ApiEndpoints.bulkUpload}/$uploadId');
      return BulkUploadStatus.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _parseException(e);
    }
  }

  /// List employees for offboard search
  Future<List<AdminEmployee>> listEmployees({String? search, String? tenantId}) async {
    try {
      final response = await _api.get(
        '/admin/employees',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (tenantId != null) 'tenant_id': tenantId,
        },
      );
      final list = response.data['data'] as List;
      return list.map((j) => AdminEmployee.fromJson(j)).toList();
    } on DioException catch (e) {
      throw _parseException(e);
    }
  }

  /// EP-26: POST /admin/employees/:id/offboard
  Future<void> offboardEmployee(String userId, String reason) async {
    try {
      await _api.post(ApiEndpoints.employeeOffboard(userId), data: {'reason': reason});
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
    return AdminEmployeeException(code: code, message: message);
  }
}

class AdminEmployeeException implements Exception {
  final String code;
  final String message;
  AdminEmployeeException({required this.code, required this.message});

  String get userMessage {
    switch (code) {
      case 'TENANT_MISMATCH':
        return 'You can only offboard employees in your own tenant.';
      case 'USER_NOT_FOUND':
        return 'Employee not found.';
      default:
        return message;
    }
  }

  @override
  String toString() => 'AdminEmployeeException($code): $message';
}
