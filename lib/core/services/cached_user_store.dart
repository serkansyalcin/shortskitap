import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_session_model.dart';

const _kCachedUserJson = 'cached_user_profile_json';

/// Last successful `/me` profile for offline session recovery.
class CachedUserStore {
  CachedUserStore._();

  static Future<void> save(AuthSessionModel session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCachedUserJson, jsonEncode(session.toJson()));
  }

  static Future<AuthSessionModel?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCachedUserJson);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AuthSessionModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCachedUserJson);
  }
}
