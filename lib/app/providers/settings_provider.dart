import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSettings {
  final String theme;
  final int fontSize;
  final bool onboardingDone;
  final int dailyGoal;

  const UserSettings({
    this.theme = 'light',
    this.fontSize = 16,
    this.onboardingDone = false,
    this.dailyGoal = 10,
  });

  UserSettings copyWith({
    String? theme,
    int? fontSize,
    bool? onboardingDone,
    int? dailyGoal,
  }) =>
      UserSettings(
        theme: theme ?? this.theme,
        fontSize: fontSize ?? this.fontSize,
        onboardingDone: onboardingDone ?? this.onboardingDone,
        dailyGoal: dailyGoal ?? this.dailyGoal,
      );
}

class SettingsNotifier extends StateNotifier<UserSettings> {
  SettingsNotifier() : super(const UserSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = UserSettings(
      theme: prefs.getString('theme') ?? 'light',
      fontSize: prefs.getInt('font_size') ?? 16,
      onboardingDone: prefs.getBool('onboarding_done') ?? false,
      dailyGoal: prefs.getInt('daily_goal') ?? 10,
    );
  }

  Future<void> setTheme(String theme) async {
    state = state.copyWith(theme: theme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme);
  }

  Future<void> setFontSize(int size) async {
    state = state.copyWith(fontSize: size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('font_size', size);
  }

  Future<void> setDailyGoal(int goal) async {
    state = state.copyWith(dailyGoal: goal);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daily_goal', goal);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingDone: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, UserSettings>((ref) {
  return SettingsNotifier();
});
