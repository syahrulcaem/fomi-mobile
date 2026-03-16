import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/api_client.dart';

class NotificationService {
  NotificationService(this._apiClient);

  final ApiClient _apiClient;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      return;
    }

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    _messaging.onTokenRefresh.listen((token) {
      _sendTokenToBackend(token);
    });

    _initialized = true;
  }

  Future<void> syncToken() async {
    if (kIsWeb) {
      return;
    }
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      return;
    }
    await _sendTokenToBackend(token);
  }

  Future<void> _sendTokenToBackend(String token) async {
    await _apiClient.dio.post(
      '/profile/fcm-token',
      data: {
        'fcm_token': token,
        'token': token,
        'device_type': kIsWeb ? 'web' : 'android',
      },
    );
  }

  Future<void> deleteTokenRegistration() async {
    if (kIsWeb) {
      return;
    }

    final token = await _messaging.getToken();
    await _apiClient.dio.delete(
      '/profile/fcm-token',
      data: {
        if (token != null && token.isNotEmpty) 'fcm_token': token,
        if (token != null && token.isNotEmpty) 'token': token,
        'device_type': kIsWeb ? 'web' : 'android',
      },
    );
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) {
      return;
    }

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fomi_alerts',
          'FOMI Alerts',
          channelDescription: 'Notifikasi scan barcode dan update akun',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}
