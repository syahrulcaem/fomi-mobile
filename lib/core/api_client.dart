import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_interceptor.dart';

class ApiClient {
  ApiClient()
      : _dio = Dio(
          BaseOptions(
            baseUrl: const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'https://fomi.live/api',
            ),
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
            contentType: Headers.jsonContentType,
            responseType: ResponseType.json,
          ),
        ) {
    _dio.interceptors.add(AuthInterceptor(_secureStorage));
    if (kDebugMode) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint(
              '[API][REQ] ${options.method} ${options.baseUrl}${options.path}',
            );
            handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint(
              '[API][RES] ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.baseUrl}${response.requestOptions.path}',
            );
            handler.next(response);
          },
          onError: (error, handler) {
            final req = error.requestOptions;
            debugPrint(
              '[API][ERR] ${error.response?.statusCode ?? '-'} ${req.method} ${req.baseUrl}${req.path}',
            );
            debugPrint('[API][ERR][MSG] ${error.message}');
            if (error.response?.data != null) {
              debugPrint('[API][ERR][BODY] ${error.response?.data}');
            }
            handler.next(error);
          },
        ),
      );
    }
  }

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Dio _dio;

  Dio get dio => _dio;
  FlutterSecureStorage get secureStorage => _secureStorage;
}
