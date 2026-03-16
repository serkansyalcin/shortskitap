class LeagueSeasonModel {
  final int id;
  final int number;
  final DateTime startsAt;
  final DateTime endsAt;
  final int daysRemaining;

  const LeagueSeasonModel({
    required this.id,
    required this.number,
    required this.startsAt,
    required this.endsAt,
    required this.daysRemaining,
  });

  factory LeagueSeasonModel.fromJson(Map<String, dynamic> json) {
    return LeagueSeasonModel(
      id: json['id'] as int,
      number: json['number'] as int,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: DateTime.parse(json['ends_at'] as String),
      daysRemaining: json['days_remaining'] as int,
    );
  }
}

class LeagueMembershipModel {
  final String tier;
  final String tierLabel;
  final String tierIcon;
  final String tierColor;
  final String? nextTier;
  final int groupNumber;
  final int weeklyXp;
  final int rank;
  final int groupSize;
  final int promotionZone;
  final int demotionZone;
  final int? xpToPromotion;
  final Map<String, dynamic>? lastResult;

  const LeagueMembershipModel({
    required this.tier,
    required this.tierLabel,
    required this.tierIcon,
    required this.tierColor,
    this.nextTier,
    required this.groupNumber,
    required this.weeklyXp,
    required this.rank,
    required this.groupSize,
    required this.promotionZone,
    required this.demotionZone,
    this.xpToPromotion,
    this.lastResult,
  });

  factory LeagueMembershipModel.fromJson(Map<String, dynamic> json) {
    return LeagueMembershipModel(
      tier: json['tier'] as String,
      tierLabel: json['tier_label'] as String,
      tierIcon: json['tier_icon'] as String,
      tierColor: json['tier_color'] as String,
      nextTier: json['next_tier'] as String?,
      groupNumber: json['group_number'] as int,
      weeklyXp: json['weekly_xp'] as int,
      rank: json['rank'] as int,
      groupSize: json['group_size'] as int,
      promotionZone: json['promotion_zone'] as int,
      demotionZone: json['demotion_zone'] as int,
      xpToPromotion: json['xp_to_promotion'] as int?,
      lastResult: json['last_result'] as Map<String, dynamic>?,
    );
  }

  /// 0.0 – 1.0 progress toward promotion zone
  double get promotionProgress {
    if (groupSize == 0) return 0;
    final pct = (groupSize - rank) / (groupSize - promotionZone);
    return pct.clamp(0.0, 1.0);
  }

  bool get isInPromotionZone => rank <= promotionZone;
  bool get isInDemotionZone => rank >= demotionZone;
}

class LeaderboardEntry {
  final int rank;
  final int userId;
  final String name;
  final String? avatarUrl;
  final int weeklyXp;
  final bool isMe;
  final String resultPreview;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.weeklyXp,
    required this.isMe,
    required this.resultPreview,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      weeklyXp: json['weekly_xp'] as int,
      isMe: json['is_me'] as bool,
      resultPreview: json['result_preview'] as String,
    );
  }
}

class LeagueStatusModel {
  final LeagueSeasonModel season;
  final LeagueMembershipModel membership;

  const LeagueStatusModel({required this.season, required this.membership});

  factory LeagueStatusModel.fromJson(Map<String, dynamic> json) {
    return LeagueStatusModel(
      season: LeagueSeasonModel.fromJson(json['season'] as Map<String, dynamic>),
      membership: LeagueMembershipModel.fromJson(json['membership'] as Map<String, dynamic>),
    );
  }
}
