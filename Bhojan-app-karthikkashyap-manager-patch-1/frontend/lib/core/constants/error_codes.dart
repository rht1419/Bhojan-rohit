class ErrorCodes {
  static const String validationError       = 'VALIDATION_ERROR';
  static const String otpInvalid            = 'OTP_INVALID';
  static const String otpExpired            = 'OTP_EXPIRED';
  static const String otpMaxAttempts        = 'OTP_MAX_ATTEMPTS';
  static const String otpRateLimit          = 'OTP_RATE_LIMIT';
  static const String accountLocked         = 'ACCOUNT_LOCKED';
  static const String userNotFound          = 'USER_NOT_FOUND';
  static const String userAlreadyExists     = 'USER_ALREADY_EXISTS';
  static const String accountDeactivated    = 'ACCOUNT_DEACTIVATED';
  static const String accountSuspended      = 'ACCOUNT_SUSPENDED';
  static const String accountDeleted        = 'ACCOUNT_DELETED';
  static const String emailNotVerified      = 'EMAIL_NOT_VERIFIED';
  static const String employeeIdNotFound    = 'EMPLOYEE_ID_NOT_FOUND';
  static const String alreadyEmployee       = 'ALREADY_EMPLOYEE';
  static const String tenantMismatch        = 'TENANT_MISMATCH';
  static const String tenantClosed          = 'TENANT_CLOSED';
  static const String permissionDenied      = 'PERMISSION_DENIED';
  static const String tokenExpired          = 'TOKEN_EXPIRED';
  static const String refreshTokenInvalid   = 'REFRESH_TOKEN_INVALID';
  static const String refreshTokenReused    = 'REFRESH_TOKEN_REUSED';
  static const String ssoDomainMismatch     = 'SSO_DOMAIN_MISMATCH';
  static const String ssoProviderError      = 'SSO_PROVIDER_ERROR';
  static const String delegationExpired     = 'DELEGATION_EXPIRED';
  static const String internalError         = 'INTERNAL_ERROR';
  static const String unauthorized          = 'UNAUTHORIZED';
  static const String authLoginFailed       = 'AUTH_LOGIN_FAILED';

  /// Returns a user-friendly message for the given API error code.
  static String getMessage(String code) {
    return _messages[code] ?? 'Something went wrong. Please try again.';
  }

  static const Map<String, String> _messages = {
    'VALIDATION_ERROR':        'Please check your input and try again.',
    'OTP_INVALID':             'Incorrect OTP. Please try again.',
    'OTP_EXPIRED':             'OTP has expired. Request a new one.',
    'OTP_MAX_ATTEMPTS':        'Too many wrong attempts. Try again in 15 minutes.',
    'OTP_RATE_LIMIT':          'Too many OTP requests. Wait 15 minutes before trying again.',
    'ACCOUNT_LOCKED':          'Account locked — too many failed attempts. Try again in 15 minutes.',
    'USER_NOT_FOUND':          'No account found with this number.',
    'USER_ALREADY_EXISTS':     'This phone number is already registered.',
    'ACCOUNT_DEACTIVATED':     'Your account has been deactivated. Contact support.',
    'ACCOUNT_SUSPENDED':       'Your account has been suspended. Contact support.',
    'ACCOUNT_DELETED':         'This account no longer exists.',
    'EMAIL_NOT_VERIFIED':      'Please activate your account first. Check your email.',
    'EMPLOYEE_ID_NOT_FOUND':   'Employee ID not found. Please contact your HR admin.',
    'ALREADY_EMPLOYEE':        'Your account is already linked to a company.',
    'TENANT_MISMATCH':         'Access denied for this company.',
    'TENANT_CLOSED':           'This location is not currently accepting registrations.',
    'PERMISSION_DENIED':       'You do not have permission for this action.',
    'TOKEN_EXPIRED':           'Session expired. Please log in again.',
    'REFRESH_TOKEN_INVALID':   'Session invalid. Please log in again.',
    'REFRESH_TOKEN_REUSED':    'Security alert. Please log in again.',
    'SSO_DOMAIN_MISMATCH':     'Your company email is not registered on Bhojan.',
    'SSO_PROVIDER_ERROR':      'Google sign-in failed. Please try again.',
    'DELEGATION_EXPIRED':      'Your temporary access has expired.',
    'INTERNAL_ERROR':          'Something went wrong. Please try again.',
    'UNAUTHORIZED':            'Please log in to continue.',
    'AUTH_LOGIN_FAILED':       'Incorrect password. Please try again.',
  };
}
