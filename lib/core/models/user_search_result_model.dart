class UserSearchResultModel {
  final int id;
  final String name;
  final String username;
  final String? avatarUrl;
  final bool isPremium;

  const UserSearchResultModel({
    required this.id,
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.isPremium,
  });

  factory UserSearchResultModel.fromJson(Map<String, dynamic> json) {
    return UserSearchResultModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      isPremium: json['is_premium'] == true,
    );
  }
}
