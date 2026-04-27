import '../models/vendor_auth_models.dart';
import '../models/vendor_profile_model.dart';

/// Abstract vendor auth service interface.
/// Both [MockVendorAuthService] and [RealVendorAuthService] implement this.
abstract class VendorAuthServiceInterface {

  // ── Registration (New Flow) ──────────────────────────────────────
  Future<void> register(VendorRegisterRequest request);
  Future<void> requestOtp(String phone);
  Future<VendorLoginResponse> verifyOtp(VerifyOtpRequest request);

  // ── EP-17 Vendor Account Activation ────────────────────────────────
  Future<void> activateAccount(VendorActivateRequest request);

  // ── EP-18 Vendor Login ─────────────────────────────────────────────
  Future<VendorLoginResponse> login(VendorLoginRequest request);

  // ── EP-19 Vendor Profile Update ────────────────────────────────────
  Future<VendorProfileModel> updateProfile(Map<String, dynamic> fields);

  // ── Get Vendor Profile (uses EP-06 /auth/me internally) ────────────
  Future<VendorProfileModel> getProfile();

  // ── EP-04 Token Refresh (shared) ───────────────────────────────────
  Future<VendorLoginResponse> refreshToken(String refreshToken);

  // ── EP-05 Logout (shared) ──────────────────────────────────────────
  Future<void> logout(String refreshToken);
}
