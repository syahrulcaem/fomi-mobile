class CheckoutProvinceModel {
  CheckoutProvinceModel({
    required this.id,
    required this.name,
    this.rajaongkirId,
  });

  final int id;
  final String name;
  final int? rajaongkirId;

  factory CheckoutProvinceModel.fromJson(Map<String, dynamic> json) {
    return CheckoutProvinceModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      rajaongkirId: (json['rajaongkir_id'] as num?)?.toInt(),
    );
  }
}

class CheckoutCityModel {
  CheckoutCityModel({
    required this.id,
    required this.provinceId,
    required this.name,
    this.type,
    this.rajaongkirId,
  });

  final int id;
  final int provinceId;
  final String name;
  final String? type;
  final int? rajaongkirId;

  factory CheckoutCityModel.fromJson(Map<String, dynamic> json) {
    return CheckoutCityModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      provinceId: (json['province_id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString(),
      rajaongkirId: (json['rajaongkir_id'] as num?)?.toInt(),
    );
  }
}

class CheckoutDistrictModel {
  CheckoutDistrictModel({
    required this.id,
    required this.name,
    this.type,
  });

  final int id;
  final String name;
  final String? type;

  factory CheckoutDistrictModel.fromJson(Map<String, dynamic> json) {
    return CheckoutDistrictModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString(),
    );
  }
}
