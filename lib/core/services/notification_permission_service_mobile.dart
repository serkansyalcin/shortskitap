import 'package:permission_handler/permission_handler.dart';

import 'notification_permission_service.dart';

class _MobileNotificationPermissionService
    implements NotificationPermissionService {
  @override
  Future<NotificationPermissionState> getStatus() async {
    final status = await Permission.notification.status;
    return _mapStatus(status);
  }

  @override
  Future<void> openSettings() async {
    await openAppSettings();
  }

  @override
  Future<NotificationPermissionState> requestPermission() async {
    final status = await Permission.notification.request();
    return _mapStatus(status);
  }

  NotificationPermissionState _mapStatus(PermissionStatus status) {
    if (status.isGranted) return NotificationPermissionState.granted;
    if (status.isPermanentlyDenied) {
      return NotificationPermissionState.permanentlyDenied;
    }
    return NotificationPermissionState.denied;
  }
}

NotificationPermissionService createNotificationPermissionServiceImpl() {
  return _MobileNotificationPermissionService();
}
