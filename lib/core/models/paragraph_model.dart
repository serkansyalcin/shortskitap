enum ParagraphType { text, quote, sceneBreak }

class ParagraphModel {
  final int id;
  final int bookId;
  final int? chapterId;
  final String content;
  final int sortOrder;
  final int? wordCount;
  final int? estimatedSeconds;
  final ParagraphType type;
  final Map<String, dynamic>? chapter;

  const ParagraphModel({
    required this.id,
    required this.bookId,
    this.chapterId,
    required this.content,
    required this.sortOrder,
    this.wordCount,
    this.estimatedSeconds,
    required this.type,
    this.chapter,
  });

  factory ParagraphModel.fromJson(Map<String, dynamic> json) => ParagraphModel(
        id: json['id'] as int,
        bookId: json['book_id'] as int,
        chapterId: json['chapter_id'] as int?,
        content: json['content'] as String,
        sortOrder: json['sort_order'] as int,
        wordCount: json['word_count'] as int?,
        estimatedSeconds: json['estimated_seconds'] as int?,
        type: _typeFromString(json['type'] as String?),
        chapter: json['chapter'] as Map<String, dynamic>?,
      );

  static ParagraphType _typeFromString(String? type) {
    switch (type) {
      case 'quote':
        return ParagraphType.quote;
      case 'scene_break':
        return ParagraphType.sceneBreak;
      default:
        return ParagraphType.text;
    }
  }
}
