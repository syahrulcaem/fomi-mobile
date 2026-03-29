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
    final data = message.data;

    final title = notification?.title ?? data['title']?.toString();
    final body = notification?.body ?? data['body']?.toString();
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    await showLocalAlert(
      id: notification?.hashCode ??
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      channelId: 'fomi_alerts',
      channelName: 'FOMI Alerts',
      channelDescription: 'Notifikasi scan barcode dan update akun',
    );
  }

  Future<void> showChatAlert({
    required String title,
    required String body,
  }) async {
    await showLocalAlert(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      channelId: 'fomi_chat',
      channelName: 'FOMI Chat',
      channelDescription: 'Notifikasi chat anonim QR',
    );
  }

  Future<void> showLocalAlert({
    required int id,
    required String? title,
    required String? body,
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) async {
    if (kIsWeb) {
      return;
    }

    await _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}
