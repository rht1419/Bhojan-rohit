import '../models/auth_response_models.dart';
import '../models/tenant_model.dart';
import '../models/user_model.dart';
import '../../profile/models/profile_model.dart';
import 'auth_service.dart';

/// Mock implementation of [AuthServiceInterface].
/// Returns hardcoded contract-matching responses with simulated network delay.
/// Used for development while the backend is being built.
class MockAuthService implements AuthServiceInterface {

  /// Simulated network delay.
  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 500));

  // ── EP-01 ─────────────────────────────────────────────────────────

  @override
  Future<OtpReferenceResponse> register(RegisterRequest request) async {
    await _delay();
    return OtpReferenceResponse(
      otpReference: 'mock-otp-ref-${DateTime.now().millisecondsSinceEpoch}',
      expiresIn: 300,
    );
  }

  // ── EP-02 ─────────────────────────────────────────────────────────

  @override
  Future<AuthTokenResponse> verifyOtp(OtpVerifyRequest request) async {
    await _delay();
    return AuthTokenResponse(
      accessToken:  'mock-access-token-${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'mock-refresh-token-${DateTime.now().millisecondsSinceEpoch}',
      user: {
        'id': 'user-uuid-001',
        'phone': request.phone,
        'email': null,
        'full_name': 'Mock User',
        'role': 'GUEST',
        'tenant_id': null,
        'is_employee': false,
        'employee_id': null,
        'is_verified': true,
        'last_login_at': DateTime.now().toIso8601String(),
      },
    );
  }

  // ── EP-03 Password Login ──────────────────────────────────────────

  @override
  Future<AuthTokenResponse> loginWithPassword(PasswordLoginRequest request) async {
    await _delay();
    return AuthTokenResponse(
      accessToken:  'mock-access-token-${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'mock-refresh-token-${DateTime.now().millisecondsSinceEpoch}',
      user: {
        'id': 'user-uuid-001',
        'phone': request.phone,
        'email': null,
        'full_name': 'Mock User',
        'role': 'GUEST',
        'tenant_id': null,
        'is_employee': false,
        'employee_id': null,
        'is_verified': true,
        'last_login_at': DateTime.now().toIso8601String(),
      },
    );
  }

  // ── EP-03b Login OTP Request ──────────────────────────────────────

  @override
  Future<OtpReferenceResponse> requestLoginOtp(String phone) async {
    await _delay();
    return OtpReferenceResponse(
      otpReference: 'mock-login-otp-ref-${DateTime.now().millisecondsSinceEpoch}',
      expiresIn: 300,
    );
  }

  // ── EP-04 ─────────────────────────────────────────────────────────

  @override
  Future<AuthTokenResponse> refreshToken(String refreshToken) async {
    await _delay();
    return AuthTokenResponse(
      accessToken:  'mock-access-refreshed-${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'mock-refresh-rotated-${DateTime.now().millisecondsSinceEpoch}',
      user: {
        'id': 'user-uuid-001',
        'phone': '+919999999999',
        'full_name': 'Mock User',
        'role': 'GUEST',
        'is_employee': false,
      },
    );
  }

  // ── EP-05 ─────────────────────────────────────────────────────────

  @override
  Future<void> logout(String refreshToken) async {
    await _delay();
    // Mock: nothing to do server-side.
  }

  // ── EP-06 ─────────────────────────────────────────────────────────

  @override
  Future<ProfileModel> getProfile() async {
    await _delay();
    return ProfileModel.fromJson({
      'id': 'user-uuid-001',
      'phone': '+919999999999',
      'email': null,
      'full_name': 'Mock User',
      'role': 'GUEST',
      'tenant_id': null,
      'is_employee': false,
      'employee_id': null,
      'avatar_url': null,
      'department': null,
      'floor': null,
      'building': null,
      'dietary_preference': null,
      'language': 'en',
      'notifications_enabled': true,
      'last_login_at': DateTime.now().toIso8601String(),
    });
  }

  // ── EP-07 ─────────────────────────────────────────────────────────

  @override
  Future<ProfileModel> updateProfile(Map<String, dynamic> fields) async {
    await _delay();
    // Return a profile with the updated fields merged.
    final Map<String, dynamic> base = {
      'id': 'user-uuid-001',
      'phone': '+919999999999',
      'full_name': 'Mock User',
      'role': 'GUEST',
      'is_employee': false,
    };
    base.addAll(fields);
    return ProfileModel.fromJson(base);
  }

  // ── EP-09 ─────────────────────────────────────────────────────────

  @override
  Future<OtpReferenceResponse> requestPasswordReset(PasswordResetRequest request) async {
    await _delay();
    // Always returns success (anti-enumeration).
    return OtpReferenceResponse(
      otpReference: 'mock-reset-ref-${DateTime.now().millisecondsSinceEpoch}',
      expiresIn: 300,
    );
  }

  // ── EP-10 ─────────────────────────────────────────────────────────

  @override
  Future<void> verifyPasswordReset(PasswordResetVerifyRequest request) async {
    await _delay();
    // Mock: success — all sessions revoked.
  }

  // ── EP-11 ─────────────────────────────────────────────────────────

  @override
  Future<ContactChangeResponse> requestContactChange(ContactChangeRequest request) async {
    await _delay();
    return ContactChangeResponse(requestId: 'mock-change-req-${DateTime.now().millisecondsSinceEpoch}');
  }

  // ── EP-12 ─────────────────────────────────────────────────────────

  @override
  Future<AuthTokenResponse> verifyContactChange(ContactVerifyRequest request) async {
    await _delay();
    return AuthTokenResponse(
      accessToken:  'mock-access-new-contact-${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'mock-refresh-new-contact-${DateTime.now().millisecondsSinceEpoch}',
      user: {
        'id': 'user-uuid-001',
        'phone': '+919999999999',
        'full_name': 'Mock User',
        'role': 'GUEST',
        'is_employee': false,
      },
    );
  }

  // ── EP-13 ─────────────────────────────────────────────────────────

  @override
  Future<void> deleteAccount(String otp, String? reason) async {
    await _delay();
    // Mock: account deleted.
  }

  // ── EP-14 ─────────────────────────────────────────────────────────

  @override
  Future<AuthTokenResponse> upgradeToEmployee(UpgradeToEmployeeRequest request) async {
    await _delay();
    return AuthTokenResponse(
      accessToken:  'mock-access-employee-${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'mock-refresh-employee-${DateTime.now().millisecondsSinceEpoch}',
      user: {
        'id': 'user-uuid-001',
        'phone': '+919999999999',
        'email': request.workEmail,
        'full_name': 'Mock User',
        'role': 'USER',
        'tenant_id': 'tenant-uuid-001',
        'is_employee': true,
        'employee_id': request.employeeId,
        'is_verified': true,
      },
    );
  }

  // ── EP-35 ─────────────────────────────────────────────────────────

  @override
  Future<List<TenantModel>> getTenants() async {
    await _delay();
    return [
      TenantModel(id: 'uuid-1', name: 'Infosys', city: 'Bangalore', location: 'Electronic City', logoUrl: null, hasActiveCafeteria: true),
      TenantModel(id: 'uuid-2', name: 'Capgemini', city: 'Bangalore', location: 'Manyata Tech Park', logoUrl: null, hasActiveCafeteria: true),
      TenantModel(id: 'uuid-3', name: 'Wipro', city: 'Bangalore', location: 'Sarjapur Road', logoUrl: null, hasActiveCafeteria: true),
      TenantModel(id: 'uuid-4', name: 'TCS', city: 'Mumbai', location: 'Andheri East', logoUrl: null, hasActiveCafeteria: true),
      TenantModel(id: 'uuid-5', name: 'HCL', city: 'Noida', location: 'Sector 126', logoUrl: null, hasActiveCafeteria: false),
    ];
  }

  // ── EP-37 ─────────────────────────────────────────────────────────

  @override
  Future<TenantValidateResponse> validateTenant(TenantValidateRequest request) async {
    await _delay();
    // Mock: all tenants accept registrations except HCL (uuid-5).
    if (request.tenantId == 'uuid-5') {
      return TenantValidateResponse(isAccepting: false, message: 'This location is not currently accepting registrations.');
    }
    return TenantValidateResponse(isAccepting: true, message: null);
  }
}
