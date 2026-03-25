import 'dart:typed_data';

import 'package:dio/dio.dart';

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
    String name,
    String email,
    String password, {
    required bool acceptTerms,
    required bool acceptPrivacyPolicy,
  }) async {
    final res = await _client.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': password,
      'accept_terms': acceptTerms,
      'accept_privacy_policy': acceptPrivacyPolicy,
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
    String? username,
    String? email,
    int? dailyGoal,
    String? preferredTheme,
    int? preferredFontSize,
    Uint8List? avatarBytes,
    String? avatarFileName,
  }) async {
    final payload = <String, dynamic>{};

    if (name != null) payload['name'] = name;
    if (username != null) payload['username'] = username;
    if (email != null) payload['email'] = email;
    if (dailyGoal != null) payload['daily_goal'] = dailyGoal;
    if (preferredTheme != null) payload['preferred_theme'] = preferredTheme;
    if (preferredFontSize != null) {
      payload['preferred_font_size'] = preferredFontSize;
    }

    UserModel? updatedUser;

    if (payload.isNotEmpty) {
      final res = await _client.put('/me', data: payload);
      updatedUser = UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
    }

    if (avatarBytes != null) {
      final res = await _client.post(
        '/me/avatar',
        data: FormData.fromMap({
          'avatar': MultipartFile.fromBytes(
            avatarBytes,
            filename: avatarFileName ?? 'avatar.jpg',
          ),
        }),
      );
      updatedUser = UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
    }

    if (updatedUser != null) {
      return updatedUser;
    }

    final me = await getMe();
    if (me == null) {
      throw StateError('Profil güncellemesi sonrası kullanıcı verisi alınamadı.');
    }
    return me;
  }

  Future<void> deleteAccount(String password) async {
    await _client.delete('/me', data: {'password': password});
    await ApiClient.clearToken();
  }

  Future<void> requestPasswordReset(String email) async {
    await _client.post('/auth/forgot-password', data: {'email': email});
  }

  Future<void> verifyResetCode(String email, String code) async {
    await _client.post('/auth/verify-reset-code', data: {
      'email': email,
      'code': code,
    });
  }

  Future<void> submitNewPassword(
    String email,
    String code,
    String password,
  ) async {
    await _client.post('/auth/reset-password', data: {
      'email': email,
      'code': code,
      'password': password,
      'password_confirmation': password,
    });
  }

  Future<({UserModel user, String token})> socialLogin({
    required String provider,
    String? idToken,
    String? accessToken,
    String? identityToken,
    String? authorizationCode,
    String? name,
    String? email,
    String? avatarUrl,
  }) async {
    final res = await _client.post('/auth/social', data: {
      'provider': provider,
      if (idToken != null) 'id_token': idToken,
      if (accessToken != null) 'access_token': accessToken,
      if (identityToken != null) 'identity_token': identityToken,
      if (authorizationCode != null) 'authorization_code': authorizationCode,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    });
    final data = res.data['data'] as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final token = data['token'] as String;
    await ApiClient.saveToken(token);
    return (user: user, token: token);
  }
}
