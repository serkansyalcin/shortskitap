class CharacterModel {
  final int id;
  final int bookId;
  final String name;
  final String? description;
  final CharacterRole role;
  final String? avatarUrl;
  final List<String> traits;
  final bool isAiGenerated;
  final int sortOrder;

  const CharacterModel({
    required this.id,
    required this.bookId,
    required this.name,
    this.description,
    required this.role,
    this.avatarUrl,
    required this.traits,
    required this.isAiGenerated,
    required this.sortOrder,
  });

  factory CharacterModel.fromJson(Map<String, dynamic> json) => CharacterModel(
        id: json['id'] as int,
        bookId: json['book_id'] as int,
        name: json['name'] as String,
        description: json['description'] as String?,
        role: CharacterRole.fromString(json['role'] as String? ?? 'supporting'),
        avatarUrl: json['avatar_url'] as String?,
        traits: (json['traits'] as List<dynamic>?)?.cast<String>() ?? [],
        isAiGenerated: json['is_ai_generated'] == true,
        sortOrder: json['sort_order'] as int? ?? 0,
      );
}

enum CharacterRole {
  protagonist,
  antagonist,
  supporting,
  narrator;

  static CharacterRole fromString(String value) => switch (value) {
        'protagonist' => CharacterRole.protagonist,
        'antagonist' => CharacterRole.antagonist,
        'narrator' => CharacterRole.narrator,
        _ => CharacterRole.supporting,
      };

  String get label => switch (this) {
        CharacterRole.protagonist => 'Başkahraman',
        CharacterRole.antagonist => 'Antagonist',
        CharacterRole.narrator => 'Anlatıcı',
        CharacterRole.supporting => 'Yan Karakter',
      };

  String get emoji => switch (this) {
        CharacterRole.protagonist => '⭐',
        CharacterRole.antagonist => '⚔️',
        CharacterRole.narrator => '📢',
        CharacterRole.supporting => '👤',
      };
}
