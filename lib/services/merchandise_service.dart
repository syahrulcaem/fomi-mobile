import '../core/api_client.dart';
import '../models/merchandise_item_model.dart';
import '../models/paginated_response.dart';

class MerchandiseService {
  MerchandiseService(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> verifyBarcode(String barcode) async {
    final response = await _apiClient.dio.post(
      '/merchandise/scan/verify',
      data: {'barcode_code': barcode},
    );

    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return const {};
  }

  Future<Map<String, dynamic>> activateBarcode(String barcode) async {
    final response = await _apiClient.dio.post(
      '/merchandise/activate',
      data: {'barcode_code': barcode},
    );

    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return const {};
  }

  Future<PaginatedResponse<MerchandiseItemModel>> getMyItems({
    int page = 1,
    int perPage = 10,
  }) async {
    final response = await _apiClient.dio.get(
      '/merchandise/my-items',
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
    );

    return PaginatedResponse.fromAny<MerchandiseItemModel>(
      response.data,
      MerchandiseItemModel.fromJson,
    );
  }
}
