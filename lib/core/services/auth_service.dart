import 'dart:developer';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../models/auth_session_model.dart';
import '../models/family_reading_summary_model.dart';
import '../models/reader_profile_model.dart';
import '../platform/platform_support.dart';

/// Result of validating the stored session against `/me`.
enum SessionFetchResult { success, unauthorized, offline }

bool _isUnreachableDioError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return true;
    case DioExceptionType.badCertificate:
      return true;
    case DioExceptionType.badResponse:
      final code = e.response?.statusCode;
      return code == null || code >= 500;
    case DioExceptionType.cancel:
      return false;
    case DioExceptionType.unknown:
      final err = e.error;
      final errStr = err?.toString().toLowerCase() ?? '';
      if (errStr.contains('socketexception')) return true;
      final msg = (e.message ?? '').toLowerCase();
      return msg.contains('socket') ||
          msg.contains('network') ||
          msg.contains('failed host lookup') ||
          msg.contains('connection refused');
  }
}

class AuthService {
  final ApiClient _client = ApiClient.instance;

  Future<({AuthSessionModel session, String token})> login(
    String email,
    String password,
  ) async {
    final res = await _client.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = res.data['data'] as Map<String, dynamic>;
    final session = AuthSessionModel.fromJson(data);
    final token = data['token'] as String;
    await ApiClient.saveToken(token);
    await ApiClient.saveActiveReaderProfileId(session.activeProfile?.id);
    return (session: session, token: token);
  }

  Future<({AuthSessionModel session, String token})> register(
    String name,
    String email,
    String password, {
    required bool acceptTerms,
    required bool acceptPrivacyPolicy,
  }) async {
    final res = await _client.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'accept_terms': acceptTerms,
        'accept_privacy_policy': acceptPrivacyPolicy,
        'platform': PlatformSupport.platformName,
      },
    );
    final data = res.data['data'] as Map<String, dynamic>;
    final session = AuthSessionModel.fromJson(data);
    final token = data['token'] as String;
    await ApiClient.saveToken(token);
    await ApiClient.saveActiveReaderProfileId(session.activeProfile?.id);
    return (session: session, token: token);
  }

  Future<void> logout() async {
    try {
      await _client.post('/auth/logout');
    } catch (_) {}
    await ApiClient.clearToken();
  }

  /// Distinguishes invalid token (401) from network/API unreachable.
  Future<(SessionFetchResult, AuthSessionModel?)> fetchSessionUser() async {
    try {
      final res = await _client.get('/me');
      log("res /me: ${res.data}");
      final session = AuthSessionModel.fromJson(
        res.data['data'] as Map<String, dynamic>,
      );
      await ApiClient.saveActiveReaderProfileId(session.activeProfile?.id);
      return (SessionFetchResult.success, session);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401) {
        return (SessionFetchResult.unauthorized, null);
      }
      if (_isUnreachableDioError(e)) {
        return (SessionFetchResult.offline, null);
      }
      if (code != null && code >= 400 && code < 500) {
        return (SessionFetchResult.unauthorized, null);
      }
      return (SessionFetchResult.offline, null);
    } catch (_) {
      return (SessionFetchResult.offline, null);
    }
  }

  Future<AuthSessionModel?> getMe() async {
    final (result, session) = await fetchSessionUser();
    log("fetchSessionUser result: $result, session: ${session?.toJson()}");
    if (result == SessionFetchResult.success) return session;
    return null;
  }

  Future<AuthSessionModel> updateMe({
    String? name,
    String? username,
    String? email,
    int? dailyGoal,
    String? preferredTheme,
    int? preferredFontSize,
    bool? childrenModeEnabled,
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
    if (childrenModeEnabled != null) {
      payload['children_mode_enabled'] = childrenModeEnabled;
    }

    AuthSessionModel? updatedSession;

    if (payload.isNotEmpty) {
      final res = await _client.put('/me', data: payload);
      updatedSession = AuthSessionModel.fromJson(
        res.data['data'] as Map<String, dynamic>,
      );
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
      log("res ${res.data}");
      updatedSession = AuthSessionModel.fromJson(
        res.data['data'] as Map<String, dynamic>,
      );
    }

    if (updatedSession != null) {
      await ApiClient.saveActiveReaderProfileId(
        updatedSession.activeProfile?.id,
      );
      return updatedSession;
    }

    final me = await getMe();
    log("me after update: ${me?.toJson()}");
    if (me == null) {
      throw StateError(
        'Profil güncellemesi sonrası kullanıcı verisi alınamadı.',
      );
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
    await _client.post(
      '/auth/verify-reset-code',
      data: {'email': email, 'code': code},
    );
  }

  Future<void> submitNewPassword(
    String email,
    String code,
    String password,
  ) async {
    await _client.post(
      '/auth/reset-password',
      data: {
        'email': email,
        'code': code,
        'password': password,
        'password_confirmation': password,
      },
    );
  }

  Future<({AuthSessionModel session, String token})> socialLogin({
    required String provider,
    String? idToken,
    String? accessToken,
    String? identityToken,
    String? authorizationCode,
    String? name,
    String? email,
    String? avatarUrl,
  }) async {
    final res = await _client.post(
      '/auth/social',
      data: {
        'provider': provider,
        ...?_optionalField('id_token', idToken),
        ...?_optionalField('access_token', accessToken),
        ...?_optionalField('identity_token', identityToken),
        ...?_optionalField('authorization_code', authorizationCode),
        ...?_optionalField('name', name),
        ...?_optionalField('email', email),
        ...?_optionalField('avatar_url', avatarUrl),
      },
    );
    final data = res.data['data'] as Map<String, dynamic>;
    final session = AuthSessionModel.fromJson(data);
    final token = data['token'] as String;
    await ApiClient.saveToken(token);
    await ApiClient.saveActiveReaderProfileId(session.activeProfile?.id);
    return (session: session, token: token);
  }

  Future<List<ReaderProfileModel>> getReaderProfiles() async {
    final res = await _client.get('/me/profiles');
    final data = res.data['data'] as Map<String, dynamic>;
    final profiles = data['profiles'] as List<dynamic>? ?? const <dynamic>[];
    return profiles
        .whereType<Map<String, dynamic>>()
        .map(ReaderProfileModel.fromJson)
        .toList(growable: false);
  }

  Future<FamilyReadingSummaryModel> getFamilyReadingSummary() async {
    final res = await _client.get('/me/profiles/family-summary');
    final root = _asJsonMap(res.data);
    final data = _asJsonMap(root['data']);

    if (data.isNotEmpty) {
      return FamilyReadingSummaryModel.fromJson(data);
    }

    if (root.isNotEmpty) {
      return FamilyReadingSummaryModel.fromJson(root);
    }

    return FamilyReadingSummaryModel.fromJson(const <String, dynamic>{});
  }

  Future<ReaderProfileModel> createChildProfile({
    required String name,
    int? birthYear,
    String? avatarUrl,
  }) async {
    final res = await _client.post(
      '/me/profiles',
      data: {
        'name': name,
        ...?_optionalField('birth_year', birthYear),
        ...?_optionalField('avatar_url', avatarUrl),
      },
    );
    final data = res.data['data'] as Map<String, dynamic>;
    return ReaderProfileModel.fromJson(data['profile'] as Map<String, dynamic>);
  }

  Future<void> updateReaderProfile({
    required int profileId,
    required String name,
    int? birthYear,
    String? avatarUrl,
  }) async {
    await _client.put(
      '/me/profiles/$profileId',
      data: {'name': name, 'birth_year': birthYear, 'avatar_url': avatarUrl},
    );
  }

  Future<void> uploadReaderProfileAvatar({
    required int profileId,
    required Uint8List avatarBytes,
    String? avatarFileName,
  }) async {
    await _client.post(
      '/me/profiles/$profileId/avatar',
      data: FormData.fromMap({
        'avatar': MultipartFile.fromBytes(
          avatarBytes,
          filename: avatarFileName ?? 'reader-profile-avatar.jpg',
        ),
      }),
    );
  }

  Future<AuthSessionModel> activateReaderProfile(
    int profileId, {
    String? parentPin,
  }) async {
    final res = await _client.post(
      '/me/profiles/$profileId/activate',
      data: {
        ...?_optionalField(
          'parent_pin',
          parentPin?.isNotEmpty == true ? parentPin : null,
        ),
      },
    );
    final session = AuthSessionModel.fromJson(
      res.data['data'] as Map<String, dynamic>,
    );
    await ApiClient.saveActiveReaderProfileId(session.activeProfile?.id);
    return session;
  }

  Future<AuthSessionModel> archiveReaderProfile(int profileId) async {
    final res = await _client.delete('/me/profiles/$profileId');
    final session = AuthSessionModel.fromJson(
      res.data['data'] as Map<String, dynamic>,
    );
    await ApiClient.saveActiveReaderProfileId(session.activeProfile?.id);
    return session;
  }

  Future<AuthSessionModel> setParentPin(String pin) async {
    final res = await _client.put('/me/parent-pin', data: {'pin': pin});
    return AuthSessionModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<bool> verifyParentPin(String pin) async {
    final res = await _client.post('/me/parent-pin/verify', data: {'pin': pin});
    final data = res.data['data'] as Map<String, dynamic>? ?? {};
    return data['valid'] == true;
  }

  Map<String, dynamic>? _optionalField(String key, Object? value) {
    if (value == null) {
      return null;
    }

    return <String, dynamic>{key: value};
  }

  Map<String, dynamic> _asJsonMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return const <String, dynamic>{};
  }
}
