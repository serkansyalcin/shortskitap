class PodcastModel {
  final int id;
  final String title;
  final String? description;
  final String audioUrl;
  final int? durationSeconds;
  final int? fileSizeBytes;
  final int sortOrder;

  const PodcastModel({
    required this.id,
    required this.title,
    this.description,
    required this.audioUrl,
    this.durationSeconds,
    this.fileSizeBytes,
    required this.sortOrder,
  });

  factory PodcastModel.fromJson(Map<String, dynamic> json) => PodcastModel(
        id: json['id'] as int,
        title: json['title'] as String,
        description: json['description'] as String?,
        audioUrl: json['audio_url'] as String,
        durationSeconds: json['duration_seconds'] as int?,
        fileSizeBytes: json['file_size_bytes'] as int?,
        sortOrder: json['sort_order'] as int? ?? 0,
      );

  String get durationFormatted {
    if (durationSeconds == null) return '';
    final m = durationSeconds! ~/ 60;
    final s = durationSeconds! % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
