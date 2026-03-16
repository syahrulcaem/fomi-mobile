import '../core/api_client.dart';
import '../models/dashboard_model.dart';

class DashboardService {
  DashboardService(this._apiClient);

  final ApiClient _apiClient;

  Future<DashboardModel> getDashboard() async {
    final response = await _apiClient.dio.get('/user/dashboard');
    final body = response.data;
    if (body is Map<String, dynamic>) {
      return DashboardModel.fromJson(body);
    }
    return DashboardModel.fromJson(const {});
  }
}
