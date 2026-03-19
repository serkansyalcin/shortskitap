class AchievementModel {
  final int id;
  final String key;
  final String? title;
  final String? description;
  final String? icon;
  final AchievementRarity rarity;
  final int xpReward;
  final DateTime? earnedAt;
  final DateTime? seenAt;

  const AchievementModel({
    required this.id,
    required this.key,
    this.title,
    this.description,
    this.icon,
    required this.rarity,
    required this.xpReward,
    this.earnedAt,
    this.seenAt,
  });

  bool get isEarned => earnedAt != null;
  bool get isSeen => seenAt != null;
  bool get isNew => isEarned && !isSeen;

  factory AchievementModel.fromJson(Map<String, dynamic> json) =>
      AchievementModel(
        id: json['id'] as int,
        key: json['key'] as String,
        title: json['title'] as String?,
        description: json['description'] as String?,
        icon: json['icon'] as String?,
        rarity: AchievementRarity.fromString(
          json['rarity'] as String? ?? 'common',
        ),
        xpReward: json['xp_reward'] as int? ?? 0,
        earnedAt: json['pivot']?['earned_at'] != null
            ? DateTime.tryParse(json['pivot']['earned_at'] as String)
            : null,
        seenAt: json['pivot']?['seen_at'] != null
            ? DateTime.tryParse(json['pivot']['seen_at'] as String)
            : null,
      );
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
        AchievementRarity.uncommon => 'Nadir Değil',
        AchievementRarity.rare => 'Nadir',
        AchievementRarity.epic => 'Destansı',
        AchievementRarity.legendary => 'Efsanevi',
      };
}
