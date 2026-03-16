import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/api_client.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService(this._apiClient);

  final ApiClient _apiClient;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.dio.post(
      '/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final token = data['token']?.toString();
    if (token != null && token.isNotEmpty) {
      await _apiClient.secureStorage.write(key: 'auth_token', value: token);
    }
    final userJson = data['user'];
    if (userJson is Map<String, dynamic>) {
      return UserModel.fromJson(userJson);
    }
    return me();
  }

  Future<UserModel> loginWithGoogle() async {
    final googleSignIn = GoogleSignIn(scopes: const ['email', 'profile']);
    GoogleSignInAccount? account;
    try {
      account = await googleSignIn.signIn();
    } on PlatformException catch (e) {
      final details = e.message?.toLowerCase() ?? '';
      final isDeveloperError =
          e.code.toLowerCase().contains('sign_in_failed') &&
              (details.contains('api.b: 10') ||
                  details.contains('developer_error'));

      if (isDeveloperError) {
        throw Exception(
          'Google Sign-In gagal (DEVELOPER_ERROR). Pastikan package com.fomi dan SHA-1/SHA-256 (debug & release) sudah didaftarkan di Firebase untuk Android app ini.',
        );
      }
      throw Exception('Google Sign-In gagal: ${e.message ?? e.code}');
    }
    if (account == null) {
      throw Exception('Login Google dibatalkan.');
    }

    final googleAuth = await account.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Google ID token tidak tersedia.');
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: idToken,
    );
    final firebaseCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final firebaseIdToken = await firebaseCredential.user?.getIdToken();

    try {
      final response = await _exchangeGoogleToken(
        idToken: idToken,
        firebaseIdToken: firebaseIdToken,
        accessToken: googleAuth.accessToken,
        email: account.email,
        name: account.displayName,
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['token']?.toString();
      if (token != null && token.isNotEmpty) {
        await _apiClient.secureStorage.write(key: 'auth_token', value: token);
      }

      final userJson = data['user'];
      if (userJson is Map<String, dynamic>) {
        return UserModel.fromJson(userJson);
      }
      return me();
    } catch (_) {
      await FirebaseAuth.instance.signOut();
      await googleSignIn.signOut();
      rethrow;
    }
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final response = await _apiClient.dio.post(
      '/register',
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': password,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final token = data['token']?.toString();
    if (token != null && token.isNotEmpty) {
      await _apiClient.secureStorage.write(key: 'auth_token', value: token);
    }
    final userJson = data['user'];
    if (userJson is Map<String, dynamic>) {
      return UserModel.fromJson(userJson);
    }
    return me();
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/logout');
    } on DioException {
      // Keep local logout behavior even when API fails.
    }
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    await _apiClient.secureStorage.delete(key: 'auth_token');
  }

  Future<bool> hasToken() async {
    final token = await _apiClient.secureStorage.read(key: 'auth_token');
    return token != null && token.isNotEmpty;
  }

  Future<UserModel> me() async {
    try {
      final response = await _apiClient.dio.get('/me');
      final data = response.data as Map<String, dynamic>;
      final userData = data['user'] is Map<String, dynamic>
          ? data['user'] as Map<String, dynamic>
          : data;
      return UserModel.fromJson(userData);
    } on DioException {
      final response = await _apiClient.dio.get('/user/profile');
      final data = response.data as Map<String, dynamic>;
      final userData = data['user'] is Map<String, dynamic>
          ? data['user'] as Map<String, dynamic>
          : data;
      return UserModel.fromJson(userData);
    }
  }

  Future<Response<dynamic>> _exchangeGoogleToken({
    required String idToken,
    String? firebaseIdToken,
    String? accessToken,
    String? email,
    String? name,
  }) async {
    final endpoints = <String>[
      const String.fromEnvironment(
        'GOOGLE_LOGIN_PATH',
        defaultValue: '/auth/google',
      ),
      '/google/login',
      '/login/google',
    ];

    DioException? lastError;
    for (final endpoint in endpoints.toSet()) {
      try {
        return await _apiClient.dio.post(
          endpoint,
          data: {
            'id_token': idToken,
            'google_id_token': idToken,
            'google_token': idToken,
            'firebase_id_token': firebaseIdToken,
            'access_token': accessToken,
            'email': email,
            'name': name,
          },
        );
      } on DioException catch (e) {
        lastError = e;
        // Try other candidate paths before failing.
        continue;
      }
    }

    if (lastError != null) {
      final data = lastError.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message']?.toString();
        if (message != null && message.isNotEmpty) {
          throw Exception(message);
        }
      }
      throw Exception(lastError.message ?? 'Login Google gagal ke server.');
    }

    throw Exception('Endpoint login Google tidak ditemukan.');
  }
}
