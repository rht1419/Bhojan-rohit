class AppConstants {
  static const String appName = 'Bhojan';

  // Secure Storage Keys — tokens
  static const String tokenKey        = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  // Secure Storage Keys — user metadata
  static const String userRoleKey     = 'user_role';
  static const String tenantIdKey     = 'tenant_id';
  static const String isEmployeeKey   = 'is_employee';
  static const String userIdKey       = 'user_id';
  static const String userProfileKey  = 'user_profile';

  // Timeouts
  static const int connectionTimeoutMs = 15000;
  static const int receiveTimeoutMs    = 15000;

  // OTP
  static const int otpLength          = 6;
  static const int otpResendSeconds   = 60;
  static const int otpExpirySeconds   = 300;

  // Password policy
  static const int passwordMinLength  = 8;
}
