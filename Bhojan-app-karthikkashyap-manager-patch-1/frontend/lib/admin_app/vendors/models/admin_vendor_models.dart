class AdminVendor {
  final String id;
  final String name;
  final String? category;
  final String? contactName;
  final String phone;
  final String email;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? gstin;
  final String? tenantId;
  final bool isActive;
  final bool isVerified;
  final bool isSuspended;
  final String status; // 'active' | 'pending' | 'suspended'

  AdminVendor({
    required this.id,
    required this.name,
    this.category,
    this.contactName,
    required this.phone,
    required this.email,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.gstin,
    this.tenantId,
    required this.isActive,
    required this.isVerified,
    required this.isSuspended,
    required this.status,
  });

  factory AdminVendor.fromJson(Map<String, dynamic> json) {
    final vp = json['vendor_profile'] as Map<String, dynamic>?;
    return AdminVendor(
      id:           json['id'] as String,
      name:         (vp?['business_name'] ?? json['business_name'] ?? json['name'] ?? '') as String,
      category:     vp?['category'] as String?,
      contactName:  json['full_name'] as String?,
      phone:        json['phone'] as String? ?? '',
      email:        json['email'] as String? ?? '',
      address:      vp?['city'] as String?,
      city:         vp?['city'] as String?,
      state:        vp?['state'] as String?,
      pincode:      json['pincode'] as String?,
      gstin:        json['gstin'] as String?,
      tenantId:     json['tenant_id'] as String?,
      isActive:     json['is_active'] as bool? ?? false,
      isVerified:   json['is_verified'] as bool? ?? false,
      isSuspended:  json['is_suspended'] as bool? ?? false,
      status:       json['status'] as String? ?? 'pending',
    );
  }
}

class AdminCreateVendorRequest {
  final String fullName;
  final String phone;
  final String email;
  final String businessName;
  final String businessAddress;
  final String city;
  final String state;
  final String pincode;
  final String? gstin;
  final String tenantId;

  AdminCreateVendorRequest({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.businessName,
    required this.businessAddress,
    required this.city,
    required this.state,
    required this.pincode,
    this.gstin,
    required this.tenantId,
  });

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'phone': phone,
    'email': email,
    'business_name': businessName,
    'business_address': businessAddress,
    'city': city,
    'state': state,
    'pincode': pincode,
    if (gstin != null && gstin!.isNotEmpty) 'gstin': gstin,
    'tenant_id': tenantId,
  };
}

class CompleteVendorRequest {
  final String businessAddress;
  final String city;
  final String state;
  final String pincode;
  final String tenantId;
  final String? gstin;

  CompleteVendorRequest({
    required this.businessAddress,
    required this.city,
    required this.state,
    required this.pincode,
    required this.tenantId,
    this.gstin,
  });

  Map<String, dynamic> toJson() => {
    'business_address': businessAddress,
    'city': city,
    'state': state,
    'pincode': pincode,
    'tenant_id': tenantId,
    if (gstin != null && gstin!.isNotEmpty) 'gstin': gstin,
  };
}
