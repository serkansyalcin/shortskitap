import 'book_model.dart';

class HighlightModel {
  final int id;
  final int bookId;
  final int? paragraphId;
  final String text;
  final String? note;
  final String? color;
  final DateTime? createdAt;
  final BookModel? book;

  const HighlightModel({
    required this.id,
    required this.bookId,
    this.paragraphId,
    required this.text,
    this.note,
    this.color,
    this.createdAt,
    this.book,
  });

  factory HighlightModel.fromJson(Map<String, dynamic> json) => HighlightModel(
        id: json['id'] as int,
        bookId: json['book_id'] as int,
        paragraphId: json['paragraph_id'] as int?,
        text: json['text'] as String? ?? '',
        note: json['note'] as String?,
        color: json['color'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        book: json['book'] != null
            ? BookModel.fromJson(json['book'] as Map<String, dynamic>)
            : null,
      );
}
