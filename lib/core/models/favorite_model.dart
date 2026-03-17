import 'book_model.dart';

class FavoriteModel {
  final int id;
  final int bookId;
  final DateTime? createdAt;
  final BookModel? book;

  const FavoriteModel({
    required this.id,
    required this.bookId,
    this.createdAt,
    this.book,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) => FavoriteModel(
    id: json['id'] as int,
    bookId: json['book_id'] as int,
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'] as String)
        : null,
    book: json['book'] != null
        ? BookModel.fromJson(json['book'] as Map<String, dynamic>)
        : null,
  );
}
