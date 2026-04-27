import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';

class AuditLog {
  final String id;
  final String? userId;
  final String? tenantId;
  final String action;
  final String module;
  final String? targetId;
  final String? ipAddress;
  final String? device;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    this.userId,
    this.tenantId,
    required this.action,
    required this.module,
    this.targetId,
    this.ipAddress,
    this.device,
    required this.metadata,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'],
      userId: json['user_id'],
      tenantId: json['tenant_id'],
      action: json['action'] ?? '',
      module: json['module'] ?? '',
      targetId: json['target_id'],
      ipAddress: json['ip_address'],
      device: json['device'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class AuditLogsResponse {
  final List<AuditLog> logs;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  AuditLogsResponse({
    required this.logs,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory AuditLogsResponse.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    return AuditLogsResponse(
      logs: (json['logs'] as List? ?? []).map((j) => AuditLog.fromJson(j)).toList(),
      page: pagination['page'] ?? 1,
      limit: pagination['limit'] ?? 50,
      total: pagination['total'] ?? 0,
      totalPages: pagination['total_pages'] ?? 1,
    );
  }
}

class AdminAuditService {
  final ApiClient _api;

  AdminAuditService(this._api);

  /// EP-22: GET /admin/audit-logs
  Future<AuditLogsResponse> getLogs({
    int page = 1,
    int limit = 50,
    String? userId,
    String? action,
    String? module,
    String? tenantId,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final response = await _api.get(
        ApiEndpoints.auditLogs,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (userId != null) 'user_id': userId,
          if (action != null) 'action': action,
          if (module != null) 'module': module,
          if (tenantId != null) 'tenant_id': tenantId,
          if (fromDate != null) 'from_date': fromDate,
          if (toDate != null) 'to_date': toDate,
        },
      );
      return AuditLogsResponse.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _parseException(e);
    }
  }

  /// EP-23: GET /admin/audit-logs/export — trigger export, returns job_id
  Future<String> requestExport({String? fromDate, String? toDate, String? action, String? tenantId}) async {
    try {
      final response = await _api.get(
        ApiEndpoints.auditLogsExport,
        queryParameters: {
          if (fromDate != null) 'from_date': fromDate,
          if (toDate != null) 'to_date': toDate,
          if (action != null) 'action': action,
          if (tenantId != null) 'tenant_id': tenantId,
        },
      );
      return response.data['data']['job_id'] as String;
    } on DioException catch (e) {
      throw _parseException(e);
    }
  }

  /// EP-23: GET /admin/audit-logs/export?job_id= — poll for status
  Future<Map<String, dynamic>> pollExport(String jobId) async {
    try {
      final response = await _api.get(ApiEndpoints.auditLogsExport, queryParameters: {'job_id': jobId});
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _parseException(e);
    }
  }

  Exception _parseException(DioException e) {
    final data = e.response?.data;
    String message = 'Failed to load audit logs.';
    if (data != null && data is Map<String, dynamic> && data['error'] != null) {
      message = data['error']['message'] ?? message;
    }
    return Exception(message);
  }
}
