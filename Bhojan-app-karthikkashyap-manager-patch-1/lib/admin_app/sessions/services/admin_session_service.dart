import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';

class AdminSession {
  final String id;
  final String userId;
  final String? device;
  final String? ipAddress;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isRevoked;

  AdminSession({
    required this.id,
    required this.userId,
    this.device,
    this.ipAddress,
    required this.createdAt,
    required this.expiresAt,
    required this.isRevoked,
  });

  bool get isActive => !isRevoked && DateTime.now().isBefore(expiresAt);

  factory AdminSession.fromJson(Map<String, dynamic> json) {
    return AdminSession(
      id: json['id'],
      userId: json['user_id'] ?? '',
      device: json['device'],
      ipAddress: json['ip_address'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(json['expires_at'] ?? '') ?? DateTime.now(),
      isRevoked: json['is_revoked'] ?? false,
    );
  }
}

class AdminSessionService {
  final ApiClient _api;

  AdminSessionService(this._api);

  /// EP-33: GET /admin/sessions — List sessions
  Future<List<AdminSession>> listSessions({String? userId, bool? isActive}) async {
    try {
      final response = await _api.get(
        ApiEndpoints.sessions,
        queryParameters: {
          if (userId != null) 'user_id': userId,
          if (isActive != null) 'is_active': isActive.toString(),
        },
      );
      final list = response.data['data']['sessions'] as List? ?? [];
      return list.map((j) => AdminSession.fromJson(j)).toList();
    } on DioException catch (e) {
      throw _parseException(e);
    }
  }

  /// EP-34: DELETE /admin/sessions/:id — Revoke a session
  Future<void> revokeSession(String sessionId) async {
    try {
      await _api.delete(ApiEndpoints.sessionRevoke(sessionId));
    } on DioException catch (e) {
      throw _parseException(e);
    }
  }

  Exception _parseException(DioException e) {
    final data = e.response?.data;
    String message = 'Failed to connect to the server.';
    if (data != null && data is Map<String, dynamic> && data['error'] != null) {
      message = data['error']['message'] ?? message;
    }
    return Exception(message);
  }
}
