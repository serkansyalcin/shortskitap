import 'dart:html' as html;

import 'notification_permission_service.dart';

class _WebNotificationPermissionService
    implements NotificationPermissionService {
  @override
  Future<NotificationPermissionState> getStatus() async {
    try {
      if (!html.Notification.supported) {
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
      'Tarayıcı bildirim ayarlarını adres çubuğundaki site izinlerinden açabilirsiniz.',
    );
  }

  @override
  Future<NotificationPermissionState> requestPermission() async {
    try {
      if (!html.Notification.supported) {
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
