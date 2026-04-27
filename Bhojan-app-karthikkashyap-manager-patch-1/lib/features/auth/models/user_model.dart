class UserModel {
  final String id;
  final String phone;
  final String? email;
  final String fullName;
  final String role;          // 'GUEST' | 'USER' | 'VENDOR' | 'SUPER_ADMIN' etc.
  final String? tenantId;     // null for GUEST
  final bool isEmployee;
  final String? employeeId;   // null for GUEST/VENDOR/ADMIN
  final bool? isVerified;
  final String? lastLoginAt;

  UserModel({
    required this.id,
    required this.phone,
    this.email,
    required this.fullName,
    required this.role,
    this.tenantId,
    required this.isEmployee,
    this.employeeId,
    this.isVerified,
    this.lastLoginAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:          json['id'] as String,
      phone:       json['phone'] as String,
      email:       json['email'] as String?,
      fullName:    json['full_name'] as String,
      role:        json['role'] as String,
      tenantId:    json['tenant_id'] as String?,
      isEmployee:  json['is_employee'] as bool? ?? false,
      employeeId:  json['employee_id'] as String?,
      isVerified:  json['is_verified'] as bool?,
      lastLoginAt: json['last_login_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'email': email,
      'full_name': fullName,
      'role': role,
      'tenant_id': tenantId,
      'is_employee': isEmployee,
      'employee_id': employeeId,
      'is_verified': isVerified,
      'last_login_at': lastLoginAt,
    };
  }
}
