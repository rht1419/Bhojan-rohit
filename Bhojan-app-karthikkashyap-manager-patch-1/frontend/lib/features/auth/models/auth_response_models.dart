/// Request / response DTOs that map directly to API contract shapes.
/// These are used by both MockAuthService and RealAuthService.
import '../../../core/utils/phone_utils.dart';

// ── Registration (EP-01) ────────────────────────────────────────────

class RegisterRequest {
  final String userType; // 'GUEST' | 'EMPLOYEE'
  final String fullName;
  final String phone;
  final String password;
  final String? email;       // required for EMPLOYEE
  final String? employeeId;  // required for EMPLOYEE

  RegisterRequest({
    required this.userType,
    required this.fullName,
    required this.phone,
    required this.password,
    this.email,
    this.employeeId,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'user_type': userType,
      'full_name': fullName,
      'phone': PhoneUtils.normalizeIndianPhone(phone),
      'password': password,
    };
    if (email != null) map['email'] = email;
    if (employeeId != null) map['employee_id'] = employeeId;
    return map;
  }
}

class OtpReferenceResponse {
  final String? otpReference;
  final int expiresIn; // seconds

  OtpReferenceResponse({this.otpReference, required this.expiresIn});

  factory OtpReferenceResponse.fromJson(Map<String, dynamic>? json) {
    if (json == null) return OtpReferenceResponse(otpReference: '', expiresIn: 300);
    return OtpReferenceResponse(
      otpReference: json['otp_reference']?.toString() ?? '',
      expiresIn:    json['expires_in'] as int? ?? 300,
    );
  }
}

// ── OTP Verify (EP-02) ─────────────────────────────────────────────

class OtpVerifyRequest {
  final String phone;
  final String otp;
  final String? otpReference;

  OtpVerifyRequest({required this.phone, required this.otp, this.otpReference});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'phone': PhoneUtils.normalizeIndianPhone(phone), 'otp': otp};
    if (otpReference != null) map['otp_reference'] = otpReference;
    return map;
  }
}

// ── Password Login (EP-03) ──────────────────────────────────────────

class PasswordLoginRequest {
  final String phone;
  final String password;

  PasswordLoginRequest({required this.phone, required this.password});

  Map<String, dynamic> toJson() => {'phone': PhoneUtils.normalizeIndianPhone(phone), 'password': password};
}

// ── Auth Token Response (EP-02, EP-03, EP-04) ───────────────────────

class AuthTokenResponse {
  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> user;

  AuthTokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthTokenResponse.fromJson(Map<String, dynamic> json) {
    return AuthTokenResponse(
      accessToken:  json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      user:         json['user'] as Map<String, dynamic>,
    );
  }
}

// ── Password Reset Request (EP-09) ──────────────────────────────────

class PasswordResetRequest {
  final String phone;

  PasswordResetRequest({required this.phone});

  Map<String, dynamic> toJson() => {'phone': PhoneUtils.normalizeIndianPhone(phone)};
}

// ── Password Reset Verify (EP-10) ───────────────────────────────────

class PasswordResetVerifyRequest {
  final String phone;
  final String otp;
  final String newPassword;

  PasswordResetVerifyRequest({
    required this.phone,
    required this.otp,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
    'phone': PhoneUtils.normalizeIndianPhone(phone),
    'otp': otp,
    'new_password': newPassword,
  };
}

// ── Contact Change (EP-11) ──────────────────────────────────────────

class ContactChangeRequest {
  final String type; // 'phone' | 'email'
  final String newValue;

  ContactChangeRequest({required this.type, required this.newValue});

  Map<String, dynamic> toJson() => {'type': type.toUpperCase(), 'new_value': newValue};
}

class ContactChangeResponse {
  final String requestId;

  ContactChangeResponse({required this.requestId});

  factory ContactChangeResponse.fromJson(Map<String, dynamic> json) {
    return ContactChangeResponse(requestId: json['request_id'] as String);
  }
}

// ── Contact Verify (EP-12) ──────────────────────────────────────────

class ContactVerifyRequest {
  final String requestId;
  final String otpOld;
  final String otpNew;

  ContactVerifyRequest({required this.requestId, required this.otpOld, required this.otpNew});

  Map<String, dynamic> toJson() => {
    'request_id': requestId,
    'otp_old': otpOld,
    'otp_new': otpNew,
  };
}

// ── Upgrade to Employee (EP-14) ─────────────────────────────────────

class UpgradeToEmployeeRequest {
  final String employeeId;
  final String workEmail;

  UpgradeToEmployeeRequest({required this.employeeId, required this.workEmail});

  Map<String, dynamic> toJson() => {'employee_id': employeeId, 'work_email': workEmail};
}

// ── Tenant Validate (EP-37) ─────────────────────────────────────────

class TenantValidateRequest {
  final String tenantId;

  TenantValidateRequest({required this.tenantId});

  Map<String, dynamic> toJson() => {'tenant_id': tenantId};
}

class TenantValidateResponse {
  final bool isAccepting;
  final String? message;

  TenantValidateResponse({required this.isAccepting, this.message});

  factory TenantValidateResponse.fromJson(Map<String, dynamic> json) {
    final msg = json['message'];
    return TenantValidateResponse(
      isAccepting: json['is_open'] as bool? ?? false,
      message:     msg is List ? msg.join('\n') : msg?.toString(),
    );
  }
}
