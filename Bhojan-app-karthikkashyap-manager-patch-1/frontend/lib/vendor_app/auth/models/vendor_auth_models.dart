/// DTOs for vendor-specific auth requests and responses.

/// EP-17 — Vendor Account Activation request.
class VendorActivateRequest {
  final String activationToken;
  final String password;

  VendorActivateRequest({required this.activationToken, required this.password});

  Map<String, dynamic> toJson() => {
    'activation_token': activationToken,
    'password': password,
  };
}

/// Vendor Registration request (New Flow).
class VendorRegisterRequest {
  final String businessName;
  final String email;
  final String phone;
  final String category;

  VendorRegisterRequest({
    required this.businessName,
    required this.email,
    required this.phone,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
    'business_name': businessName,
    'email': email,
    'phone': phone,
    'category': category,
  };
}

/// Verify OTP request.
class VerifyOtpRequest {
  final String phone;
  final String otp;

  VerifyOtpRequest({required this.phone, required this.otp});

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'otp': otp,
  };
}

/// EP-18 — Vendor Login request.
class VendorLoginRequest {
  final String phone;
  final String password;

  VendorLoginRequest({required this.phone, required this.password});

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'password': password,
  };
}

/// EP-18 — Vendor Login response (tokens + user object).
class VendorLoginResponse {
  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> user;

  VendorLoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory VendorLoginResponse.fromJson(Map<String, dynamic> json) {
    return VendorLoginResponse(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      user: json['user'] ?? {},
    );
  }
}
