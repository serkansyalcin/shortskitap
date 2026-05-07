class FriendActivityUser {
  final int id;
  final String name;
  final String? username;
  final String? avatarUrl;

  const FriendActivityUser({
    required this.id,
    required this.name,
    this.username,
    this.avatarUrl,
  });

  factory FriendActivityUser.fromJson(Map<String, dynamic> json) =>
      FriendActivityUser(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        username: json['username'] as String?,
        avatarUrl: json['avatar_url'] as String?,
      );
}

class FriendActivityBook {
  final int id;
  final String title;
  final String? slug;
  final String? coverUrl;
  final String? author;

  const FriendActivityBook({
    required this.id,
    required this.title,
    this.slug,
    this.coverUrl,
    this.author,
  });

  factory FriendActivityBook.fromJson(Map<String, dynamic> json) =>
      FriendActivityBook(
        id: json['id'] as int? ?? 0,
        title: json['title'] as String? ?? '',
        slug: json['slug'] as String?,
        coverUrl: json['cover_url'] as String?,
        author: json['author'] as String?,
      );
}

class FriendActivityModel {
  final FriendActivityUser user;
  final FriendActivityBook book;
  final double completionPct;
  final bool isCompleted;
  final DateTime? lastReadAt;

  const FriendActivityModel({
    required this.user,
    required this.book,
    required this.completionPct,
    required this.isCompleted,
    this.lastReadAt,
  });

  factory FriendActivityModel.fromJson(Map<String, dynamic> json) =>
      FriendActivityModel(
        user: FriendActivityUser.fromJson(
          json['user'] as Map<String, dynamic>? ?? const {},
        ),
        book: FriendActivityBook.fromJson(
          json['book'] as Map<String, dynamic>? ?? const {},
        ),
        completionPct: (json['completion_pct'] as num?)?.toDouble() ?? 0,
        isCompleted: json['is_completed'] == true,
        lastReadAt: json['last_read_at'] is String
            ? DateTime.tryParse(json['last_read_at'] as String)
            : null,
      );
}
