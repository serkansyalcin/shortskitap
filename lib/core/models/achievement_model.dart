class AchievementModel {
  final int id;
  final String key;
  final String? title;
  final String? description;
  final String? icon;
  final DateTime? earnedAt;

  const AchievementModel({
    required this.id,
    required this.key,
    this.title,
    this.description,
    this.icon,
    this.earnedAt,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) =>
      AchievementModel(
        id: json['id'] as int,
        key: json['key'] as String,
        title: json['title'] as String?,
        description: json['description'] as String?,
        icon: json['icon'] as String?,
        earnedAt: json['pivot']?['earned_at'] != null
            ? DateTime.tryParse(json['pivot']['earned_at'] as String)
            : null,
      );
}
