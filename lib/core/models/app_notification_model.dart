class AppNotificationModel {
  final int id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final DateTime? readAt;
  final bool isRead;
  final String? deeplink;
  final String? entityType;
  final int? entityId;
  final Map<String, dynamic> meta;

  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.readAt,
    required this.isRead,
    this.deeplink,
    this.entityType,
    this.entityId,
    this.meta = const <String, dynamic>{},
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: _NotificationJsonParser.requiredInt(json, 'id'),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? 'generic',
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      isRead: json['is_read'] == true || json['read_at'] != null,
      deeplink: json['deeplink'] as String?,
      entityType: json['entity_type'] as String?,
      entityId: _NotificationJsonParser.nullableInt(json, 'entity_id'),
      meta: json['meta'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['meta'] as Map<String, dynamic>)
          : const <String, dynamic>{},
    );
  }

  AppNotificationModel copyWith({DateTime? readAt, bool? isRead}) {
    return AppNotificationModel(
      id: id,
      title: title,
      body: body,
      type: type,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
      isRead: isRead ?? this.isRead,
      deeplink: deeplink,
      entityType: entityType,
      entityId: entityId,
      meta: meta,
    );
  }
}

class NotificationPageModel {
  final List<AppNotificationModel> items;
  final String? nextCursor;
  final int unreadCount;

  const NotificationPageModel({
    required this.items,
    required this.nextCursor,
    required this.unreadCount,
  });

  const NotificationPageModel.empty()
    : items = const <AppNotificationModel>[],
      nextCursor = null,
      unreadCount = 0;

  factory NotificationPageModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? const <dynamic>[];
    return NotificationPageModel(
      items: itemsJson
          .whereType<Map<String, dynamic>>()
          .map(AppNotificationModel.fromJson)
          .toList(),
      nextCursor: json['next_cursor']?.toString(),
      unreadCount: _NotificationJsonParser.requiredInt(json, 'unread_count'),
    );
  }
}

class _NotificationJsonParser {
  static int requiredInt(Map<String, dynamic> json, String key) {
    final parsed = _parseInt(json[key]);
    if (parsed == null) {
      throw FormatException('`$key` alanı geçerli bir tam sayı değil.');
    }
    return parsed;
  }

  static int? nullableInt(Map<String, dynamic> json, String key) {
    return _parseInt(json[key]);
  }

  static int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      if (value.isFinite && value == value.roundToDouble()) {
        return value.toInt();
      }
      return null;
    }

    if (value is String) {
      final normalized = value.trim();
      if (normalized.isEmpty) {
        return null;
      }

      return int.tryParse(normalized) ??
          (() {
            final parsedNum = num.tryParse(normalized);
            if (parsedNum != null &&
                parsedNum.isFinite &&
                parsedNum == parsedNum.roundToDouble()) {
              return parsedNum.toInt();
            }
            return null;
          })();
    }

    return null;
  }
}
