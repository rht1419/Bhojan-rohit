import 'package:dio/dio.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Handle the standard 200 OK wrapper if necessary.
    // However, Dio already passed it through. Let the service layer evaluate `success: true`.
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response != null) {
      final data = err.response!.data;
      if (data is Map<String, dynamic> && data['success'] == false) {
        // Enforce the standard error envelope
        final error = data['error'];
        final message = error?['message'] ?? 'Unknown error occurred';
        err = err.copyWith(message: message);
      }
    }
    super.onError(err, handler);
  }
}
