import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_client.dart';
import '../../core/models/auth_session_model.dart';
import '../../core/models/reader_profile_capabilities_model.dart';
import '../../core/models/reader_profile_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cached_user_store.dart';
import '../../core/services/push_notification_service.dart';
import '../../core/platform/platform_support.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final List<ReaderProfileModel> profiles;
  final ReaderProfileModel? activeProfile;
  final ReaderProfileCapabilitiesModel profileCapabilities;
  final String? error;

  /// True when `/me` could not be reached but a locally cached profile is used.
  final bool isOfflineSession;

  const AuthState({
    required this.status,
    this.user,
    this.profiles = const <ReaderProfileModel>[],
    this.activeProfile,
    this.profileCapabilities = const ReaderProfileCapabilitiesModel.defaults(),
    this.error,
    this.isOfflineSession = false,
  });

  const AuthState.unknown() : this(status: AuthStatus.unknown);

  AuthState.authenticated(
    this.user, {
    this.profiles = const <ReaderProfileModel>[],
    this.activeProfile,
    this.profileCapabilities = const ReaderProfileCapabilitiesModel.defaults(),
    bool offlineSession = false,
  }) : status = AuthStatus.authenticated,
       error = null,
       isOfflineSession = offlineSession;

  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service = AuthService();

  AuthNotifier() : super(const AuthState.unknown()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await ApiClient.getToken();
    log("Auth check, token: $token");
    if (token == null) {
      state = const AuthState.unauthenticated();
      return;
    }

    final (result, session) = await _service.fetchSessionUser();
    switch (result) {
      case SessionFetchResult.success:
        if (session != null) {
          await _setSession(session, offlineSession: false);
        } else {
          await ApiClient.clearToken();
          await CachedUserStore.clear();
          state = const AuthState.unauthenticated();
        }
        break;
      case SessionFetchResult.unauthorized:
        await ApiClient.clearToken();
        await CachedUserStore.clear();
        state = const AuthState.unauthenticated();
        break;
      case SessionFetchResult.offline:
        final cached = await CachedUserStore.load();
        if (cached != null) {
          state = _stateFromSession(cached, offlineSession: true);
        } else {
          state = const AuthState.unauthenticated();
        }
        break;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final result = await _service.login(email, password);
      await _setSession(result.session, offlineSession: false);
      _syncOnboardingPrefs();
      return true;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: _parseError(e),
      );
      return false;
    }
  }

  Future<bool> register(
    String name,
    String email,
    String password, {
    required bool acceptTerms,
    required bool acceptPrivacyPolicy,
  }) async {
    try {
      final result = await _service.register(
        name,
        email,
        password,
        acceptTerms: acceptTerms,
        acceptPrivacyPolicy: acceptPrivacyPolicy,
      );
      await _setSession(result.session, offlineSession: false);
      _syncOnboardingPrefs();
      return true;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: _parseError(e),
      );
      return false;
    }
  }

  Future<bool> socialLogin({
    required String provider,
    String? idToken,
    String? accessToken,
    String? identityToken,
    String? authorizationCode,
    String? name,
    String? email,
    String? avatarUrl,
  }) async {
    try {
      final result = await _service.socialLogin(
        provider: provider,
        idToken: idToken,
        accessToken: accessToken,
        identityToken: identityToken,
        authorizationCode: authorizationCode,
        name: name,
        email: email,
        avatarUrl: avatarUrl,
      );
      await _setSession(result.session, offlineSession: false);
      _syncOnboardingPrefs();
      return true;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: _parseError(e),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _service.logout();
    await CachedUserStore.clear();
    state = const AuthState.unauthenticated();
  }

  Future<bool> deleteAccount(String password) async {
    try {
      await _service.deleteAccount(password);
      await CachedUserStore.clear();
      state = const AuthState.unauthenticated();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateProfile({
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
    try {
      final session = await _service.updateMe(
        name: name,
        username: username,
        email: email,
        dailyGoal: dailyGoal,
        preferredTheme: preferredTheme,
        preferredFontSize: preferredFontSize,
        childrenModeEnabled: childrenModeEnabled,
        avatarBytes: avatarBytes,
        avatarFileName: avatarFileName,
      );
      await _setSession(session, offlineSession: false);
      return true;
    } catch (e) {
      _setAuthenticatedError(_parseError(e));
      return false;
    }
  }

  Future<bool> refreshMe() async {
    final token = await ApiClient.getToken();
    if (token == null) {
      state = const AuthState.unauthenticated();
      return false;
    }

    final (result, session) = await _service.fetchSessionUser();
    switch (result) {
      case SessionFetchResult.success:
        if (session != null) {
          await _setSession(session, offlineSession: false);
          return true;
        }
        await ApiClient.clearToken();
        await CachedUserStore.clear();
        state = const AuthState.unauthenticated();
        return false;
      case SessionFetchResult.unauthorized:
        await ApiClient.clearToken();
        await CachedUserStore.clear();
        state = const AuthState.unauthenticated();
        return false;
      case SessionFetchResult.offline:
        final cached = await CachedUserStore.load();
        final fallback = _sessionFromState(state) ?? cached;
        if (fallback != null) {
          state = _stateFromSession(fallback, offlineSession: true);
          return true;
        }
        state = const AuthState.unauthenticated();
        return false;
    }
  }

  void updateUser(UserModel user) {
    state = AuthState.authenticated(
      user,
      profiles: state.profiles,
      activeProfile: state.activeProfile,
      profileCapabilities: state.profileCapabilities,
      offlineSession: false,
    );
    final snapshot = _sessionFromState(state);
    if (snapshot != null) {
      unawaited(CachedUserStore.save(snapshot));
    }
    _syncOnboardingPrefs();
  }

  Future<bool> createChildProfile({
    required String name,
    int? age,
    String? avatarUrl,
    Uint8List? avatarBytes,
    String? avatarFileName,
  }) async {
    try {
      final profile = await _service.createChildProfile(
        name: name,
        age: age,
        avatarUrl: avatarUrl,
      );
      if (avatarBytes != null) {
        await _service.uploadReaderProfileAvatar(
          profileId: profile.id,
          avatarBytes: avatarBytes,
          avatarFileName: avatarFileName,
        );
      }
      return await refreshMe();
    } catch (e) {
      _setAuthenticatedError(_parseError(e));
      return false;
    }
  }

  Future<bool> updateReaderProfile({
    required int profileId,
    required String name,
    int? age,
    String? avatarUrl,
    Uint8List? avatarBytes,
    String? avatarFileName,
  }) async {
    try {
      await _service.updateReaderProfile(
        profileId: profileId,
        name: name,
        age: age,
        avatarUrl: avatarUrl,
      );
      if (avatarBytes != null) {
        await _service.uploadReaderProfileAvatar(
          profileId: profileId,
          avatarBytes: avatarBytes,
          avatarFileName: avatarFileName,
        );
      }
      return await refreshMe();
    } catch (e) {
      _setAuthenticatedError(_parseError(e));
      return false;
    }
  }

  Future<bool> activateReaderProfile(int profileId, {String? parentPin}) async {
    try {
      final session = await _service.activateReaderProfile(
        profileId,
        parentPin: parentPin,
      );
      await _setSession(session, offlineSession: false);
      return true;
    } catch (e) {
      _setAuthenticatedError(_parseError(e));
      return false;
    }
  }

  Future<bool> archiveReaderProfile(int profileId) async {
    try {
      final session = await _service.archiveReaderProfile(profileId);
      await _setSession(session, offlineSession: false);
      return true;
    } catch (e) {
      _setAuthenticatedError(_parseError(e));
      return false;
    }
  }

  Future<bool> setParentPin(String pin) async {
    try {
      final session = await _service.setParentPin(pin);
      await _setSession(session, offlineSession: false);
      return true;
    } catch (e) {
      _setAuthenticatedError(_parseError(e));
      return false;
    }
  }

  Future<bool> verifyParentPin(String pin) {
    return _service.verifyParentPin(pin);
  }

  Future<void> _syncOnboardingPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPrefs = prefs.getStringList('onboarding_prefs');
      if (savedPrefs != null && savedPrefs.isNotEmpty) {
        final savedGoal = prefs.getInt('daily_goal') ?? 10;
        await ApiClient.instance.put(
          '/me',
          data: {'daily_goal': savedGoal, 'preferences': savedPrefs},
        );
        await prefs.remove('onboarding_prefs');
        await refreshMe();
      }
    } catch (_) {}
  }

  void _setAuthenticatedError(String error) {
    state = AuthState(
      status: AuthStatus.authenticated,
      user: state.user,
      profiles: state.profiles,
      activeProfile: state.activeProfile,
      profileCapabilities: state.profileCapabilities,
      error: error,
      isOfflineSession: state.isOfflineSession,
    );
  }

  String _parseError(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final code = data['code']?.toString();
        if (code != null && code.isNotEmpty) {
          return _translateCode(code, data['data']);
        }

        final errors = data['errors'];
        if (errors is Map<String, dynamic> && errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            return _translateMessage(firstError.first.toString());
          }
        }

        final message = data['message'];
        if (message != null) {
          return _translateMessage(message.toString());
        }
      }
    }

    return 'Bir hata oluştu. Lütfen tekrar deneyin.';
  }

  String _translateMessage(String message) {
    if (message.contains('unique') ||
        message.contains('already been taken') ||
        message.contains('zaten kullanılıyor')) {
      return 'Bu bilgi zaten kullanımda.';
    }
    if (message.contains('required')) {
      return 'Lütfen tüm alanları doldur.';
    }
    if (message == 'invalid_credentials' ||
        message == 'The provided credentials are incorrect.') {
      return 'E-posta veya şifre hatalı. Bilgilerini kontrol edip tekrar dene.';
    }
    if (message == 'Unauthenticated.') {
      return 'Oturumun sona ermiş görünüyor. Lütfen tekrar giriş yap.';
    }
    if (message == 'Ebeveyn şifresi doğrulanamadı.') {
      return 'Ebeveyn şifresi hatalı. Lütfen tekrar deneyin.';
    }
    return message;
  }

  String _translateCode(String code, Object? payload) {
    final data = payload is Map<String, dynamic> ? payload : null;

    switch (code) {
      case 'reader_profile_limit_reached':
        final limit = (data?['child_profile_limit'] as num?)?.toInt();
        final requiresPremium = data?['requires_premium_for_more'] == true;
        if (requiresPremium && limit != null) {
          return 'Bu hesapta en fazla $limit çocuk profili oluşturabilirsiniz. Daha fazlası için Premium gerekli.';
        }
        if (limit != null) {
          return 'Çocuk profili limiti dolu. En fazla $limit profil oluşturabilirsiniz.';
        }
        return 'Çocuk profili limiti dolu.';
      case 'parent_pin_required':
        return 'Lütfen ebeveyn şifresini girin.';
      case 'invalid_parent_pin':
        return 'Ebeveyn şifresi hatalı. Lütfen tekrar deneyin.';
      default:
        return code;
    }
  }

  Future<void> _setSession(
    AuthSessionModel session, {
    required bool offlineSession,
  }) async {
    await CachedUserStore.save(session);
    await ApiClient.saveActiveReaderProfileId(session.activeProfile?.id);
    if (PlatformSupport.isMobileNative) {
      unawaited(PushNotificationService.instance.syncTokenWithBackend());
    }
    state = _stateFromSession(session, offlineSession: offlineSession);
  }

  AuthState _stateFromSession(
    AuthSessionModel session, {
    required bool offlineSession,
  }) {
    return AuthState.authenticated(
      session.account,
      profiles: session.profiles,
      activeProfile: session.activeProfile,
      profileCapabilities: session.profileCapabilities,
      offlineSession: offlineSession,
    );
  }

  AuthSessionModel? _sessionFromState(AuthState authState) {
    final user = authState.user;
    if (user == null) {
      return null;
    }

    return AuthSessionModel(
      account: user,
      profiles: authState.profiles,
      activeProfile: authState.activeProfile,
      profileCapabilities: authState.profileCapabilities,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
