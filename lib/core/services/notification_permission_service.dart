import 'notification_permission_service_stub.dart'
    if (dart.library.html) 'notification_permission_service_web.dart'
    if (dart.library.io) 'notification_permission_service_mobile.dart';

enum NotificationPermissionState {
  granted,
  denied,
  permanentlyDenied,
  unsupported,
}

abstract class NotificationPermissionService {
  Future<NotificationPermissionState> getStatus();

  Future<NotificationPermissionState> requestPermission();

  Future<void> openSettings();
}

NotificationPermissionService createNotificationPermissionService() =>
    createNotificationPermissionServiceImpl();
