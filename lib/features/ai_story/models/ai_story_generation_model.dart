import '../../../core/models/book_model.dart';
import 'ai_quota_model.dart';

class AiStoryGenerationModel {
  final int id;
  final String status;
  final String? step;
  final int progressCurrent;
  final int progressTotal;
  final String? errorMessage;
  final String? completedAt;
  final BookModel? book;
  final AiQuotaModel? quota;

  const AiStoryGenerationModel({
    required this.id,
    required this.status,
    this.step,
    required this.progressCurrent,
    required this.progressTotal,
    this.errorMessage,
    this.completedAt,
    this.book,
    this.quota,
  });

  factory AiStoryGenerationModel.fromJson(Map<String, dynamic> json) =>
      AiStoryGenerationModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        status: json['status'] as String? ?? 'pending',
        step: json['step'] as String?,
        progressCurrent: (json['progress_current'] as num?)?.toInt() ?? 0,
        progressTotal: (json['progress_total'] as num?)?.toInt() ?? 0,
        errorMessage: json['error_message'] as String?,
        completedAt: json['completed_at'] as String?,
        book: json['book'] != null
            ? BookModel.fromJson(json['book'] as Map<String, dynamic>)
            : null,
        quota: json['quota'] != null
            ? AiQuotaModel.fromJson(json['quota'] as Map<String, dynamic>)
            : null,
      );

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isActive => status == 'pending' || status == 'processing';

  double get progressRatio {
    if (progressTotal <= 0) return 0;
    final ratio = progressCurrent / progressTotal;
    if (ratio < 0) return 0;
    if (ratio > 1) return 1;
    return ratio;
  }
}
