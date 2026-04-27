import 'package:dio/dio.dart';
import '../../utils/storage_service.dart';
import '../../constants/error_codes.dart';
import '../api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  final StorageService _storageService;
  final Dio _dio;

  AuthInterceptor(this._storageService, this._dio);

  /// Public endpoints that must NOT include an Authorization header.
  static final _publicEndpoints = <String>{
    ApiEndpoints.register,
    ApiEndpoints.loginPassword,
    ApiEndpoints.otpVerify,
    ApiEndpoints.passwordResetRequest,
    ApiEndpoints.passwordResetVerify,
    ApiEndpoints.tenants,
    ApiEndpoints.tenantsValidate,
    // Vendor self-registration (unauthenticated)
    ApiEndpoints.vendorSelfRegister,
    ApiEndpoints.vendorRequestOtp,
    ApiEndpoints.vendorVerifyOtp,
    ApiEndpoints.vendorActivate,
    ApiEndpoints.vendorLogin,
    ApiEndpoints.adminLogin,
  };

  // ── Attach Bearer token ──────────────────────────────────────────

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (_publicEndpoints.contains(options.path)) {
      return super.onRequest(options, handler);
    }

    if (options.path == ApiEndpoints.tokenRefresh) {
      // Token-refresh uses refresh_token in body; no bearer header.
      return super.onRequest(options, handler);
    }

    final token = await _storageService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  // ── Handle 401 / 403 errors ──────────────────────────────────────

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final errorCode = _extractErrorCode(err);

    // ── 401 — Token expired → try refresh ──────────────────────────
    if (statusCode == 401 && err.requestOptions.path != ApiEndpoints.tokenRefresh) {
      if (errorCode == ErrorCodes.tokenExpired) {
        final success = await _refreshToken();
        if (success) {
          // Retry the original request with the new access token
          final token = await _storageService.getAccessToken();
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $token';
          try {
            final response = await _dio.fetch(opts);
            return handler.resolve(response);
          } catch (_) {
            return handler.next(err);
          }
        }
      }

      // Refresh token invalid / reused → force logout
      if (errorCode == ErrorCodes.refreshTokenInvalid ||
          errorCode == ErrorCodes.refreshTokenReused) {
        await _storageService.clearAll();
        // Navigation to login is driven reactively by AuthNotifier state.
      }
    }

    // ── 403 — Account-level blocks → clear & redirect ──────────────
    if (statusCode == 403) {
      if (errorCode == ErrorCodes.accountSuspended ||
          errorCode == ErrorCodes.accountDeleted ||
          errorCode == ErrorCodes.accountDeactivated) {
        await _storageService.clearAll();
        // AuthNotifier state change will trigger navigation to login.
      }
    }

    super.onError(err, handler);
  }

  // ── Helpers ──────────────────────────────────────────────────────

  String? _extractErrorCode(DioException err) {
    final data = err.response?.data;
    if (data is Map<String, dynamic> && data['success'] == false) {
      return data['error']?['code'] as String?;
    }
    return null;
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio.post(
        ApiEndpoints.tokenRefresh,
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'Authorization': ''}), // bypass normal auth
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final newAccess  = response.data['data']['access_token'] as String;
        final newRefresh = response.data['data']['refresh_token'] as String;
        await _storageService.saveTokens(newAccess, newRefresh);
        return true;
      }
    } catch (_) {
      // refresh failed
    }
    return false;
  }
}
