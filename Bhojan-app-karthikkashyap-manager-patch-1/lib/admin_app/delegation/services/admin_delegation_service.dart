import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';

class AdminDelegation {
  final String id;
  final Map<String, dynamic> delegator;
  final Map<String, dynamic> delegatee;
  final String module;
  final bool isActive;
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final String? reason;

  AdminDelegation({
    required this.id,
    required this.delegator,
    required this.delegatee,
    required this.module,
    required this.isActive,
    this.startsAt,
    this.expiresAt,
    this.reason,
  });

  factory AdminDelegation.fromJson(Map<String, dynamic> json) {
    return AdminDelegation(
      id: json['id'],
      delegator: Map<String, dynamic>.from(json['delegator'] ?? {}),
      delegatee: Map<String, dynamic>.from(json['delegatee'] ?? {}),
      module: json['module'] ?? '',
      isActive: json['is_active'] ?? false,
      startsAt: json['starts_at'] != null ? DateTime.tryParse(json['starts_at']) : null,
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at']) : null,
      reason: json['reason'],
    );
  }
}

class AdminDelegationService {
  final ApiClient _api;

  AdminDelegationService(this._api);

  /// EP-31: GET /admin/delegations
  Future<List<AdminDelegation>> listDelegations({bool? isActive}) async {
    try {
      final response = await _api.get(
        ApiEndpoints.delegates,
        queryParameters: {
          if (isActive != null) 'is_active': isActive.toString(),
        },
      );
      final list = response.data['data']['delegations'] as List? ?? [];
      return list.map((j) => AdminDelegation.fromJson(j)).toList();
    } on DioException catch (e) {
      throw _parseException(e);
    }
  }

  /// EP-30: POST /admin/delegations — Create delegation
  Future<AdminDelegation> createDelegation({
    required String delegateeId,
    required String module,
    required DateTime expiresAt,
    DateTime? startsAt,
    String? reason,
  }) async {
    try {
      final response = await _api.post(ApiEndpoints.delegates, data: {
        'delegatee_id': delegateeId,
        'module': module,
        'expires_at': expiresAt.toIso8601String(),
        if (startsAt != null) 'starts_at': startsAt.toIso8601String(),
        if (reason != null) 'reason': reason,
      });
      return AdminDelegation.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _parseException(e);
    }
  }

  /// EP-32: DELETE /admin/delegations/:id — Revoke
  Future<void> revokeDelegation(String id) async {
    try {
      await _api.delete(ApiEndpoints.delegateRevoke(id));
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
    return AdminDelegationException(code: code, message: message);
  }
}

class AdminDelegationException implements Exception {
  final String code;
  final String message;
  AdminDelegationException({required this.code, required this.message});

  String get userMessage {
    switch (code) {
      case 'USER_NOT_FOUND':
        return 'Delegatee admin not found.';
      case 'VALIDATION_ERROR':
        return 'Expiry date must be in the future.';
      default:
        return message;
    }
  }

  @override
  String toString() => 'AdminDelegationException($code): $message';
}
