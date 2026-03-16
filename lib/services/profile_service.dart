import '../core/api_client.dart';
import '../models/profile_model.dart';

class ProfileService {
  ProfileService(this._apiClient);

  final ApiClient _apiClient;

  Future<ProfileModel> getProfile() async {
    final response = await _apiClient.dio.get('/user/profile');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final profileData = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data['user'] is Map<String, dynamic>
              ? data['user'] as Map<String, dynamic>
              : data;
      return ProfileModel.fromJson(profileData);
    }
    return ProfileModel.fromJson(const {});
  }

  Future<ProfileModel> updateProfile({
    required String name,
    required String email,
    String? phone,
    String? address,
  }) async {
    final response = await _apiClient.dio.put(
      '/user/profile',
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final profileData = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data['user'] is Map<String, dynamic>
              ? data['user'] as Map<String, dynamic>
              : data;
      return ProfileModel.fromJson(profileData);
    }
    return getProfile();
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.dio.put(
      '/user/profile/password',
      data: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPassword,
      },
    );
  }

  Future<PrivacySettings> updatePrivacy(PrivacySettings privacy) async {
    final response = await _apiClient.dio.put(
      '/user/profile/privacy',
      data: privacy.toJson(),
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final privacyData = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data['privacy'] is Map<String, dynamic>
              ? data['privacy'] as Map<String, dynamic>
              : data;
      return PrivacySettings.fromJson(privacyData);
    }

    return privacy;
  }
}
