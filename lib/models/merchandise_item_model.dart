class MerchandiseItemModel {
  MerchandiseItemModel({
    required this.id,
    required this.barcode,
    required this.name,
    required this.isActive,
    this.activatedAt,
  });

  final String id;
  final String barcode;
  final String name;
  final bool isActive;
  final String? activatedAt;

  factory MerchandiseItemModel.fromJson(Map<String, dynamic> json) {
    return MerchandiseItemModel(
      id: json['id']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '-',
      name: json['name']?.toString() ?? '-',
      isActive:
          json['is_active'] == true || json['status']?.toString() == 'active',
      activatedAt: json['activated_at']?.toString(),
    );
  }
}
