class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    this.sku,
    required this.isActive,
  });

  final String id;
  final String name;
  final num price;
  final String unit;
  final String? sku;
  final bool isActive;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      price: json['price'] as num? ?? 0,
      unit: json['unit'] as String? ?? 'dona',
      sku: json['sku'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
