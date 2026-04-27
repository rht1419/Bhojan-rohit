class AdminVendor {
  final String id;
  final String name;
  final String contactName;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String? gstin;
  final String tenantId;
  final bool isActive;
  final bool isSuspended;

  AdminVendor({
    required this.id,
    required this.name,
    required this.contactName,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    this.gstin,
    required this.tenantId,
    required this.isActive,
    required this.isSuspended,
  });

  factory AdminVendor.fromJson(Map<String, dynamic> json) {
    return AdminVendor(
      id: json['id'],
      name: json['business_name'] ?? json['name'] ?? '',
      contactName: json['contact_person_name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      gstin: json['gstin'],
      tenantId: json['tenant_id'] ?? '',
      isActive: json['is_active'] ?? false,
      isSuspended: json['is_suspended'] ?? false,
    );
  }
}

class AdminCreateVendorRequest {
  final String contactPersonName;
  final String phone;
  final String email;
  final String businessName;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String? gstin;
  final String tenantId;

  AdminCreateVendorRequest({
    required this.contactPersonName,
    required this.phone,
    required this.email,
    required this.businessName,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    this.gstin,
    required this.tenantId,
  });

  Map<String, dynamic> toJson() => {
    'contact_person_name': contactPersonName,
    'phone': phone,
    'email': email,
    'business_name': businessName,
    'address': address,
    'city': city,
    'state': state,
    'pincode': pincode,
    if (gstin != null && gstin!.isNotEmpty) 'gstin': gstin,
    'tenant_id': tenantId,
  };
}
