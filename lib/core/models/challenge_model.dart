class ChallengeModel {
  final int id;
  final String title;
  final String description;
  final String type;
  final String? icon;
  final int targetValue;
  final int currentValue;
  final int xpReward;
  final int lpReward;
  final bool isCompleted;
  final bool isClaimed;
  final int progressPct;

  const ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.icon,
    required this.targetValue,
    required this.currentValue,
    required this.xpReward,
    required this.lpReward,
    required this.isCompleted,
    required this.isClaimed,
    required this.progressPct,
  });

  factory ChallengeModel.fromJson(Map<String, dynamic> json) => ChallengeModel(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        type: json['type'] as String? ?? '',
        icon: json['icon'] as String?,
        targetValue: json['target_value'] as int? ?? 1,
        currentValue: json['current_value'] as int? ?? 0,
        xpReward: json['xp_reward'] as int? ?? 0,
        lpReward: json['lp_reward'] as int? ?? 0,
        isCompleted: json['is_completed'] == true,
        isClaimed: json['is_claimed'] == true,
        progressPct: json['progress_pct'] as int? ?? 0,
      );

  ChallengeModel copyWith({bool? isClaimed}) => ChallengeModel(
        id: id,
        title: title,
        description: description,
        type: type,
        icon: icon,
        targetValue: targetValue,
        currentValue: currentValue,
        xpReward: xpReward,
        lpReward: lpReward,
        isCompleted: isCompleted,
        isClaimed: isClaimed ?? this.isClaimed,
        progressPct: progressPct,
      );
}
