import 'book_model.dart';

class SeriesModel {
  final int id;
  final String title;
  final String slug;
  final String? description;
  final String? coverImageUrl;
  final String? authorName;
  final bool isPublished;
  final int sortOrder;
  final int? booksCount;
  final List<BookModel> books;

  const SeriesModel({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
    this.coverImageUrl,
    this.authorName,
    required this.isPublished,
    required this.sortOrder,
    this.booksCount,
    this.books = const [],
  });

  factory SeriesModel.fromJson(Map<String, dynamic> json) => SeriesModel(
    id: json['id'] as int,
    title: json['title'] as String,
    slug: json['slug'] as String,
    description: json['description'] as String?,
    coverImageUrl: json['cover_image_url'] as String?,
    authorName: (json['author'] as Map<String, dynamic>?)?['name'] as String?,
    isPublished: json['is_published'] == true,
    sortOrder: json['sort_order'] as int? ?? 0,
    booksCount: json['books_count'] as int?,
    books:
        (json['books'] as List<dynamic>?)
            ?.map((b) => BookModel.fromJson(b as Map<String, dynamic>))
            .toList() ??
        [],
  );
}
