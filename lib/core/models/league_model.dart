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
  final int weeklyLp;
  final int duelWins;
  final int duelLosses;
  final int streakShields;
  final int rank;
  final int groupSize;
  final int promotionZone;
  final int demotionZone;
  final int? lpToPromotion;
  final Map<String, dynamic>? lastResult;

  const LeagueMembershipModel({
    required this.tier,
    required this.tierLabel,
    required this.tierIcon,
    required this.tierColor,
    this.nextTier,
    required this.groupNumber,
    required this.weeklyXp,
    required this.weeklyLp,
    required this.duelWins,
    required this.duelLosses,
    required this.streakShields,
    required this.rank,
    required this.groupSize,
    required this.promotionZone,
    required this.demotionZone,
    this.lpToPromotion,
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
      weeklyLp: json['weekly_lp'] as int? ?? 0,
      duelWins: json['duel_wins'] as int? ?? 0,
      duelLosses: json['duel_losses'] as int? ?? 0,
      streakShields: json['streak_shields'] as int? ?? 0,
      rank: json['rank'] as int,
      groupSize: json['group_size'] as int,
      promotionZone: json['promotion_zone'] as int,
      demotionZone: json['demotion_zone'] as int,
      lpToPromotion:
          json['lp_to_promotion'] as int? ?? json['xp_to_promotion'] as int?,
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
  final String username;
  final String? avatarUrl;
  final int weeklyXp;
  final int weeklyLp;
  final bool isMe;
  final bool isPremium;
  final String resultPreview;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.username,
    this.avatarUrl,
    required this.weeklyXp,
    required this.weeklyLp,
    required this.isMe,
    this.isPremium = false,
    required this.resultPreview,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String,
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      weeklyXp: json['weekly_xp'] as int,
      weeklyLp: json['weekly_lp'] as int? ?? 0,
      isMe: json['is_me'] as bool,
      isPremium: json['is_premium'] == true,
      resultPreview: json['result_preview'] as String,
    );
  }
}

class LeaderboardPageModel {
  final List<LeaderboardEntry> entries;
  final int total;
  final int limit;
  final int offset;
  final bool hasMore;
  final int? nextOffset;

  const LeaderboardPageModel({
    required this.entries,
    required this.total,
    required this.limit,
    required this.offset,
    required this.hasMore,
    required this.nextOffset,
  });

  factory LeaderboardPageModel.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] as List<dynamic>? ?? const [];
    return LeaderboardPageModel(
      entries: rawEntries
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? rawEntries.length,
      limit: json['limit'] as int? ?? rawEntries.length,
      offset: json['offset'] as int? ?? 0,
      hasMore: json['has_more'] == true,
      nextOffset: json['next_offset'] as int?,
    );
  }
}

class LeagueStatusModel {
  final LeagueSeasonModel season;
  final LeagueMembershipModel membership;

  const LeagueStatusModel({required this.season, required this.membership});

  factory LeagueStatusModel.fromJson(Map<String, dynamic> json) {
    return LeagueStatusModel(
      season: LeagueSeasonModel.fromJson(
        json['season'] as Map<String, dynamic>,
      ),
      membership: LeagueMembershipModel.fromJson(
        json['membership'] as Map<String, dynamic>,
      ),
    );
  }
}
