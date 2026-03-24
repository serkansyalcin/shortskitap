import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../models/achievement_model.dart';

class AchievementService {
  AchievementService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  static const List<_DynamicAchievementTemplate> _dynamicTemplates = [
    _DynamicAchievementTemplate(
      id: -101,
      key: 'night_owl',
      title: 'Gece Kuşu',
      description: 'Saat 22:00 ile 03:59 arasında okuyarak kazanılır.',
      icon: '🌙',
      rarity: AchievementRarity.rare,
      xpReward: 40,
      hint: '22:00 ile 03:59 arasında en az bir okuma oturumu tamamla.',
      shouldUnlock: _isNightOwl,
    ),
    _DynamicAchievementTemplate(
      id: -102,
      key: 'weekend_warrior',
      title: 'Hafta Sonu Savaşçısı',
      description: 'Cumartesi veya pazar günü okuyarak kazanılır.',
      icon: '⚔️',
      rarity: AchievementRarity.uncommon,
      xpReward: 25,
      hint: 'Hafta sonunda en az bir okuma oturumu tamamla.',
      shouldUnlock: _isWeekendWarrior,
    ),
  ];

  Future<List<AchievementModel>> getAchievements() async {
    final apiAchievements = await _fetchApiAchievements();
    final localDynamicAchievements = await _getLocalDynamicAchievements();

    final merged = <String, AchievementModel>{
      for (final achievement in localDynamicAchievements)
        achievement.key: achievement,
    };

    for (final achievement in apiAchievements) {
      final localAchievement = merged[achievement.key];
      merged[achievement.key] = localAchievement == null
          ? achievement
          : _mergeAchievement(
              apiAchievement: achievement,
              localAchievement: localAchievement,
            );
    }

    final values = merged.values.toList()
      ..sort((left, right) {
        final earnedCompare =
            (right.isEarned ? 1 : 0) - (left.isEarned ? 1 : 0);
        if (earnedCompare != 0) return earnedCompare;

        final rarityCompare = right.rarity.index.compareTo(left.rarity.index);
        if (rarityCompare != 0) return rarityCompare;

        return (left.title ?? left.key).compareTo(right.title ?? right.key);
      });

    return values;
  }

  Future<List<AchievementModel>> trackDynamicAchievements({
    required DateTime readAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final unlocked = <AchievementModel>[];

    for (final template in _dynamicTemplates) {
      if (!template.shouldUnlock(readAt)) continue;

      final storageKey = _earnedAtStorageKey(template.key);
      if (prefs.getString(storageKey) != null) continue;

      await prefs.setString(storageKey, readAt.toIso8601String());
      unlocked.add(template.toAchievement(earnedAt: readAt));
    }

    return unlocked;
  }

  Future<void> markSeen(AchievementModel achievement) async {
    if (achievement.seenAt != null) {
      return;
    }

    if (achievement.source == AchievementSource.api && achievement.id > 0) {
      await _apiClient.post('/achievements/${achievement.id}/seen');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _seenAtStorageKey(achievement.key),
      DateTime.now().toIso8601String(),
    );
  }

  Future<List<AchievementModel>> _fetchApiAchievements() async {
    final response = await _apiClient.get('/achievements');
    final payload = response.data;
    final list = switch (payload) {
      {'data': final List<dynamic> data} => data,
      List<dynamic> data => data,
      _ => const <dynamic>[],
    };

    return list
        .whereType<Map<String, dynamic>>()
        .map(AchievementModel.fromJson)
        .toList();
  }

  Future<List<AchievementModel>> _getLocalDynamicAchievements() async {
    final prefs = await SharedPreferences.getInstance();

    return _dynamicTemplates.map((template) {
      final earnedAtRaw = prefs.getString(_earnedAtStorageKey(template.key));
      final seenAtRaw = prefs.getString(_seenAtStorageKey(template.key));

      return template.toAchievement(
        earnedAt: earnedAtRaw == null ? null : DateTime.tryParse(earnedAtRaw),
        seenAt: seenAtRaw == null ? null : DateTime.tryParse(seenAtRaw),
      );
    }).toList();
  }

  AchievementModel _mergeAchievement({
    required AchievementModel apiAchievement,
    required AchievementModel localAchievement,
  }) {
    return apiAchievement.copyWith(
      category:
          apiAchievement.category == AchievementCategory.reading &&
              localAchievement.category == AchievementCategory.dynamic
          ? localAchievement.category
          : apiAchievement.category,
      hint: apiAchievement.hint ?? localAchievement.hint,
      progressCurrent:
          apiAchievement.progressCurrent == 0 && localAchievement.isEarned
          ? localAchievement.progressCurrent
          : apiAchievement.progressCurrent,
      progressTarget: apiAchievement.progressTarget == 0
          ? localAchievement.progressTarget
          : apiAchievement.progressTarget,
      earnedAt: apiAchievement.earnedAt ?? localAchievement.earnedAt,
      seenAt: apiAchievement.seenAt ?? localAchievement.seenAt,
      metadata: {...localAchievement.metadata, ...apiAchievement.metadata},
    );
  }

  static String _earnedAtStorageKey(String key) =>
      'achievement.dynamic.$key.earned_at';

  static String _seenAtStorageKey(String key) =>
      'achievement.dynamic.$key.seen_at';

  static bool _isNightOwl(DateTime readAt) =>
      readAt.hour >= 22 || readAt.hour < 4;

  static bool _isWeekendWarrior(DateTime readAt) =>
      readAt.weekday == DateTime.saturday || readAt.weekday == DateTime.sunday;
}

class _DynamicAchievementTemplate {
  const _DynamicAchievementTemplate({
    required this.id,
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.xpReward,
    required this.hint,
    required this.shouldUnlock,
  });

  final int id;
  final String key;
  final String title;
  final String description;
  final String icon;
  final AchievementRarity rarity;
  final int xpReward;
  final String hint;
  final bool Function(DateTime readAt) shouldUnlock;

  AchievementModel toAchievement({DateTime? earnedAt, DateTime? seenAt}) {
    return AchievementModel(
      id: id,
      key: key,
      title: title,
      description: description,
      icon: icon,
      rarity: rarity,
      category: AchievementCategory.dynamic,
      source: AchievementSource.local,
      xpReward: xpReward,
      progressCurrent: earnedAt == null ? 0 : 1,
      progressTarget: 1,
      hint: hint,
      earnedAt: earnedAt,
      seenAt: seenAt,
      metadata: const {'is_dynamic': true},
    );
  }
}
