import '../core/api_client.dart';
import '../models/shop_dashboard_model.dart';
import '../models/shop_product_model.dart';

class ShopService {
  ShopService(this._apiClient);

  final ApiClient _apiClient;

  Future<ShopDashboardModel> getShopDashboard() async {
    final response = await _apiClient.dio.get('/dashboard');
    return ShopDashboardModel.fromJson(
      response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{},
    );
  }

  Future<List<ShopProduct>> getProducts({String? category}) async {
    final response = await _apiClient.dio.get(
      '/products',
      queryParameters: category != null && category.isNotEmpty
          ? {'category': category}
          : null,
    );
    final raw = response.data;
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(ShopProduct.fromJson)
          .toList();
    }
    return [];
  }

  Future<ShopProduct> getProductDetail(String id) async {
    final response = await _apiClient.dio.get('/products/$id');
    return ShopProduct.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Fetch checkout context: customer info, active_qr_assets, saved_addresses,
  /// available_shipping_couriers, renewal_targets, midtrans config.
  Future<Map<String, dynamic>> getCheckoutContext() async {
    final response = await _apiClient.dio.get('/user/shop/checkout/context');
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {};
  }

  /// Calculate shipping cost via backend (RajaOngkir proxy).
  /// [regencyId] destination regency id, [courier] e.g. 'jne', 'j&t'.
  Future<dynamic> getShippingCosts({
    required int regencyId,
    required String courier,
    required int totalWeight,
  }) async {
    final response = await _apiClient.dio.post('/shipping/cost', data: {
      'destination': regencyId,
      'weight': totalWeight,
      'courier': courier,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> checkout(Map<String, dynamic> data) async {
    final response =
        await _apiClient.dio.post('/user/shop/checkout', data: data);
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {};
  }

  Future<Map<String, dynamic>> checkMidtransStatus(String orderId) async {
    final response = await _apiClient.dio.post(
      '/midtrans/check-status',
      data: {'order_id': orderId},
    );
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {};
  }
}
