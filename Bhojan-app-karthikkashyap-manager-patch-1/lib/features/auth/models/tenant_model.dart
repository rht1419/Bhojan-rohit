/// Matches EP-35 GET /tenants response shape `data.tenants[]`.
class TenantModel {
  final String id;
  final String name;
  final String city;
  final String location;
  final String? logoUrl;
  final bool hasActiveCafeteria;

  TenantModel({
    required this.id,
    required this.name,
    this.city = '',
    this.location = '',
    this.logoUrl,
    required this.hasActiveCafeteria,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id:                  json['id'] as String,
      name:                json['name'] as String,
      city:                json['city'] as String? ?? '',
      location:            json['location'] as String? ?? '',
      logoUrl:             json['logo_url'] as String?,
      hasActiveCafeteria:  json['has_active_cafeteria'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'location': location,
      'logo_url': logoUrl,
      'has_active_cafeteria': hasActiveCafeteria,
    };
  }
}
