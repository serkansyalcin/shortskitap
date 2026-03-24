import 'achievement_model.dart';

class PublicProfileModel {
  final ProfileIdentityModel profile;
  final ProfileCountsModel counts;
  final ProfileRelationshipModel relationship;
  final ProfileStatsModel stats;
  final ProfileLeagueSummaryModel? activeLeague;
  final List<Map<String, dynamic>> leagueHistory;
  final List<AchievementModel> achievements;

  const PublicProfileModel({
    required this.profile,
    required this.counts,
    required this.relationship,
    required this.stats,
    required this.activeLeague,
    required this.leagueHistory,
    required this.achievements,
  });

  factory PublicProfileModel.fromJson(Map<String, dynamic> json) {
    final history = (json['league_history'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
    final achievements = (json['achievements'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AchievementModel.fromJson)
        .toList(growable: false);

    return PublicProfileModel(
      profile: ProfileIdentityModel.fromJson(
        json['profile'] as Map<String, dynamic>? ?? const {},
      ),
      counts: ProfileCountsModel.fromJson(
        json['counts'] as Map<String, dynamic>? ?? const {},
      ),
      relationship: ProfileRelationshipModel.fromJson(
        json['relationship'] as Map<String, dynamic>? ?? const {},
      ),
      stats: ProfileStatsModel.fromJson(
        json['stats'] as Map<String, dynamic>? ?? const {},
      ),
      activeLeague: json['active_league'] is Map<String, dynamic>
          ? ProfileLeagueSummaryModel.fromJson(
              json['active_league'] as Map<String, dynamic>,
            )
          : null,
      leagueHistory: history,
      achievements: achievements,
    );
  }
}

class ProfileIdentityModel {
  final int id;
  final String name;
  final String username;
  final String? avatarUrl;
  final bool isPremium;

  const ProfileIdentityModel({
    required this.id,
    required this.name,
    required this.username,
    this.avatarUrl,
    required this.isPremium,
  });

  factory ProfileIdentityModel.fromJson(Map<String, dynamic> json) {
    return ProfileIdentityModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      isPremium: json['is_premium'] == true,
    );
  }
}

class ProfileCountsModel {
  final int followers;
  final int following;

  const ProfileCountsModel({
    required this.followers,
    required this.following,
  });

  factory ProfileCountsModel.fromJson(Map<String, dynamic> json) {
    return ProfileCountsModel(
      followers: (json['followers'] as num?)?.toInt() ?? 0,
      following: (json['following'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProfileRelationshipModel {
  final bool isSelf;
  final bool isFollowing;

  const ProfileRelationshipModel({
    required this.isSelf,
    required this.isFollowing,
  });

  factory ProfileRelationshipModel.fromJson(Map<String, dynamic> json) {
    return ProfileRelationshipModel(
      isSelf: json['is_self'] == true,
      isFollowing: json['is_following'] == true,
    );
  }
}

class ProfileStatsModel {
  final int totalParagraphsRead;
  final int completedBooks;
  final int startedBooks;
  final int currentStreak;
  final int longestStreak;

  const ProfileStatsModel({
    required this.totalParagraphsRead,
    required this.completedBooks,
    required this.startedBooks,
    required this.currentStreak,
    required this.longestStreak,
  });

  factory ProfileStatsModel.fromJson(Map<String, dynamic> json) {
    return ProfileStatsModel(
      totalParagraphsRead: (json['total_paragraphs_read'] as num?)?.toInt() ?? 0,
      completedBooks: (json['completed_books'] as num?)?.toInt() ?? 0,
      startedBooks: (json['started_books'] as num?)?.toInt() ?? 0,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProfileLeagueSummaryModel {
  final int? seasonNumber;
  final int? daysRemaining;
  final String tier;
  final String tierLabel;
  final String tierIcon;
  final String tierColor;
  final int groupNumber;
  final int weeklyXp;
  final int weeklyLp;
  final int duelWins;
  final int duelLosses;
  final int streakShields;
  final int rank;
  final int groupSize;

  const ProfileLeagueSummaryModel({
    required this.seasonNumber,
    required this.daysRemaining,
    required this.tier,
    required this.tierLabel,
    required this.tierIcon,
    required this.tierColor,
    required this.groupNumber,
    required this.weeklyXp,
    required this.weeklyLp,
    required this.duelWins,
    required this.duelLosses,
    required this.streakShields,
    required this.rank,
    required this.groupSize,
  });

  factory ProfileLeagueSummaryModel.fromJson(Map<String, dynamic> json) {
    return ProfileLeagueSummaryModel(
      seasonNumber: (json['season_number'] as num?)?.toInt(),
      daysRemaining: (json['days_remaining'] as num?)?.toInt(),
      tier: json['tier'] as String? ?? '',
      tierLabel: json['tier_label'] as String? ?? '',
      tierIcon: json['tier_icon'] as String? ?? '',
      tierColor: json['tier_color'] as String? ?? '#22C55E',
      groupNumber: (json['group_number'] as num?)?.toInt() ?? 0,
      weeklyXp: (json['weekly_xp'] as num?)?.toInt() ?? 0,
      weeklyLp: (json['weekly_lp'] as num?)?.toInt() ?? 0,
      duelWins: (json['duel_wins'] as num?)?.toInt() ?? 0,
      duelLosses: (json['duel_losses'] as num?)?.toInt() ?? 0,
      streakShields: (json['streak_shields'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      groupSize: (json['group_size'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProfileFollowUserModel {
  final String name;
  final String username;
  final String? avatarUrl;
  final bool isPremium;
  final DateTime? followedAt;

  const ProfileFollowUserModel({
    required this.name,
    required this.username,
    this.avatarUrl,
    required this.isPremium,
    this.followedAt,
  });

  factory ProfileFollowUserModel.fromJson(Map<String, dynamic> json) {
    return ProfileFollowUserModel(
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      isPremium: json['is_premium'] == true,
      followedAt: json['followed_at'] != null
          ? DateTime.tryParse(json['followed_at'] as String)
          : null,
    );
  }
}

class ProfileFollowPageModel {
  final List<ProfileFollowUserModel> items;
  final int currentPage;
  final int lastPage;
  final int total;

  const ProfileFollowPageModel({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory ProfileFollowPageModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ProfileFollowUserModel.fromJson)
        .toList(growable: false);

    return ProfileFollowPageModel(
      items: items,
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
      total: (json['total'] as num?)?.toInt() ?? items.length,
    );
  }
}
