/// Vendor profile model matching EP-19 contract shape.
class VendorProfileModel {
  final String id;
  final String phone;
  final String? email;
  final String? fullName;
  final String role;
  final String? tenantId;
  final bool isVerified;
  final String? lastLoginAt;

  // Vendor-specific fields (from vendor_profiles table)
  final String? businessName;
  final String? businessAddress;
  final String? city;
  final String? logoUrl;
  final String? fssaiNumber;
  final String? operatingHours;

  // Bank details (read-only in Phase 1)
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;

  VendorProfileModel({
    required this.id,
    required this.phone,
    this.email,
    this.fullName,
    required this.role,
    this.tenantId,
    this.isVerified = false,
    this.lastLoginAt,
    this.businessName,
    this.businessAddress,
    this.city,
    this.logoUrl,
    this.fssaiNumber,
    this.operatingHours,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
  });

  factory VendorProfileModel.fromJson(Map<String, dynamic> json) {
    return VendorProfileModel(
      id: json['id'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      fullName: json['full_name'],
      role: json['role'] ?? 'VENDOR',
      tenantId: json['tenant_id'],
      isVerified: json['is_verified'] ?? false,
      lastLoginAt: json['last_login_at'],
      businessName: json['business_name'],
      businessAddress: json['business_address'],
      city: json['city'],
      logoUrl: json['logo_url'],
      fssaiNumber: json['fssai_number'],
      operatingHours: json['operating_hours'],
      bankName: json['bank_name'],
      accountNumber: json['account_number'],
      ifscCode: json['ifsc_code'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'email': email,
    'full_name': fullName,
    'role': role,
    'tenant_id': tenantId,
    'is_verified': isVerified,
    'last_login_at': lastLoginAt,
    'business_name': businessName,
    'business_address': businessAddress,
    'city': city,
    'logo_url': logoUrl,
    'fssai_number': fssaiNumber,
    'operating_hours': operatingHours,
    'bank_name': bankName,
    'account_number': accountNumber,
    'ifsc_code': ifscCode,
  };
}
