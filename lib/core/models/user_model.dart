class UserModel {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String provider;
  final bool isPremium;
  final int dailyGoal;
  final String preferredTheme;
  final int preferredFontSize;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.provider,
    required this.isPremium,
    required this.dailyGoal,
    required this.preferredTheme,
    required this.preferredFontSize,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        avatarUrl: json['avatar_url'] as String?,
        provider: json['provider'] as String? ?? 'email',
        isPremium: json['is_premium'] == true,
        dailyGoal: json['daily_goal'] as int? ?? 10,
        preferredTheme: json['preferred_theme'] as String? ?? 'system',
        preferredFontSize: json['preferred_font_size'] as int? ?? 16,
      );

  UserModel copyWith({
    String? name,
    String? avatarUrl,
    bool? isPremium,
    int? dailyGoal,
    String? preferredTheme,
    int? preferredFontSize,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        email: email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        provider: provider,
        isPremium: isPremium ?? this.isPremium,
        dailyGoal: dailyGoal ?? this.dailyGoal,
        preferredTheme: preferredTheme ?? this.preferredTheme,
        preferredFontSize: preferredFontSize ?? this.preferredFontSize,
      );
}
