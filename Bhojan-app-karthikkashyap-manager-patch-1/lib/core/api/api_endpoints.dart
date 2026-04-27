class ApiEndpoints {
  // Base URL — overridden by AppConfig in real mode
  static const String baseUrl = 'http://localhost:3000';

  // ── User App — Auth ──────────────────────────────────────────────
  static const String register            = '/auth/register';           // EP-01
  static const String otpVerify           = '/auth/otp/verify';         // EP-02
  static const String loginPassword       = '/auth/login/password';     // EP-03
  static const String tokenRefresh        = '/auth/token/refresh';      // EP-04
  static const String logout              = '/auth/logout';             // EP-05
  static const String getProfile          = '/auth/me';                 // EP-06
  static const String updateProfile       = '/auth/profile';            // EP-07
  static const String uploadAvatar        = '/auth/profile/avatar';     // EP-08
  static const String passwordResetRequest = '/auth/password/reset-request'; // EP-09
  static const String passwordResetVerify = '/auth/password/reset-verify';   // EP-10
  static const String contactChange       = '/auth/contact/change';     // EP-11
  static const String contactVerify       = '/auth/contact/verify';     // EP-12
  static const String deleteAccount       = '/auth/account';            // EP-13
  static const String upgradeToEmployee   = '/auth/upgrade-to-employee'; // EP-14
  static const String ssoGoogle           = '/auth/sso/google';         // EP-15
  static const String ssoGoogleCallback   = '/auth/sso/google/callback'; // EP-16

  // ── Vendor App — Auth ────────────────────────────────────────────
  static const String vendorActivate      = '/vendor/auth/activate';    // EP-17
  static const String vendorLogin         = '/vendor/auth/login';       // EP-18
  static const String vendorProfile       = '/vendor/auth/profile';     // EP-19

  // ── Admin App — Auth ─────────────────────────────────────────────
  static const String adminLogin          = '/admin/auth/login';        // EP-20
  static const String adminPermissions    = '/admin/auth/permissions';  // EP-21
  static const String auditLogs           = '/admin/audit-logs';        // EP-22
  static const String auditLogsExport     = '/admin/audit-logs/export'; // EP-23
  static const String bulkUpload          = '/admin/employees/bulk-upload'; // EP-24
  static String employeeOffboard(String id) => '/admin/employees/$id/offboard'; // EP-26
  static const String vendors             = '/admin/vendors';           // EP-27
  static String vendorSuspend(String id)   => '/admin/vendors/$id/suspend';    // EP-28
  static String vendorReactivate(String id) => '/admin/vendors/$id/reactivate'; // EP-29
  static const String delegates           = '/admin/delegates';         // EP-30, EP-31
  static String delegateRevoke(String id)  => '/admin/delegates/$id';   // EP-32
  static const String sessions            = '/admin/sessions';          // EP-33
  static String sessionRevoke(String id)   => '/admin/sessions/$id';    // EP-34

  // ── Tenants — Public ─────────────────────────────────────────────
  static const String tenants             = '/tenants';                 // EP-35
  static String tenantSettings(String id)  => '/tenants/$id/settings';  // EP-36
  static const String tenantsValidate     = '/tenants/validate';        // EP-37
}
