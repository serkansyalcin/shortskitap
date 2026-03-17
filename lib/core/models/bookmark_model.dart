import 'book_model.dart';

class BookmarkParagraphModel {
  final int id;
  final String content;
  final String? type;
  final int? sortOrder;

  const BookmarkParagraphModel({
    required this.id,
    required this.content,
    this.type,
    this.sortOrder,
  });

  factory BookmarkParagraphModel.fromJson(Map<String, dynamic> json) =>
      BookmarkParagraphModel(
        id: json['id'] as int,
        content: json['content'] as String? ?? '',
        type: json['type'] as String?,
        sortOrder: json['sort_order'] as int?,
      );
}

class BookmarkModel {
  final int id;
  final int bookId;
  final int paragraphId;
  final String? note;
  final DateTime? createdAt;
  final BookModel? book;
  final BookmarkParagraphModel? paragraph;

  const BookmarkModel({
    required this.id,
    required this.bookId,
    required this.paragraphId,
    this.note,
    this.createdAt,
    this.book,
    this.paragraph,
  });

  factory BookmarkModel.fromJson(Map<String, dynamic> json) => BookmarkModel(
    id: json['id'] as int,
    bookId: json['book_id'] as int,
    paragraphId: json['paragraph_id'] as int,
    note: json['note'] as String?,
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'] as String)
        : null,
    book: json['book'] != null
        ? BookModel.fromJson(json['book'] as Map<String, dynamic>)
        : null,
    paragraph: json['paragraph'] != null
        ? BookmarkParagraphModel.fromJson(
            json['paragraph'] as Map<String, dynamic>,
          )
        : null,
  );
}
