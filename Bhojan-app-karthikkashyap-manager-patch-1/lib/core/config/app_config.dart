/// App-wide configuration flags.
/// Flip [useMockServices] to false when connecting to the staging/real API.
class AppConfig {
  /// When true, Riverpod providers inject MockXxxService implementations.
  /// When false, they inject RealXxxService implementations backed by Dio.
  static const bool useMockServices = false;

  /// API base URL — switch per environment.
  /// Mock mode ignores this; real mode uses it as the Dio baseUrl.
  static const String apiBaseUrl = 'http://localhost:3000';
}
