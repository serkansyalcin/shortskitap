import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';

/// ---------------- BACKGROUND HANDLER ----------------
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  await PushNotificationService.instance._initLocalOnly();

  await PushNotificationService.instance.showNotification(
    message,
    isForeground: false,
  );

  log("Background message: ${message.messageId}");
}

/// ---------------- SERVICE ----------------
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance =
      PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  VoidCallback? _onMessageReceived;

  bool _initialized = false;
  bool _localReady = false;

  /// ---------------- INIT ----------------
  Future<void> initialize({VoidCallback? onMessageReceived}) async {
    if (_initialized) return;

    _onMessageReceived = onMessageReceived;

    await _initLocal();
    await _requestPermission();

    await _waitForApns();

    await _initFcm();

    _initialized = true;
  }

  /// ---------------- LOCAL INIT ----------------
  Future<void> _initLocal() async {
    if (_localReady) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    await _local.initialize(
      const InitializationSettings(
        android: android,
        iOS: ios,
      ),
    );

    _localReady = true;
  }

  Future<void> _initLocalOnly() async {
    if (!_localReady) {
      await _initLocal();
    }
  }

  /// ---------------- PERMISSION ----------------
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    log("Permission: ${settings.authorizationStatus}");
  }

  /// ---------------- FIX APNS ----------------
  Future<void> _waitForApns() async {
    if (!Platform.isIOS) return;

    for (int i = 0; i < 15; i++) {
      final apns = await _messaging.getAPNSToken();
      if (apns != null && apns.isNotEmpty) {
        log("APNS READY: $apns");
        return;
      }
      await Future.delayed(const Duration(seconds: 1));
    }

    log("⚠️ APNS still null → check Push capability + real device");
  }

  /// ---------------- FCM INIT ----------------
  Future<void> _initFcm() async {
    /// 🔥 IMPORTANT FIX → prevents iOS duplicate notifications
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    final token = await _messaging.getToken();
    log("FCM TOKEN: $token");

    if (token != null) {
      await _saveToken(token);
      await _sendToBackend(token);
    }

    /// TOKEN REFRESH
    _messaging.onTokenRefresh.listen((token) async {
      log("TOKEN REFRESH: $token");
      await _saveToken(token);
      await _sendToBackend(token);
    });

    /// FOREGROUND MESSAGE
    FirebaseMessaging.onMessage.listen((msg) {
      log("Foreground: ${msg.notification?.title}");

      showNotification(msg, isForeground: true);

      _onMessageReceived?.call();
    });

    /// OPENED APP
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      log("Opened notification");
      _onMessageReceived?.call();
    });

    /// TERMINATED STATE
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      log("App opened from terminated state");
    }
  }

  /// ---------------- LOCAL NOTIFICATION ----------------
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
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// ---------------- STORAGE ----------------
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcmToken', token);
  }

  /// ---------------- BACKEND ----------------
  Future<void> _sendToBackend(String token) async {
    try {
      final res = await ApiClient.instance.post(
        '/push-token',
        data: {'push_token': token},
      );

      log("Backend response: $res");
    } catch (e) {
      log("Backend error: $e");
    }
  }
}