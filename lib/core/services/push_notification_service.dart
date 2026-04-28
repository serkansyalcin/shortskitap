import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../platform/platform_support.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log("Background message: ${message.messageId}");
}

@pragma('vm:entry-point')
Future<void> onDidReceiveBackgroundNotificationResponse(
  NotificationResponse response,
) async {
  await PushNotificationService.persistPendingDeepLinkFromPayload(
    response.payload,
  );
}

class PushNotificationService {
  static const _pendingDeepLinkKey = 'pending_push_deeplink';

  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  VoidCallback? _onMessageReceived;
  ValueChanged<String>? _onNotificationTap;

  bool _initialized = false;
  bool _localReady = false;

  Future<void> initialize({
    VoidCallback? onMessageReceived,
    ValueChanged<String>? onNotificationTap,
  }) async {
    if (onMessageReceived != null) {
      _onMessageReceived = onMessageReceived;
    }
    if (onNotificationTap != null) {
      _onNotificationTap = onNotificationTap;
    }

    await _initLocal();

    if (_initialized) {
      await _flushPendingDeepLink();
      return;
    }

    await _requestPermission();
    await _waitForApns();
    await _initFcm();

    _initialized = true;

    await _flushPendingDeepLink();
  }

  Future<void> _initLocal() async {
    if (_localReady) {
      return;
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _handleLocalNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );

    _localReady = true;

    final launchDetails = await _local.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      await _handleNotificationPayload(
        launchDetails?.notificationResponse?.payload,
      );
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    log("Permission: ${settings.authorizationStatus}");
  }

  Future<void> _waitForApns() async {
    if (!PlatformSupport.isIOS) {
      return;
    }

    for (int i = 0; i < 15; i++) {
      final apns = await _messaging.getAPNSToken();
      if (apns != null && apns.isNotEmpty) {
        log("APNS READY: $apns");
        return;
      }
      await Future.delayed(const Duration(seconds: 1));
    }

    log("APNS still null; check push capability on a real device.");
  }

  Future<void> _initFcm() async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    await syncTokenWithBackend();

    _messaging.onTokenRefresh.listen((token) async {
      log("TOKEN REFRESH: $token");
      await _saveToken(token);
      await _sendToBackend(token);
    });

    FirebaseMessaging.onMessage.listen((message) {
      log("Foreground: ${message.notification?.title}");
      showNotification(message, isForeground: true);
      _onMessageReceived?.call();
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      log("Opened notification");
      _onMessageReceived?.call();
      await _handleRemoteMessageTap(message);
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      log("App opened from terminated state");
      await _handleRemoteMessageTap(initialMessage);
    }
  }

  Future<void> showNotification(
    RemoteMessage message, {
    required bool isForeground,
  }) async {
    final title = message.notification?.title ?? "KitapLig";
    final body = message.notification?.body ?? "";

    const androidDetails = AndroidNotificationDetails(
      'high_importance',
      'High Importance',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    await _local.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(message.data),
    );
  }

  Future<void> syncTokenWithBackend() async {
    final token = await _messaging.getToken();
    log("FCM TOKEN: $token");

    if (token == null || token.isEmpty) {
      return;
    }

    await _saveToken(token);
    await _sendToBackend(token);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcmToken', token);
  }

  Future<void> _sendToBackend(String token) async {
    try {
      final response = await ApiClient.instance.post(
        '/push-token',
        data: {'push_token': token},
      );

      log("Backend response: $response");
    } catch (error) {
      log("Backend error: $error");
    }
  }

  Future<void> _handleLocalNotificationResponse(
    NotificationResponse response,
  ) async {
    await _handleNotificationPayload(response.payload);
  }

  Future<void> _handleRemoteMessageTap(RemoteMessage message) async {
    await _dispatchDeepLink(_extractDeepLink(message.data));
  }

  Future<void> _handleNotificationPayload(String? payload) async {
    if (payload == null || payload.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        await _dispatchDeepLink(_extractDeepLink(decoded));
        return;
      }
      if (decoded is Map) {
        await _dispatchDeepLink(
          _extractDeepLink(Map<String, dynamic>.from(decoded)),
        );
      }
    } catch (error) {
      log("Notification payload parse error: $error");
    }
  }

  String? _extractDeepLink(Map<String, dynamic> data) {
    final raw = data['deeplink']?.toString().trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return _normalizeDeepLink(raw);
  }

  String _normalizeDeepLink(String deepLink) {
    final normalized = deepLink.startsWith('/') ? deepLink : '/$deepLink';

    return switch (normalized) {
      '/settings/profile' => '/home/settings',
      _ => normalized,
    };
  }

  Future<void> _dispatchDeepLink(String? deepLink) async {
    if (deepLink == null || deepLink.isEmpty) {
      return;
    }

    final handler = _onNotificationTap;
    if (handler != null) {
      handler(deepLink);
      return;
    }

    await _persistPendingDeepLink(deepLink);
  }

  Future<void> _flushPendingDeepLink() async {
    final handler = _onNotificationTap;
    if (handler == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final deepLink = prefs.getString(_pendingDeepLinkKey);
    if (deepLink == null || deepLink.isEmpty) {
      return;
    }

    await prefs.remove(_pendingDeepLinkKey);
    handler(deepLink);
  }

  Future<void> _persistPendingDeepLink(String deepLink) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingDeepLinkKey, deepLink);
  }

  static Future<void> persistPendingDeepLinkFromPayload(String? payload) async {
    if (payload == null || payload.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(payload);
      final data = decoded is Map<String, dynamic>
          ? decoded
          : decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : null;
      if (data == null) {
        return;
      }

      final raw = data['deeplink']?.toString().trim();
      if (raw == null || raw.isEmpty) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final normalized = raw.startsWith('/') ? raw : '/$raw';
      final deepLink = normalized == '/settings/profile'
          ? '/home/settings'
          : normalized;
      await prefs.setString(_pendingDeepLinkKey, deepLink);
    } catch (_) {}
  }
}
