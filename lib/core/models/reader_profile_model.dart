class ReaderProfileModel {
  final int id;
  final int userId;
  final String name;
  final String type;
  final String contentMode;
  final String? avatarUrl;
  final int? birthYear;
  final bool isDefault;
  final bool isActiveForLastSession;
  final bool isArchived;

  const ReaderProfileModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.contentMode,
    this.avatarUrl,
    this.birthYear,
    required this.isDefault,
    required this.isActiveForLastSession,
    required this.isArchived,
  });

  factory ReaderProfileModel.fromJson(Map<String, dynamic> json) =>
      ReaderProfileModel(
        id: _asInt(json['id']),
        userId: _asInt(json['user_id']),
        name: json['name']?.toString() ?? '',
        type: json['type']?.toString() ?? 'parent',
        contentMode: json['content_mode']?.toString() ?? 'adult',
        avatarUrl: json['avatar_url']?.toString(),
        birthYear: _asNullableInt(json['birth_year']),
        isDefault: json['is_default'] == true,
        isActiveForLastSession: json['is_active_for_last_session'] == true,
        isArchived: json['is_archived'] == true,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'type': type,
    'content_mode': contentMode,
    'avatar_url': avatarUrl,
    'birth_year': birthYear,
    'is_default': isDefault,
    'is_active_for_last_session': isActiveForLastSession,
    'is_archived': isArchived,
  };

  bool get isChild => type == 'child';

  bool get isParent => type == 'parent';

  static int _asInt(Object? value) {
    return _asNullableInt(value) ?? 0;
  }

  static int? _asNullableInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }
}
