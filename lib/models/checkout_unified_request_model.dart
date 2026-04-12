import 'package:dio/dio.dart';

class CheckoutItemPayload {
  CheckoutItemPayload({
    required this.productId,
    required this.quantity,
    this.variantId,
  });

  final String productId;
  final int quantity;
  final String? variantId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'product_id': productId,
      'quantity': quantity,
      if (variantId != null && variantId!.trim().isNotEmpty)
        'variant_id': variantId!.trim(),
    };
  }
}

class CheckoutUnifiedRequest {
  CheckoutUnifiedRequest({
    required this.items,
    this.paymentMethod = 'midtrans',
    this.renewalAssetId,
    this.selectedAssetId,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.shippingAddress,
    this.shippingCity,
    this.shippingProvince,
    this.shippingPostalCode,
    this.regencyId,
    this.districtId,
    this.shippingCost,
    this.shippingCourier,
    this.shippingService,
    this.paymentBankName,
    this.paymentSenderName,
    this.paymentProofBytes,
    this.paymentProofFileName,
  });

  final List<CheckoutItemPayload> items;
  final String paymentMethod;
  final String? renewalAssetId;
  final String? selectedAssetId;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? shippingAddress;
  final String? shippingCity;
  final String? shippingProvince;
  final String? shippingPostalCode;
  final int? regencyId;
  final int? districtId;
  final int? shippingCost;
  final String? shippingCourier;
  final String? shippingService;
  final String? paymentBankName;
  final String? paymentSenderName;
  final List<int>? paymentProofBytes;
  final String? paymentProofFileName;

  bool get isBankTransfer => paymentMethod == 'bank_transfer';

  Map<String, dynamic> toJson() {
    return _withoutNulls(<String, dynamic>{
      'items': items.map((item) => item.toJson()).toList(),
      'payment_method': paymentMethod,
      'renewal_asset_id': _trimOrNull(renewalAssetId),
      'selected_asset_id': _trimOrNull(selectedAssetId),
      'customer_name': _trimOrNull(customerName),
      'customer_email': _trimOrNull(customerEmail),
      'customer_phone': _trimOrNull(customerPhone),
      'shipping_address': _trimOrNull(shippingAddress),
      'shipping_city': _trimOrNull(shippingCity),
      'shipping_province': _trimOrNull(shippingProvince),
      'shipping_postal_code': _trimOrNull(shippingPostalCode),
      'regency_id': regencyId,
      'district_id': districtId,
      'shipping_cost': shippingCost,
      'shipping_courier': _trimOrNull(shippingCourier),
      'shipping_service': _trimOrNull(shippingService),
      'payment_bank_name': _trimOrNull(paymentBankName),
      'payment_sender_name': _trimOrNull(paymentSenderName),
    });
  }

  FormData toMultipartFormData() {
    final fields = <String, dynamic>{
      'payment_method': paymentMethod,
    };

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      fields['items[$i][product_id]'] = item.productId;
      fields['items[$i][quantity]'] = item.quantity;
      final variantId = _trimOrNull(item.variantId);
      if (variantId != null) {
        fields['items[$i][variant_id]'] = variantId;
      }
    }

    _putIfNotNull(fields, 'renewal_asset_id', _trimOrNull(renewalAssetId));
    _putIfNotNull(fields, 'selected_asset_id', _trimOrNull(selectedAssetId));
    _putIfNotNull(fields, 'customer_name', _trimOrNull(customerName));
    _putIfNotNull(fields, 'customer_email', _trimOrNull(customerEmail));
    _putIfNotNull(fields, 'customer_phone', _trimOrNull(customerPhone));
    _putIfNotNull(fields, 'shipping_address', _trimOrNull(shippingAddress));
    _putIfNotNull(fields, 'shipping_city', _trimOrNull(shippingCity));
    _putIfNotNull(fields, 'shipping_province', _trimOrNull(shippingProvince));
    _putIfNotNull(
      fields,
      'shipping_postal_code',
      _trimOrNull(shippingPostalCode),
    );
    _putIfNotNull(fields, 'regency_id', regencyId);
    _putIfNotNull(fields, 'district_id', districtId);
    _putIfNotNull(fields, 'shipping_cost', shippingCost);
    _putIfNotNull(fields, 'shipping_courier', _trimOrNull(shippingCourier));
    _putIfNotNull(fields, 'shipping_service', _trimOrNull(shippingService));
    _putIfNotNull(fields, 'payment_bank_name', _trimOrNull(paymentBankName));
    _putIfNotNull(
      fields,
      'payment_sender_name',
      _trimOrNull(paymentSenderName),
    );

    final proofBytes = paymentProofBytes;
    if (proofBytes != null && proofBytes.isNotEmpty) {
      fields['payment_proof'] = MultipartFile.fromBytes(
        proofBytes,
        filename: _trimOrNull(paymentProofFileName) ?? 'payment-proof.jpg',
      );
    }

    return FormData.fromMap(fields);
  }

  static Map<String, dynamic> _withoutNulls(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      if (entry.value != null) {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  static String? _trimOrNull(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static void _putIfNotNull(
    Map<String, dynamic> map,
    String key,
    dynamic value,
  ) {
    if (value != null) {
      map[key] = value;
    }
  }
}
