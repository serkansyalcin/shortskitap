import 'package:shared_preferences/shared_preferences.dart';

/// Streak: ardışık günlerde okuma. MVP — sadece "kaç gün üst üste okudun" hissi.
class StreakService {
  StreakService._();

  static const _keyLastReadDate = 'streak_last_read_ymd';
  static const _keyCurrentStreak = 'streak_count';

  /// Bugün okuma yapıldığında çağrılır. Streak'i günceller.
  static Future<void> recordReading() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayYmd();
    final lastYmd = prefs.getString(_keyLastReadDate);
    final current = prefs.getInt(_keyCurrentStreak) ?? 0;

    if (lastYmd == null) {
      await prefs.setString(_keyLastReadDate, today);
      await prefs.setInt(_keyCurrentStreak, 1);
      return;
    }

    if (lastYmd == today) {
      return;
    }

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayYmd = _ymd(yesterday);

    if (lastYmd == yesterdayYmd) {
      await prefs.setString(_keyLastReadDate, today);
      await prefs.setInt(_keyCurrentStreak, current + 1);
    } else {
      await prefs.setString(_keyLastReadDate, today);
      await prefs.setInt(_keyCurrentStreak, 1);
    }
  }

  static String _todayYmd() => _ymd(DateTime.now());
  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastYmd = prefs.getString(_keyLastReadDate);
    final current = prefs.getInt(_keyCurrentStreak) ?? 0;

    if (lastYmd == null) return 0;

    final lastDate = DateTime.parse(lastYmd);
    final today = DateTime.now();
    final diff = today.difference(lastDate).inDays;

    if (diff == 0) return current;
    if (diff == 1) return current;
    if (diff > 1) return 0;
    return 0;
  }

  /// Son okumanın yapıldığı tarih (YYYY-MM-DD). Gösterim için.
  static Future<String?> getLastReadDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastReadDate);
  }
}
