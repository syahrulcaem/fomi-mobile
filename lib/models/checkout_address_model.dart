class CheckoutAddressModel {
  CheckoutAddressModel({
    required this.id,
    required this.label,
    required this.shippingAddress,
    required this.shippingPostalCode,
    required this.provinceName,
    required this.regencyName,
    this.provinceId,
    this.regencyId,
    this.districtId,
    this.districtName,
  });

  final String id;
  final String label;
  final String shippingAddress;
  final String shippingPostalCode;
  final String provinceName;
  final String regencyName;
  final int? provinceId;
  final int? regencyId;
  final int? districtId;
  final String? districtName;

  factory CheckoutAddressModel.fromJson(Map<String, dynamic> json) {
    return CheckoutAddressModel(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Alamat',
      shippingAddress: json['shipping_address']?.toString() ?? '',
      shippingPostalCode: json['shipping_postal_code']?.toString() ?? '',
      provinceName: json['province_name']?.toString() ??
          json['shipping_province']?.toString() ??
          '',
      regencyName: json['regency_name']?.toString() ??
          json['shipping_city']?.toString() ??
          '',
      provinceId: (json['province_id'] as num?)?.toInt(),
      regencyId: (json['regency_id'] as num?)?.toInt(),
      districtId: (json['district_id'] as num?)?.toInt(),
      districtName: json['district_name']?.toString(),
    );
  }

  String get fullDisplay =>
      '$shippingAddress, $regencyName, $provinceName $shippingPostalCode';
}

class CheckoutAddressCreateRequest {
  CheckoutAddressCreateRequest({
    required this.label,
    required this.shippingAddress,
    required this.shippingPostalCode,
    required this.provinceId,
    required this.regencyId,
    required this.districtId,
    this.districtName,
  });

  final String label;
  final String shippingAddress;
  final String shippingPostalCode;
  final int provinceId;
  final int regencyId;
  final int districtId;
  final String? districtName;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'label': label,
      'shipping_address': shippingAddress,
      'shipping_postal_code': shippingPostalCode,
      'province_id': provinceId,
      'regency_id': regencyId,
      'district_id': districtId,
      if (districtName != null && districtName!.trim().isNotEmpty)
        'district_name': districtName!.trim(),
    };
  }
}
