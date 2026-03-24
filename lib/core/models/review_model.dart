class ReviewModel {
  final int id;
  final int userId;
  final int rating;
  final String? comment;
  final String? userName;
  final String? userAvatarUrl;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.userId,
    required this.rating,
    this.comment,
    this.userName,
    this.userAvatarUrl,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>?;
    return ReviewModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      userName: userJson?['name'] as String?,
      userAvatarUrl: userJson?['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
