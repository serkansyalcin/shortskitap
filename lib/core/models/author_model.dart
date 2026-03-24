class AuthorModel {
  final int id;
  final String name;
  final String? bio;
  final String? avatarUrl;
  final int? birthYear;
  final String? nationality;

  const AuthorModel({
    required this.id,
    required this.name,
    this.bio,
    this.avatarUrl,
    this.birthYear,
    this.nationality,
  });

  factory AuthorModel.fromJson(Map<String, dynamic> json) => AuthorModel(
    id: json['id'] as int,
    name: json['name'] as String,
    bio: json['bio'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    birthYear: json['birth_year'] as int?,
    nationality: json['nationality'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'bio': bio,
    'avatar_url': avatarUrl,
    'birth_year': birthYear,
    'nationality': nationality,
  };
}
