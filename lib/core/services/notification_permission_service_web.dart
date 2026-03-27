// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;

import 'notification_permission_service.dart';

class _WebNotificationPermissionService
    implements NotificationPermissionService {
  bool get _isSecureContext {
    final protocol = html.window.location.protocol;
    final host = html.window.location.hostname;
    return protocol == 'https:' || host == 'localhost' || host == '127.0.0.1';
  }

  @override
  Future<NotificationPermissionState> getStatus() async {
    try {
      if (!html.Notification.supported || !_isSecureContext) {
        return NotificationPermissionState.unsupported;
      }
      return _mapPermission(html.Notification.permission);
    } catch (_) {
      return NotificationPermissionState.unsupported;
    }
  }

  @override
  Future<void> openSettings() async {
    html.window.alert(
      _isSecureContext
          ? 'Tarayici bildirim ayarlarini adres cubugundaki site izinlerinden acabilirsiniz.'
          : 'Web bildirimleri yalnizca HTTPS veya localhost uzerinde calisir. Bu sayfayi guvenli bir adreste acip tekrar deneyin.',
    );
  }

  @override
  Future<NotificationPermissionState> requestPermission() async {
    try {
      if (!html.Notification.supported || !_isSecureContext) {
        return NotificationPermissionState.unsupported;
      }
      final result = await html.Notification.requestPermission();
      return _mapPermission(result);
    } catch (_) {
      return NotificationPermissionState.unsupported;
    }
  }

  NotificationPermissionState _mapPermission(String? permission) {
    switch (permission) {
      case 'granted':
        return NotificationPermissionState.granted;
      case 'denied':
        return NotificationPermissionState.permanentlyDenied;
      default:
        return NotificationPermissionState.denied;
    }
  }
}

NotificationPermissionService createNotificationPermissionServiceImpl() {
  return _WebNotificationPermissionService();
}
