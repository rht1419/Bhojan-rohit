import '../models/auth_response_models.dart';
import '../models/tenant_model.dart';
import '../models/user_model.dart';
import '../../profile/models/profile_model.dart';

/// Abstract auth service interface.
/// Both [MockAuthService] and [RealAuthService] implement this.
abstract class AuthServiceInterface {

  // ── EP-01 Registration ────────────────────────────────────────────
  Future<OtpReferenceResponse> register(RegisterRequest request);

  // ── EP-02 OTP Verify ──────────────────────────────────────────────
  Future<AuthTokenResponse> verifyOtp(OtpVerifyRequest request);

  // ── EP-03 Password Login ──────────────────────────────────────────
  Future<AuthTokenResponse> loginWithPassword(PasswordLoginRequest request);

  // ── EP-03b Login OTP Request ──────────────────────────────────────
  Future<OtpReferenceResponse> requestLoginOtp(String phone);

  // ── EP-04 Token Refresh ───────────────────────────────────────────
  Future<AuthTokenResponse> refreshToken(String refreshToken);

  // ── EP-05 Logout ──────────────────────────────────────────────────
  Future<void> logout(String refreshToken);

  // ── EP-06 Get Profile ─────────────────────────────────────────────
  Future<ProfileModel> getProfile();

  // ── EP-07 Update Profile ──────────────────────────────────────────
  Future<ProfileModel> updateProfile(Map<String, dynamic> fields);

  // ── EP-09 Password Reset Request ──────────────────────────────────
  Future<OtpReferenceResponse> requestPasswordReset(PasswordResetRequest request);

  // ── EP-10 Password Reset Verify ───────────────────────────────────
  Future<void> verifyPasswordReset(PasswordResetVerifyRequest request);

  // ── EP-11 Contact Change ──────────────────────────────────────────
  Future<ContactChangeResponse> requestContactChange(ContactChangeRequest request);

  // ── EP-12 Contact Verify ──────────────────────────────────────────
  Future<AuthTokenResponse> verifyContactChange(ContactVerifyRequest request);

  // ── EP-13 Delete Account ──────────────────────────────────────────
  Future<void> deleteAccount(String otp, String? reason);

  // ── EP-14 Upgrade to Employee ─────────────────────────────────────
  Future<AuthTokenResponse> upgradeToEmployee(UpgradeToEmployeeRequest request);

  // ── EP-35 Get Tenants ─────────────────────────────────────────────
  Future<List<TenantModel>> getTenants();

  // ── EP-37 Validate Tenant ─────────────────────────────────────────
  Future<TenantValidateResponse> validateTenant(TenantValidateRequest request);
}
