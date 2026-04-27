class AdminAuthModels {
  // Empty constructor for namespace
  AdminAuthModels._();
}

class AdminLoginRequest {
  final String emailOrPhone;
  final String? password;
  final String? otp;

  AdminLoginRequest({required this.emailOrPhone, this.password, this.otp});

  Map<String, dynamic> toJson() => {
    'identifier': emailOrPhone,
    if (password != null) 'password': password,
    if (otp != null) 'otp': otp,
  };
}

class AdminSsoRequest {
  final String provider; // 'google' | 'microsoft'
  final String idToken;

  AdminSsoRequest({required this.provider, required this.idToken});

  Map<String, dynamic> toJson() => {
    'provider': provider,
    'id_token': idToken,
  };
}

class AdminLoginResponse {
  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> user;

  AdminLoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AdminLoginResponse.fromJson(Map<String, dynamic> json) {
    return AdminLoginResponse(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      user: json['user'],
    );
  }
}

class AdminProfile {
  final String id;
  final String name;
  final String role; // 'SUPER_ADMIN', 'TENANT_ADMIN', 'SUPPORT_ADMIN'
  final String? tenantId;
  final List<String> permissions;

  AdminProfile({
    required this.id,
    required this.name,
    required this.role,
    this.tenantId,
    required this.permissions,
  });

  factory AdminProfile.fromJson(Map<String, dynamic> json) {
    return AdminProfile(
      id: json['id'],
      name: json['name'] ?? 'Admin User',
      role: json['role'] ?? 'SUPPORT_ADMIN',
      tenantId: json['tenant_id'],
      permissions: List<String>.from(json['permissions'] ?? []),
    );
  }
}

class AdminAuthException implements Exception {
  final String code;
  final String message;
  final int? httpStatus;

  AdminAuthException({required this.code, required this.message, this.httpStatus});

  @override
  String toString() => 'AdminAuthException: $message ($code)';
}
