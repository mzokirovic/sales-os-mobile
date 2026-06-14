class CustomerModel {
  const CustomerModel({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.lat,
    this.lng,
  });

  final String id;
  final String name;
  final String? phone;
  final String? address;
  final double? lat;
  final double? lng;

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }
}
