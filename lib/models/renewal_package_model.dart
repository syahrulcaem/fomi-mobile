class RenewalPackageModel {
  RenewalPackageModel({
    required this.id,
    required this.name,
    required this.price,
    required this.barcodeQuota,
    this.description,
  });

  final String id;
  final String name;
  final int price;
  final int barcodeQuota;
  final String? description;

  factory RenewalPackageModel.fromJson(Map<String, dynamic> json) {
    return RenewalPackageModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '-',
      price: (json['price'] as num?)?.toInt() ?? 0,
      barcodeQuota: (json['barcode_quota'] as num?)?.toInt() ?? 0,
      description: json['description']?.toString(),
    );
  }
}
