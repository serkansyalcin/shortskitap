import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kitaplig/app/providers/notification_provider.dart';
import 'package:kitaplig/core/api/api_client.dart';
import 'package:kitaplig/core/models/app_notification_model.dart';
import 'package:kitaplig/core/services/notification_center_service.dart';
import 'package:kitaplig/features/home/widgets/notification_bell_button.dart';

void main() {
  setUpAll(() async {
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost/api');
  });

  testWidgets('shows unread badge and latest notifications in menu', (
    WidgetTester tester,
  ) async {
    final fakeService = _FakeNotificationCenterService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationCenterServiceProvider.overrideWithValue(fakeService),
          unreadNotificationsCountProvider.overrideWith((ref) async => 2),
          notificationPreviewProvider.overrideWith((ref) async {
            return NotificationPageModel(
              items: [
                AppNotificationModel(
                  id: 4,
                  title: 'Yeni duel',
                  body: 'Rakibinden yeni teklif geldi.',
                  type: 'duel_challenge',
                  createdAt: DateTime(2026, 3, 24, 12, 0),
                  readAt: null,
                  isRead: false,
                  deeplink: '/duels/4',
                  entityType: 'duel',
                  entityId: 4,
                ),
              ],
              nextCursor: null,
              unreadCount: 2,
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: Center(child: NotificationBellButton())),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);

    final bellButton = tester.widget<IconButton>(find.byType(IconButton));
    bellButton.onPressed!.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Son Bildirimler'), findsOneWidget);
    expect(find.text('Yeni duel'), findsOneWidget);
    expect(fakeService.markedVisibleIds, <int>[4]);
  });
}

class _FakeNotificationCenterService extends NotificationCenterService {
  _FakeNotificationCenterService() : super(ApiClient.instance);

  List<int> markedVisibleIds = <int>[];

  @override
  Future<int> markVisible(List<int> ids) async {
    markedVisibleIds = ids;
    return 0;
  }

  @override
  Future<AppNotificationModel?> markRead(int notificationId) async {
    return null;
  }
}
