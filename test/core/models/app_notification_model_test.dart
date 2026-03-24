import 'package:flutter_test/flutter_test.dart';
import 'package:kitaplig/core/models/app_notification_model.dart';

void main() {
  group('AppNotificationModel', () {
    test('parses integers, numeric strings and null fields safely', () {
      final notification = AppNotificationModel.fromJson({
        'id': 12.0,
        'title': 'Yeni duel',
        'body': 'Bir teklifin var.',
        'type': 'duel_challenge',
        'created_at': '2026-03-24T12:30:00.000000Z',
        'read_at': null,
        'is_read': false,
        'deeplink': '/duels/12',
        'entity_type': 'duel',
        'entity_id': '12',
        'meta': {'challenger_name': 'Ali Can'},
      });

      expect(notification.id, 12);
      expect(notification.entityId, 12);
      expect(notification.isRead, isFalse);
      expect(notification.deeplink, '/duels/12');
      expect(notification.meta['challenger_name'], 'Ali Can');
    });

    test('parses notification page payload', () {
      final page = NotificationPageModel.fromJson({
        'items': [
          {
            'id': 1,
            'title': 'LP kazandın',
            'body': '+5 LP kazandın.',
            'type': 'lp_earned',
            'created_at': '2026-03-24T12:30:00.000000Z',
            'read_at': '2026-03-24T12:35:00.000000Z',
            'is_read': true,
            'deeplink': '/league',
            'entity_type': 'league_membership',
            'entity_id': 8,
            'meta': <String, dynamic>{},
          },
        ],
        'next_cursor': '24',
        'unread_count': 3.0,
      });

      expect(page.items, hasLength(1));
      expect(page.nextCursor, '24');
      expect(page.unreadCount, 3);
      expect(page.items.first.isRead, isTrue);
    });
  });
}
