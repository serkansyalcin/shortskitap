import 'book_model.dart';

class ProgressModel {
  final int id;
  final int userId;
  final int bookId;
  final int? lastParagraphOrder;
  final int totalParagraphsRead;
  final double completionPercentage;
  final bool isCompleted;
  final DateTime? lastReadAt;
  final BookModel? book;

  const ProgressModel({
    required this.id,
    required this.userId,
    required this.bookId,
    this.lastParagraphOrder,
    required this.totalParagraphsRead,
    required this.completionPercentage,
    required this.isCompleted,
    this.lastReadAt,
    this.book,
  });

  factory ProgressModel.fromJson(Map<String, dynamic> json) => ProgressModel(
    id: json['id'] as int,
    userId: json['user_id'] as int,
    bookId: json['book_id'] as int,
    lastParagraphOrder: json['last_paragraph_order'] as int?,
    totalParagraphsRead: json['total_paragraphs_read'] as int? ?? 0,
    completionPercentage:
        (json['completion_percentage'] as num?)?.toDouble() ?? 0.0,
    isCompleted: json['is_completed'] == true,
    lastReadAt: json['last_read_at'] != null
        ? DateTime.tryParse(json['last_read_at'] as String)
        : null,
    book: json['book'] != null
        ? BookModel.fromJson(json['book'] as Map<String, dynamic>)
        : null,
  );
}

class StreakModel {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastReadDate;

  const StreakModel({
    required this.currentStreak,
    required this.longestStreak,
    this.lastReadDate,
  });

  factory StreakModel.fromJson(Map<String, dynamic> json) => StreakModel(
    currentStreak: json['current_streak'] as int? ?? 0,
    longestStreak: json['longest_streak'] as int? ?? 0,
    lastReadDate: json['last_read_date'] != null
        ? DateTime.tryParse(json['last_read_date'] as String)
        : null,
  );
}
