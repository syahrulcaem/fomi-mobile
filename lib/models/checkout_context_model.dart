import 'checkout_address_model.dart';

class CheckoutCustomerModel {
  CheckoutCustomerModel({
    this.name,
    this.email,
    this.phone,
  });

  final String? name;
  final String? email;
  final String? phone;

  factory CheckoutCustomerModel.fromJson(Map<String, dynamic> json) {
    return CheckoutCustomerModel(
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
    );
  }
}

class CheckoutMidtransModel {
  CheckoutMidtransModel({
    this.clientKey,
    this.checkStatusUrl,
    this.isProduction = false,
  });

  final String? clientKey;
  final String? checkStatusUrl;
  final bool isProduction;

  factory CheckoutMidtransModel.fromJson(Map<String, dynamic> json) {
    return CheckoutMidtransModel(
      clientKey: json['client_key']?.toString(),
      checkStatusUrl: json['check_status_url']?.toString(),
      isProduction: json['is_production'] == true,
    );
  }
}

class CheckoutRenewalTargetModel {
  CheckoutRenewalTargetModel({
    required this.id,
    required this.name,
    this.expiresAt,
  });

  final String id;
  final String name;
  final String? expiresAt;

  factory CheckoutRenewalTargetModel.fromJson(Map<String, dynamic> json) {
    final rawName = json['name']?.toString() ??
        json['asset_name']?.toString() ??
        json['label']?.toString() ??
        json['code']?.toString() ??
        'Asset';

    return CheckoutRenewalTargetModel(
      id: json['id']?.toString() ?? json['asset_id']?.toString() ?? '',
      name: rawName,
      expiresAt: json['active_subscription'] is Map<String, dynamic>
          ? (json['active_subscription'] as Map<String, dynamic>)['expires_at']
              ?.toString()
          : json['expires_at']?.toString(),
    );
  }
}

class CheckoutQrAssetModel {
  CheckoutQrAssetModel({
    required this.id,
    required this.name,
    this.expiresAt,
  });

  final String id;
  final String name;
  final String? expiresAt;

  factory CheckoutQrAssetModel.fromJson(Map<String, dynamic> json) {
    return CheckoutQrAssetModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Asset',
      expiresAt: json['active_subscription'] is Map<String, dynamic>
          ? (json['active_subscription'] as Map<String, dynamic>)['expires_at']
              ?.toString()
          : json['expires_at']?.toString(),
    );
  }
}

class CheckoutContextModel {
  CheckoutContextModel({
    this.customer,
    this.midtrans,
    required this.renewalTargets,
    required this.activeQrAssets,
    required this.savedAddresses,
    required this.availableShippingCouriers,
    required this.raw,
  });

  final CheckoutCustomerModel? customer;
  final CheckoutMidtransModel? midtrans;
  final List<CheckoutRenewalTargetModel> renewalTargets;
  final List<CheckoutQrAssetModel> activeQrAssets;
  final List<CheckoutAddressModel> savedAddresses;
  final List<String> availableShippingCouriers;
  final Map<String, dynamic> raw;

  factory CheckoutContextModel.fromJson(Map<String, dynamic> json) {
    final root = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return CheckoutContextModel(
      customer: root['customer'] is Map<String, dynamic>
          ? CheckoutCustomerModel.fromJson(
              root['customer'] as Map<String, dynamic>,
            )
          : null,
      midtrans: root['midtrans'] is Map<String, dynamic>
          ? CheckoutMidtransModel.fromJson(
              root['midtrans'] as Map<String, dynamic>,
            )
          : null,
      renewalTargets: _toRenewalTargets(root['renewal_targets']),
      activeQrAssets: _toQrAssets(root['active_qr_assets']),
      savedAddresses: _toAddresses(root['saved_addresses']),
      availableShippingCouriers:
          _toStrings(root['available_shipping_couriers']),
      raw: root,
    );
  }

  static List<CheckoutRenewalTargetModel> _toRenewalTargets(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map<String, dynamic>>()
        .map(CheckoutRenewalTargetModel.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  static List<CheckoutQrAssetModel> _toQrAssets(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map<String, dynamic>>()
        .map(CheckoutQrAssetModel.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  static List<CheckoutAddressModel> _toAddresses(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map<String, dynamic>>()
        .map(CheckoutAddressModel.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  static List<String> _toStrings(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw.map((item) => item.toString()).toList();
  }
}
