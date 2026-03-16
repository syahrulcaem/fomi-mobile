import '../core/api_client.dart';
import '../models/chat_model.dart';

class QrService {
  QrService(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> scanCode(String code) async {
    final response = await _apiClient.dio.get('/scan/$code');
    return response.data as Map<String, dynamic>;
  }

  Future<ChatModel> sendFinderMessage({
    required String code,
    required String sessionId,
    required String message,
  }) async {
    final response = await _apiClient.dio.post(
      '/scan/$code/chat',
      data: {
        'session_id': sessionId,
        'message': message,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final chatData = data['chat'] as Map<String, dynamic>?;
    return ChatModel.fromJson(chatData ?? data);
  }

  Future<List<ChatModel>> getFinderChats({
    required String code,
    required String sessionId,
  }) async {
    final response = await _apiClient.dio.get('/scan/$code/chats/$sessionId');
    final data = response.data;

    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(ChatModel.fromJson)
          .toList();
    }

    return [];
  }

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _apiClient.dio.get('/user/dashboard');
    return response.data as Map<String, dynamic>;
  }
}
