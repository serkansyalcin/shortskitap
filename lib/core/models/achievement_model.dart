class AchievementModel {
  final int id;
  final String key;
  final String? title;
  final String? description;
  final String? icon;
  final AchievementRarity rarity;
  final AchievementCategory category;
  final AchievementSource source;
  final int xpReward;
  final int progressCurrent;
  final int progressTarget;
  final String? hint;
  final DateTime? earnedAt;
  final DateTime? seenAt;
  final Map<String, dynamic> metadata;

  const AchievementModel({
    required this.id,
    required this.key,
    this.title,
    this.description,
    this.icon,
    required this.rarity,
    this.category = AchievementCategory.reading,
    this.source = AchievementSource.api,
    required this.xpReward,
    this.progressCurrent = 0,
    this.progressTarget = 0,
    this.hint,
    this.earnedAt,
    this.seenAt,
    this.metadata = const {},
  });

  bool get isEarned => earnedAt != null;
  bool get isSeen => seenAt != null;
  bool get isNew => isEarned && !isSeen;
  bool get isDynamic =>
      category == AchievementCategory.dynamic || metadata['is_dynamic'] == true;
  bool get hasProgress => progressTarget > 0;

  double get progressRatio {
    if (!hasProgress) return isEarned ? 1 : 0;
    final ratio = progressCurrent / progressTarget;
    return ratio.clamp(0, 1).toDouble();
  }

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    final pivot = _asStringMap(json['pivot']);
    final metadata = _asStringMap(json['metadata'])
      ..addAll(_asStringMap(json['criteria']));

    return AchievementModel(
      id: _asInt(json['id']) ?? 0,
      key: json['key'] as String? ?? '',
      title: json['title'] as String?,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      rarity: AchievementRarity.fromString(
        json['rarity'] as String? ?? 'common',
      ),
      category: AchievementCategory.fromString(
        json['category'] as String? ??
            metadata['category'] as String? ??
            (json['is_dynamic'] == true ? 'dynamic' : null) ??
            'reading',
      ),
      source: AchievementSource.fromString(json['source'] as String? ?? 'api'),
      xpReward: _asInt(json['xp_reward']) ?? 0,
      progressCurrent:
          _asInt(
            json['progress_current'] ??
                json['current_value'] ??
                json['earned_count'] ??
                metadata['progress_current'],
          ) ??
          0,
      progressTarget:
          _asInt(
            json['progress_target'] ??
                json['target_value'] ??
                metadata['progress_target'],
          ) ??
          0,
      hint: json['hint'] as String? ?? metadata['hint'] as String?,
      earnedAt: _parseDateTime(
        pivot['earned_at'] ?? json['earned_at'] ?? json['unlocked_at'],
      ),
      seenAt: _parseDateTime(pivot['seen_at'] ?? json['seen_at']),
      metadata: metadata,
    );
  }

  AchievementModel copyWith({
    int? id,
    String? key,
    String? title,
    String? description,
    String? icon,
    AchievementRarity? rarity,
    AchievementCategory? category,
    AchievementSource? source,
    int? xpReward,
    int? progressCurrent,
    int? progressTarget,
    String? hint,
    DateTime? earnedAt,
    DateTime? seenAt,
    Map<String, dynamic>? metadata,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      key: key ?? this.key,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      rarity: rarity ?? this.rarity,
      category: category ?? this.category,
      source: source ?? this.source,
      xpReward: xpReward ?? this.xpReward,
      progressCurrent: progressCurrent ?? this.progressCurrent,
      progressTarget: progressTarget ?? this.progressTarget,
      hint: hint ?? this.hint,
      earnedAt: earnedAt ?? this.earnedAt,
      seenAt: seenAt ?? this.seenAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'key': key,
    'title': title,
    'description': description,
    'icon': icon,
    'rarity': rarity.name,
    'category': category.name,
    'source': source.name,
    'xp_reward': xpReward,
    'progress_current': progressCurrent,
    'progress_target': progressTarget,
    'hint': hint,
    'earned_at': earnedAt?.toIso8601String(),
    'seen_at': seenAt?.toIso8601String(),
    'metadata': metadata,
  };
}

enum AchievementCategory {
  reading,
  streak,
  dynamic,
  collection,
  community,
  special;

  static AchievementCategory fromString(String value) => switch (value) {
    'streak' => AchievementCategory.streak,
    'dynamic' => AchievementCategory.dynamic,
    'collection' => AchievementCategory.collection,
    'community' => AchievementCategory.community,
    'special' => AchievementCategory.special,
    _ => AchievementCategory.reading,
  };

  String get label => switch (this) {
    AchievementCategory.reading => 'Okuma',
    AchievementCategory.streak => 'Seri',
    AchievementCategory.dynamic => 'Dinamik',
    AchievementCategory.collection => 'Koleksiyon',
    AchievementCategory.community => 'Topluluk',
    AchievementCategory.special => 'Özel',
  };
}

enum AchievementSource {
  api,
  local;

  static AchievementSource fromString(String value) => switch (value) {
    'local' => AchievementSource.local,
    _ => AchievementSource.api,
  };
}

enum AchievementRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary;

  static AchievementRarity fromString(String value) => switch (value) {
    'uncommon' => AchievementRarity.uncommon,
    'rare' => AchievementRarity.rare,
    'epic' => AchievementRarity.epic,
    'legendary' => AchievementRarity.legendary,
    _ => AchievementRarity.common,
  };

  String get label => switch (this) {
    AchievementRarity.common => 'Yaygın',
    AchievementRarity.uncommon => 'Sıradışı',
    AchievementRarity.rare => 'Nadir',
    AchievementRarity.epic => 'Destansı',
    AchievementRarity.legendary => 'Efsanevi',
  };
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _parseDateTime(Object? value) {
  if (value is String) return DateTime.tryParse(value);
  return null;
}

Map<String, dynamic> _asStringMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.from(value);
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}
