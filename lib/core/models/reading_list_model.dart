class ReadingListBookItem {
  final int id;
  final String title;
  final String slug;
  final String? coverUrl;
  final bool isPremium;
  final String? authorName;
  final String? categoryName;
  final String? categoryColor;

  const ReadingListBookItem({
    required this.id,
    required this.title,
    required this.slug,
    this.coverUrl,
    this.isPremium = false,
    this.authorName,
    this.categoryName,
    this.categoryColor,
  });

  factory ReadingListBookItem.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    final category = json['category'] as Map<String, dynamic>?;
    return ReadingListBookItem(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      coverUrl: json['cover_url'] as String?,
      isPremium: json['is_premium'] == true,
      authorName: author?['name'] as String?,
      categoryName: category?['name'] as String?,
      categoryColor: category?['color'] as String?,
    );
  }
}

class ReadingListBookPreview {
  final int id;
  final String title;
  final String? coverUrl;

  const ReadingListBookPreview({
    required this.id,
    required this.title,
    this.coverUrl,
  });

  factory ReadingListBookPreview.fromJson(Map<String, dynamic> json) =>
      ReadingListBookPreview(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        coverUrl: json['cover_url'] as String?,
      );
}

class ReadingListModel {
  final int id;
  final String name;
  final String? description;
  final bool isPublic;
  final int bookCount;
  final List<ReadingListBookPreview> previewCovers;
  final DateTime? createdAt;

  const ReadingListModel({
    required this.id,
    required this.name,
    this.description,
    required this.isPublic,
    required this.bookCount,
    required this.previewCovers,
    this.createdAt,
  });

  factory ReadingListModel.fromJson(Map<String, dynamic> json) {
    final covers = (json['preview_covers'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ReadingListBookPreview.fromJson)
        .toList(growable: false);

    return ReadingListModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      isPublic: json['is_public'] == true,
      bookCount: json['book_count'] as int? ?? 0,
      previewCovers: covers,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  ReadingListModel copyWith({int? bookCount, List<ReadingListBookPreview>? previewCovers}) =>
      ReadingListModel(
        id: id,
        name: name,
        description: description,
        isPublic: isPublic,
        bookCount: bookCount ?? this.bookCount,
        previewCovers: previewCovers ?? this.previewCovers,
        createdAt: createdAt,
      );
}
