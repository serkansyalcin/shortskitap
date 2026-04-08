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
  /// Highlight color hex string (e.g. '#FFEB3B'), null if not highlighted.
  final String? highlightColor;
  final String? audioUrl;
  final String? audioProvider;
  final String? audioStatus;
  final int? audioDurationSeconds;

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
    this.highlightColor,
    this.audioUrl,
    this.audioProvider,
    this.audioStatus,
    this.audioDurationSeconds,
  });

  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;

  ParagraphModel copyWith({
    String? highlightColor,
    String? audioUrl,
    String? audioProvider,
    String? audioStatus,
    int? audioDurationSeconds,
  }) => ParagraphModel(
        id: id,
        bookId: bookId,
        chapterId: chapterId,
        content: content,
        sortOrder: sortOrder,
        wordCount: wordCount,
        estimatedSeconds: estimatedSeconds,
        type: type,
        chapter: chapter,
        highlightColor: highlightColor ?? this.highlightColor,
        audioUrl: audioUrl ?? this.audioUrl,
        audioProvider: audioProvider ?? this.audioProvider,
        audioStatus: audioStatus ?? this.audioStatus,
        audioDurationSeconds: audioDurationSeconds ?? this.audioDurationSeconds,
      );

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
        highlightColor: json['highlight_color'] as String?,
        audioUrl: json['audio_url'] as String?,
        audioProvider: json['audio_provider'] as String?,
        audioStatus: json['audio_status'] as String?,
        audioDurationSeconds: json['audio_duration_seconds'] as int?,
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
