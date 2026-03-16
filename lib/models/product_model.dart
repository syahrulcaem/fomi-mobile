class ProductModel {
  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.type,
  });

  final String id;
  final String name;
  final int price;
  final String? description;
  final String? type;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '-',
      price: (json['price'] as num?)?.toInt() ?? 0,
      description: json['description']?.toString(),
      type: json['type']?.toString(),
    );
  }
}
