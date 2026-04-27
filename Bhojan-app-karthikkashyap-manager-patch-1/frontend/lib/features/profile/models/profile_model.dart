/// Full profile model for EP-06 GET /auth/me and EP-07 PUT /auth/profile.
class ProfileModel {
  final String id;
  final String phone;
  final String? email;
  final String fullName;
  final String role;
  final String? tenantId;
  final bool isEmployee;
  final String? employeeId;
  final String? avatarUrl;
  final String? department;
  final String? floor;
  final String? building;
  final String? dietaryPreference;
  final String? language;
  final bool? notificationsEnabled;
  final String? lastLoginAt;

  ProfileModel({
    required this.id,
    required this.phone,
    this.email,
    required this.fullName,
    required this.role,
    this.tenantId,
    required this.isEmployee,
    this.employeeId,
    this.avatarUrl,
    this.department,
    this.floor,
    this.building,
    this.dietaryPreference,
    this.language,
    this.notificationsEnabled,
    this.lastLoginAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    // Determine if we have the full nested structure (from EP-06) or just the profile part
    final bool isFull = json.containsKey('user') && json.containsKey('profile');
    
    final Map<String, dynamic> userPart = isFull ? (json['user'] as Map<String, dynamic>) : {};
    final Map<String, dynamic> profilePart = isFull ? (json['profile'] as Map<String, dynamic>) : json;
    final Map<String, dynamic>? prefs = profilePart['preferences'] as Map<String, dynamic>?;

    return ProfileModel(
      id:                   (userPart['id'] ?? profilePart['id'] ?? '') as String,
      phone:                (userPart['phone'] ?? profilePart['phone'] ?? '') as String,
      email:                (userPart['email'] ?? profilePart['email']) as String?,
      fullName:             (userPart['full_name'] ?? profilePart['full_name'] ?? '') as String,
      role:                 (userPart['role'] ?? profilePart['role'] ?? 'USER') as String,
      tenantId:             (userPart['tenant_id'] ?? profilePart['tenant_id']) as String?,
      isEmployee:           (userPart['is_employee'] ?? profilePart['is_employee']) as bool? ?? false,
      employeeId:           (userPart['employee_id'] ?? profilePart['employee_id']) as String?,
      avatarUrl:            profilePart['avatar_url'] as String?,
      department:           profilePart['department'] as String?,
      floor:                profilePart['floor'] as String?,
      building:             profilePart['building'] as String?,
      dietaryPreference:    prefs?['dietary'] as String?,
      language:             prefs?['language'] as String?,
      notificationsEnabled: (prefs?['notifications'] as Map<String, dynamic>?)?['order'] as bool?,
      lastLoginAt:          (userPart['last_login_at'] ?? profilePart['last_login_at']) as String?,
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
      'avatar_url': avatarUrl,
      'department': department,
      'floor': floor,
      'building': building,
      'dietary_preference': dietaryPreference,
      'language': language,
      'notifications_enabled': notificationsEnabled,
      'last_login_at': lastLoginAt,
    };
  }
}
