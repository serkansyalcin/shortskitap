class AiQuotaModel {
  final String featureKey;
  final String usageDate;
  final int usedCount;
  final int limitCount;
  final int remainingCount;
  final bool isPremium;
  final bool canGenerate;

  const AiQuotaModel({
    required this.featureKey,
    required this.usageDate,
    required this.usedCount,
    required this.limitCount,
    required this.remainingCount,
    required this.isPremium,
    required this.canGenerate,
  });

  factory AiQuotaModel.fromJson(Map<String, dynamic> json) => AiQuotaModel(
    featureKey: json['feature_key'] as String? ?? 'story_studio',
    usageDate: json['usage_date'] as String? ?? '',
    usedCount: (json['used_count'] as num?)?.toInt() ?? 0,
    limitCount: (json['limit_count'] as num?)?.toInt() ?? 0,
    remainingCount: (json['remaining_count'] as num?)?.toInt() ?? 0,
    isPremium: json['is_premium'] == true,
    canGenerate: json['can_generate'] == true,
  );
}
