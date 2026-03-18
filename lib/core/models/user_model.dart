class UserModel {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String provider;
  final bool isPremium;
  final DateTime? premiumExpiresAt;
  final int dailyGoal;
  final String preferredTheme;
  final int preferredFontSize;
  final DateTime? termsAcceptedAt;
  final DateTime? privacyPolicyAcceptedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.provider,
    required this.isPremium,
    this.premiumExpiresAt,
    required this.dailyGoal,
    required this.preferredTheme,
    required this.preferredFontSize,
    this.termsAcceptedAt,
    this.privacyPolicyAcceptedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        avatarUrl: json['avatar_url'] as String?,
        provider: json['provider'] as String? ?? 'email',
        isPremium: json['is_premium'] == true,
        premiumExpiresAt: json['premium_expires_at'] != null
            ? DateTime.tryParse(json['premium_expires_at'] as String)
            : null,
        dailyGoal: json['daily_goal'] as int? ?? 10,
        preferredTheme: json['preferred_theme'] as String? ?? 'system',
        preferredFontSize: json['preferred_font_size'] as int? ?? 16,
        termsAcceptedAt: json['terms_accepted_at'] != null
            ? DateTime.tryParse(json['terms_accepted_at'] as String)
            : null,
        privacyPolicyAcceptedAt: json['privacy_policy_accepted_at'] != null
            ? DateTime.tryParse(json['privacy_policy_accepted_at'] as String)
            : null,
      );

  UserModel copyWith({
    String? name,
    String? avatarUrl,
    bool? isPremium,
    DateTime? premiumExpiresAt,
    int? dailyGoal,
    String? preferredTheme,
    int? preferredFontSize,
    DateTime? termsAcceptedAt,
    DateTime? privacyPolicyAcceptedAt,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        email: email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        provider: provider,
        isPremium: isPremium ?? this.isPremium,
        premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
        dailyGoal: dailyGoal ?? this.dailyGoal,
        preferredTheme: preferredTheme ?? this.preferredTheme,
        preferredFontSize: preferredFontSize ?? this.preferredFontSize,
        termsAcceptedAt: termsAcceptedAt ?? this.termsAcceptedAt,
        privacyPolicyAcceptedAt:
            privacyPolicyAcceptedAt ?? this.privacyPolicyAcceptedAt,
      );
}
