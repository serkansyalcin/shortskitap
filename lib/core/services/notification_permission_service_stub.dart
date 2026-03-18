import 'notification_permission_service.dart';

class _StubNotificationPermissionService
    implements NotificationPermissionService {
  @override
  Future<NotificationPermissionState> getStatus() async {
    return NotificationPermissionState.unsupported;
  }

  @override
  Future<void> openSettings() async {}

  @override
  Future<NotificationPermissionState> requestPermission() async {
    return NotificationPermissionState.unsupported;
  }
}

NotificationPermissionService createNotificationPermissionServiceImpl() {
  return _StubNotificationPermissionService();
}
