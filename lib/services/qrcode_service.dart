import '../core/api_client.dart';
import '../models/asset_model.dart';
import '../models/chat_model.dart';
import '../models/paginated_response.dart';
import '../models/qrcode_model.dart';

class QrCodeService {
  QrCodeService(this._apiClient);

  final ApiClient _apiClient;

  Future<PaginatedResponse<QrCodeModel>> getUserQrCodes({
    int page = 1,
    int perPage = 12,
  }) async {
    final response = await _apiClient.dio.get(
      '/user/qrcodes',
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
    );

    final parsed = _extractAssetsAsQrCodes(response.data);
    if (parsed != null) {
      return parsed;
    }

    return PaginatedResponse.fromAny<QrCodeModel>(
      response.data,
      QrCodeModel.fromJson,
    );
  }

  Future<QrCodeModel?> getQrCodeDetail(String assetId) async {
    final response = await _apiClient.dio.get('/assets/$assetId');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final assetJson = data['asset'] is Map<String, dynamic>
          ? data['asset'] as Map<String, dynamic>
          : data;
      return QrCodeModel.fromAsset(AssetModel.fromJson(assetJson));
    }

    return null;
  }

  Future<QrCodeModel> updateQrCode({
    required String assetId,
    required String name,
    String? description,
    String? contactName,
    String? contactPhone,
    String? contactEmail,
    String? contactAddress,
    String? contactNote,
    String? privacyMode,
    List<String>? visibleFields,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'description': _emptyToNull(description),
      'contact_name': _emptyToNull(contactName),
      'contact_phone': _emptyToNull(contactPhone),
      'contact_email': _emptyToNull(contactEmail),
      'contact_address': _emptyToNull(contactAddress),
      'contact_note': _emptyToNull(contactNote),
    };

    final normalizedPrivacyMode = _emptyToNull(privacyMode);
    if (normalizedPrivacyMode != null) {
      payload['privacy_mode'] = normalizedPrivacyMode;
    }

    if (visibleFields != null && visibleFields.isNotEmpty) {
      payload['visible_fields'] = visibleFields;
    }

    final response = await _apiClient.dio.put(
      '/user/qrcodes/$assetId',
      data: payload,
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final qrMap = data['asset'] is Map<String, dynamic>
          ? data['asset'] as Map<String, dynamic>
          : data['data'] is Map<String, dynamic>
              ? data['data'] as Map<String, dynamic>
              : data['qrcode'] is Map<String, dynamic>
                  ? data['qrcode'] as Map<String, dynamic>
                  : data;
      if (qrMap['contact_info'] != null || qrMap['qr_codes'] != null) {
        return QrCodeModel.fromAsset(AssetModel.fromJson(qrMap));
      }
      return QrCodeModel.fromJson(qrMap);
    }
    return QrCodeModel.fromAsset(AssetModel.fromJson(const {}));
  }

  Future<QrCodeModel> toggleLostStatus(String assetId) async {
    final response =
        await _apiClient.dio.patch('/user/qrcodes/$assetId/toggle-lost');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final qrMap = data['asset'] is Map<String, dynamic>
          ? data['asset'] as Map<String, dynamic>
          : data['data'] is Map<String, dynamic>
              ? data['data'] as Map<String, dynamic>
              : data['qrcode'] is Map<String, dynamic>
                  ? data['qrcode'] as Map<String, dynamic>
                  : data;
      if (qrMap['contact_info'] != null || qrMap['qr_codes'] != null) {
        return QrCodeModel.fromAsset(AssetModel.fromJson(qrMap));
      }
      return QrCodeModel.fromJson(qrMap);
    }
    return QrCodeModel.fromAsset(AssetModel.fromJson(const {}));
  }

  Future<Map<String, List<ChatModel>>> getAssetChats(String assetId) async {
    final response = await _apiClient.dio.get(
      '/assets/$assetId/chats',
      queryParameters: {
        '_t': DateTime.now().millisecondsSinceEpoch,
      },
    );
    final data = response.data;

    if (data is! Map<String, dynamic>) {
      return const {};
    }

    final result = <String, List<ChatModel>>{};
    for (final entry in data.entries) {
      final sessionId = entry.key;
      final value = entry.value;
      if (value is! List) {
        continue;
      }

      final messages = value
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => ChatModel.fromJson(
              item['session_id'] == null
                  ? {
                      ...item,
                      'session_id': sessionId,
                    }
                  : item,
            ),
          )
          .toList();

      result[sessionId] = messages;
    }

    return result;
  }

  Future<ChatModel> replyAssetChat({
    required String assetId,
    required String sessionId,
    required String message,
  }) async {
    final response = await _apiClient.dio.post(
      '/assets/$assetId/chats',
      data: {
        'session_id': sessionId,
        'message': message.trim(),
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final chatData = data['chat'] is Map<String, dynamic>
          ? data['chat'] as Map<String, dynamic>
          : data;
      return ChatModel.fromJson(chatData);
    }

    return ChatModel(
      id: '',
      assetId: assetId,
      senderType: 'owner',
      message: message,
      sessionId: sessionId,
    );
  }

  Future<bool> deleteAssetChatSession({
    required String assetId,
    required String sessionId,
  }) async {
    final encodedSession = Uri.encodeComponent(sessionId);

    try {
      await _apiClient.dio.delete('/assets/$assetId/chats/$encodedSession');
      return true;
    } on Exception {
      // Try alternate shape when backend expects session in body.
    }

    try {
      await _apiClient.dio.delete(
        '/assets/$assetId/chats',
        data: {
          'session_id': sessionId,
        },
      );
      return true;
    } on Exception {
      return false;
    }
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
      final nested = raw['data'] is Map<String, dynamic>
          ? raw['data'] as Map<String, dynamic>
          : null;

      final list = raw['data'] is List
          ? raw['data'] as List
          : nested?['data'] is List
              ? nested!['data'] as List
              : raw['assets'] is List
                  ? raw['assets'] as List
                  : <dynamic>[];

      final items = list
          .whereType<Map<String, dynamic>>()
          .map(AssetModel.fromJson)
          .map(QrCodeModel.fromAsset)
          .toList();

      final currentPage = (raw['current_page'] as num?)?.toInt() ??
          (nested?['current_page'] as num?)?.toInt() ??
          1;
      final lastPage = (raw['last_page'] as num?)?.toInt() ??
          (nested?['last_page'] as num?)?.toInt() ??
          1;
      final perPage = (raw['per_page'] as num?)?.toInt() ??
          (nested?['per_page'] as num?)?.toInt() ??
          items.length;
      final total = (raw['total'] as num?)?.toInt() ??
          (nested?['total'] as num?)?.toInt() ??
          items.length;

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

String? _emptyToNull(String? value) {
  if (value == null) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
