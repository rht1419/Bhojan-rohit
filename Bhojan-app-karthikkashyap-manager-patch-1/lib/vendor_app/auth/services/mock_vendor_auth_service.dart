import '../models/vendor_auth_models.dart';
import '../models/vendor_profile_model.dart';
import 'vendor_auth_service.dart';

/// Mock implementation of [VendorAuthServiceInterface].
/// Returns hardcoded contract-matching responses with simulated network delay.
class MockVendorAuthService implements VendorAuthServiceInterface {

  /// Simulated network delay.
  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 500));

  // Track login attempts for lockout simulation
  int _loginAttemptCount = 0;
  static const _maxAttempts = 5;

  // ── Registration & OTP (New Flow) ─────────────────────────────────

  @override
  Future<void> register(VendorRegisterRequest request) async {
    await _delay();
    // Mock success
  }

  @override
  Future<void> requestOtp(String phone) async {
    await _delay();
    // Simulate error for specific phone
    if (phone == '+910000000000') {
      throw VendorAuthException(
        code: 'ACCOUNT_NOT_FOUND',
        message: 'No vendor account found with this number.',
        httpStatus: 404,
      );
    }
  }

  @override
  Future<VendorLoginResponse> verifyOtp(VerifyOtpRequest request) async {
    await _delay();
    if (request.otp != '123456') {
      throw VendorAuthException(
        code: 'INVALID_OTP',
        message: 'The OTP entered is incorrect.',
        httpStatus: 400,
      );
    }
    return VendorLoginResponse(
      accessToken: 'mock-vendor-access-${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'mock-vendor-refresh-${DateTime.now().millisecondsSinceEpoch}',
      user: {
        'id': 'vendor-uuid-001',
        'phone': request.phone,
        'role': 'VENDOR',
        'tenant_id': 'tenant-uuid-001',
        'is_verified': true,
      },
    );
  }

  // ── EP-17 ─────────────────────────────────────────────────────────

  @override
  Future<void> activateAccount(VendorActivateRequest request) async {
    await _delay();

    // Simulate expired/invalid token
    if (request.activationToken == 'expired-token') {
      throw VendorAuthException(
        code: 'UNAUTHORIZED',
        message: 'Activation link has expired or is invalid.',
        httpStatus: 401,
      );
    }

    // Simulate weak password
    if (request.password.length < 8) {
      throw VendorAuthException(
        code: 'VALIDATION_ERROR',
        message: 'Password must be at least 8 characters with 1 uppercase, 1 number, and 1 special character.',
        httpStatus: 400,
      );
    }

    // Mock success — account activated.
  }

  // ── EP-18 ─────────────────────────────────────────────────────────

  @override
  Future<VendorLoginResponse> login(VendorLoginRequest request) async {
    await _delay();

    // Simulate EMAIL_NOT_VERIFIED (vendor hasn't activated yet)
    if (request.phone == '+910000000000') {
      throw VendorAuthException(
        code: 'EMAIL_NOT_VERIFIED',
        message: 'Please activate your account first. Check your email.',
        httpStatus: 403,
      );
    }

    // Simulate ACCOUNT_SUSPENDED
    if (request.phone == '+911111111111') {
      throw VendorAuthException(
        code: 'ACCOUNT_SUSPENDED',
        message: 'Your account has been suspended. Contact support.',
        httpStatus: 403,
      );
    }

    // Simulate wrong password with attempt tracking
    if (request.password == 'wrong') {
      _loginAttemptCount++;
      if (_loginAttemptCount >= _maxAttempts) {
        throw VendorAuthException(
          code: 'ACCOUNT_LOCKED',
          message: 'Account locked — too many failed attempts. Try again in 15 minutes.',
          httpStatus: 429,
        );
      }
      final remaining = _maxAttempts - _loginAttemptCount;
      throw VendorAuthException(
        code: 'AUTH_LOGIN_FAILED',
        message: remaining <= 2
            ? 'Incorrect password. $remaining attempts remaining.'
            : 'Incorrect password. Please try again.',
        httpStatus: 401,
      );
    }

    // Reset attempt counter on success
    _loginAttemptCount = 0;

    return VendorLoginResponse(
      accessToken: 'mock-vendor-access-${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'mock-vendor-refresh-${DateTime.now().millisecondsSinceEpoch}',
      user: {
        'id': 'vendor-uuid-001',
        'phone': request.phone,
        'role': 'VENDOR',
        'tenant_id': 'tenant-uuid-001',
        'is_verified': true,
      },
    );
  }

  // ── Get Profile ───────────────────────────────────────────────────

  @override
  Future<VendorProfileModel> getProfile() async {
    await _delay();
    return VendorProfileModel.fromJson({
      'id': 'vendor-uuid-001',
      'phone': '+919876543210',
      'email': 'vendor@bakery.com',
      'full_name': 'Marwan Ahmed',
      'role': 'VENDOR',
      'tenant_id': 'tenant-uuid-001',
      'is_verified': true,
      'last_login_at': DateTime.now().toIso8601String(),
      'business_name': 'Bakery By Marwan\'s',
      'business_address': '42, MG Road, Electronic City',
      'city': 'Bangalore',
      'logo_url': null,
      'fssai_number': '12345678901234',
      'operating_hours': '8:00 AM - 10:00 PM',
      'bank_name': 'HDFC Bank',
      'account_number': 'XXXX XXXX 4521',
      'ifsc_code': 'HDFC0001234',
    });
  }

  // ── EP-19 ─────────────────────────────────────────────────────────

  @override
  Future<VendorProfileModel> updateProfile(Map<String, dynamic> fields) async {
    await _delay();
    final Map<String, dynamic> base = {
      'id': 'vendor-uuid-001',
      'phone': '+919876543210',
      'email': 'vendor@bakery.com',
      'full_name': 'Marwan Ahmed',
      'role': 'VENDOR',
      'tenant_id': 'tenant-uuid-001',
      'is_verified': true,
      'business_name': 'Bakery By Marwan\'s',
      'business_address': '42, MG Road, Electronic City',
      'city': 'Bangalore',
      'fssai_number': '12345678901234',
      'operating_hours': '8:00 AM - 10:00 PM',
      'bank_name': 'HDFC Bank',
      'account_number': 'XXXX XXXX 4521',
      'ifsc_code': 'HDFC0001234',
    };
    base.addAll(fields);
    return VendorProfileModel.fromJson(base);
  }

  // ── EP-04 ─────────────────────────────────────────────────────────

  @override
  Future<VendorLoginResponse> refreshToken(String refreshToken) async {
    await _delay();
    return VendorLoginResponse(
      accessToken: 'mock-vendor-access-refreshed-${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'mock-vendor-refresh-rotated-${DateTime.now().millisecondsSinceEpoch}',
      user: {
        'id': 'vendor-uuid-001',
        'phone': '+919876543210',
        'role': 'VENDOR',
        'tenant_id': 'tenant-uuid-001',
        'is_verified': true,
      },
    );
  }

  // ── EP-05 ─────────────────────────────────────────────────────────

  @override
  Future<void> logout(String refreshToken) async {
    await _delay();
    // Mock: nothing to do server-side.
  }
}

/// Custom exception for vendor auth errors (used in mock to simulate API errors).
class VendorAuthException implements Exception {
  final String code;
  final String message;
  final int httpStatus;

  VendorAuthException({
    required this.code,
    required this.message,
    required this.httpStatus,
  });

  @override
  String toString() => 'VendorAuthException($code): $message';
}
