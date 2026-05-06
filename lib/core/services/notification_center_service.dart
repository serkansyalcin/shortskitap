import '../api/api_client.dart';
import '../models/app_notification_model.dart';

class NotificationCenterService {
  final ApiClient _api;

  NotificationCenterService(this._api);

  Future<NotificationPageModel> fetchNotifications({
    String? cursor,
    int limit = 20,
  }) async {
    final response = await _api.get(
      '/notifications',
      params: {
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );

    final data = response.data['data'] as Map<String, dynamic>?;
    if (data == null) {
      return const NotificationPageModel.empty();
    }

    return NotificationPageModel.fromJson(data);
  }

  Future<int> getUnreadCount() async {
    final response = await _api.get('/notifications/unread-count');
    final data = response.data['data'] as Map<String, dynamic>?;
    if (data == null) {
      return 0;
    }

    return (data['unread_count'] as num?)?.toInt() ?? 0;
  }

  Future<int> markVisible(List<int> ids) async {
    if (ids.isEmpty) {
      return 0;
    }

    final response = await _api.post(
      '/notifications/read-visible',
      data: {'ids': ids},
    );
    final data = response.data['data'] as Map<String, dynamic>?;
    return (data?['unread_count'] as num?)?.toInt() ?? 0;
  }

  Future<int> markAllRead() async {
    final response = await _api.post('/notifications/read-all');
    final data = response.data['data'] as Map<String, dynamic>?;
    return (data?['unread_count'] as num?)?.toInt() ?? 0;
  }

  Future<AppNotificationModel?> markRead(int notificationId) async {
    final response = await _api.post('/notifications/$notificationId/read');
    final data = response.data['data'] as Map<String, dynamic>?;
    final notificationJson = data?['notification'];
    if (notificationJson is! Map<String, dynamic>) {
      return null;
    }

    return AppNotificationModel.fromJson(notificationJson);
  }
}
