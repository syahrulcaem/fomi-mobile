import '../core/api_client.dart';
import '../models/asset_model.dart';

class AssetService {
  AssetService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<AssetModel>> getAssets() async {
    final response = await _apiClient.dio.get('/assets');
    final data = response.data;

    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(AssetModel.fromJson)
          .toList();
    }

    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(AssetModel.fromJson)
          .toList();
    }

    return [];
  }

  Future<AssetModel> getAssetDetail(String id) async {
    final response = await _apiClient.dio.get('/assets/$id');
    final data = response.data as Map<String, dynamic>;
    if (data['asset'] is Map<String, dynamic>) {
      return AssetModel.fromJson(data['asset'] as Map<String, dynamic>);
    }
    return AssetModel.fromJson(data);
  }

  Future<AssetModel> createAsset({
    required String name,
    String? description,
  }) async {
    final response = await _apiClient.dio.post(
      '/assets',
      data: {
        'name': name,
        'description': description,
      },
    );
    return AssetModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AssetModel> updateAsset({
    required String assetId,
    required String name,
    String? description,
  }) async {
    final response = await _apiClient.dio.put(
      '/assets/$assetId',
      data: {
        'name': name,
        'description': description,
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic> && data['asset'] is Map<String, dynamic>) {
      return AssetModel.fromJson(data['asset'] as Map<String, dynamic>);
    }

    return AssetModel.fromJson(data as Map<String, dynamic>);
  }

  Future<AssetModel> toggleStatus(String assetId) async {
    final response =
        await _apiClient.dio.patch('/assets/$assetId/toggle-status');
    final data = response.data as Map<String, dynamic>;
    final assetData = data['asset'] as Map<String, dynamic>?;
    return AssetModel.fromJson(assetData ?? data);
  }
}
