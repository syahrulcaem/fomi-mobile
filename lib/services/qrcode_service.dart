import '../core/api_client.dart';
import '../models/asset_model.dart';
import '../models/paginated_response.dart';
import '../models/qrcode_model.dart';

class QrCodeService {
  QrCodeService(this._apiClient);

  final ApiClient _apiClient;

  Future<PaginatedResponse<QrCodeModel>> getUserQrCodes({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/assets',
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );

      final parsed = _extractAssetsAsQrCodes(response.data);
      if (parsed != null) {
        return parsed;
      }
    } catch (_) {
      // Fallback to legacy endpoint if assets endpoint shape changes.
    }

    final fallback = await _apiClient.dio.get(
      '/user/qrcodes',
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
    );

    return PaginatedResponse.fromAny<QrCodeModel>(
      fallback.data,
      QrCodeModel.fromJson,
    );
  }

  Future<QrCodeModel?> getQrCodeDetail(String assetId) async {
    try {
      final response = await _apiClient.dio.get('/assets/$assetId');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final assetJson = data['asset'] is Map<String, dynamic>
            ? data['asset'] as Map<String, dynamic>
            : data;
        return QrCodeModel.fromAsset(AssetModel.fromJson(assetJson));
      }
    } catch (_) {
      // Fallback to legacy endpoint when needed.
    }

    final fallback = await _apiClient.dio.get(
      '/user/qrcodes',
      queryParameters: {
        'asset_id': assetId,
        'per_page': 1,
      },
    );

    final parsed = PaginatedResponse.fromAny<QrCodeModel>(
      fallback.data,
      QrCodeModel.fromJson,
    );

    for (final item in parsed.items) {
      if (item.routeAssetId == assetId || item.id == assetId) {
        return item;
      }
    }

    return parsed.items.isNotEmpty ? parsed.items.first : null;
  }

  Future<QrCodeModel> updateQrCode({
    required String assetId,
    required String name,
    String? description,
    String? contactName,
    String? contactPhone,
    String? contactEmail,
  }) async {
    final payload = {
      'name': name,
      'description': description,
      'contact_info': {
        'name': contactName,
        'phone': contactPhone,
        'email': contactEmail,
      },
    };

    final response =
        await _apiClient.dio.put('/user/qrcodes/$assetId', data: payload);
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final qrMap = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data['qrcode'] is Map<String, dynamic>
              ? data['qrcode'] as Map<String, dynamic>
              : data;
      return QrCodeModel.fromJson(qrMap);
    }
    return QrCodeModel.fromJson(const {});
  }

  Future<QrCodeModel> toggleLostStatus(String assetId) async {
    final response =
        await _apiClient.dio.patch('/user/qrcodes/$assetId/toggle-lost');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final qrMap = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data['qrcode'] is Map<String, dynamic>
              ? data['qrcode'] as Map<String, dynamic>
              : data;
      return QrCodeModel.fromJson(qrMap);
    }
    return QrCodeModel.fromJson(const {});
  }

  PaginatedResponse<QrCodeModel>? _extractAssetsAsQrCodes(dynamic raw) {
    if (raw is List) {
      final items = raw
          .whereType<Map<String, dynamic>>()
          .map(AssetModel.fromJson)
          .map(QrCodeModel.fromAsset)
          .toList();
      return PaginatedResponse<QrCodeModel>(
        items: items,
        currentPage: 1,
        lastPage: 1,
        perPage: items.length,
        total: items.length,
      );
    }

    if (raw is Map<String, dynamic>) {
      final list = raw['data'] is List
          ? raw['data'] as List
          : raw['assets'] is List
              ? raw['assets'] as List
              : <dynamic>[];

      final items = list
          .whereType<Map<String, dynamic>>()
          .map(AssetModel.fromJson)
          .map(QrCodeModel.fromAsset)
          .toList();

      final currentPage = (raw['current_page'] as num?)?.toInt() ?? 1;
      final lastPage = (raw['last_page'] as num?)?.toInt() ?? 1;
      final perPage = (raw['per_page'] as num?)?.toInt() ?? items.length;
      final total = (raw['total'] as num?)?.toInt() ?? items.length;

      return PaginatedResponse<QrCodeModel>(
        items: items,
        currentPage: currentPage,
        lastPage: lastPage,
        perPage: perPage,
        total: total,
      );
    }

    return null;
  }
}
