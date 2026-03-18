import '../api/api_client.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _client = ApiClient.instance;

  Future<({UserModel user, String token})> login(
      String email, String password) async {
    final res = await _client.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = res.data['data'] as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final token = data['token'] as String;
    await ApiClient.saveToken(token);
    return (user: user, token: token);
  }

  Future<({UserModel user, String token})> register(
      String name, String email, String password) async {
    final res = await _client.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': password,
    });
    final data = res.data['data'] as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final token = data['token'] as String;
    await ApiClient.saveToken(token);
    return (user: user, token: token);
  }

  Future<void> logout() async {
    try {
      await _client.post('/auth/logout');
    } catch (_) {}
    await ApiClient.clearToken();
  }

  Future<UserModel?> getMe() async {
    try {
      final res = await _client.get('/me');
      return UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> updateMe({
    String? name,
    int? dailyGoal,
    String? preferredTheme,
    int? preferredFontSize,
  }) async {
    final payload = <String, dynamic>{};

    if (name != null) payload['name'] = name;
    if (dailyGoal != null) payload['daily_goal'] = dailyGoal;
    if (preferredTheme != null) payload['preferred_theme'] = preferredTheme;
    if (preferredFontSize != null) {
      payload['preferred_font_size'] = preferredFontSize;
    }

    final res = await _client.put('/me', data: payload);
    return UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteAccount() async {
    await _client.delete('/me');
    await ApiClient.clearToken();
  }
}
