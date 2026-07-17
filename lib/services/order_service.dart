import '../core/api_client.dart';
import '../models/paginated_response.dart';
import '../models/order_model.dart';

class OrderService {
  OrderService(this._apiClient);

  final ApiClient _apiClient;

  Future<PaginatedResponse<OrderModel>> getOrders({
    int page = 1,
    int perPage = 10,
  }) async {
    final response = await _apiClient.dio.get(
      '/user/orders',
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
    );

    return extractPaginatedOrders(response.data);
  }

  Future<OrderModel> getOrderDetail(String orderId) async {
    final response = await _apiClient.dio.get('/user/orders/$orderId');
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final data = body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : body['order'] is Map<String, dynamic>
              ? body['order'] as Map<String, dynamic>
              : body;
      return OrderModel.fromJson(data);
    }
    return OrderModel.fromJson(const {});
  }

  static PaginatedResponse<OrderModel> extractPaginatedOrders(dynamic raw) {
    return PaginatedResponse.fromAny<OrderModel>(raw, OrderModel.fromJson);
  }

  Future<void> cancelOrder(String orderId) async {
    await _apiClient.dio.post('/user/orders/$orderId/cancel');
  }
}
