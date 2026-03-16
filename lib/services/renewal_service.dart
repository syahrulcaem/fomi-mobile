import '../core/api_client.dart';
import '../models/checkout_result_model.dart';
import '../models/renewal_package_model.dart';

class RenewalService {
  RenewalService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<RenewalPackageModel>> getPackages() async {
    final response = await _apiClient.dio.get('/user/renewal/packages');
    final data = response.data;

    if (data is Map<String, dynamic>) {
      final list = data['data'] is List
          ? data['data'] as List
          : data['packages'] is List
              ? data['packages'] as List
              : <dynamic>[];
      return list
          .whereType<Map<String, dynamic>>()
          .map(RenewalPackageModel.fromJson)
          .toList();
    }

    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(RenewalPackageModel.fromJson)
          .toList();
    }

    return const [];
  }

  Future<CheckoutResultModel> checkoutRenewal({
    required String productId,
    int quantity = 1,
    String? renewalAssetId,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
  }) async {
    final response = await _apiClient.dio.post(
      '/user/renewal/checkout',
      data: {
        'product_id': productId,
        'quantity': quantity,
        'renewal_asset_id': renewalAssetId,
        'customer_name': customerName,
        'customer_email': customerEmail,
        'customer_phone': customerPhone,
      },
    );

    if (response.data is Map<String, dynamic>) {
      return CheckoutResultModel.fromJson(
          response.data as Map<String, dynamic>);
    }
    return CheckoutResultModel.fromJson(const {});
  }

  Future<CheckoutResultModel> checkMidtransStatus(
      {required String orderId}) async {
    final response = await _apiClient.dio.post(
      '/midtrans/check-status',
      data: {
        'order_id': orderId,
      },
    );

    if (response.data is Map<String, dynamic>) {
      return CheckoutResultModel.fromJson(
          response.data as Map<String, dynamic>);
    }
    return CheckoutResultModel.fromJson(const {});
  }
}
