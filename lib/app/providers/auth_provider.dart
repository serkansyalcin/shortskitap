import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_client.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cached_user_store.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  /// True when `/me` could not be reached but a locally cached profile is used.
  final bool isOfflineSession;

  const AuthState({
    required this.status,
    this.user,
    this.error,
    this.isOfflineSession = false,
  });

  const AuthState.unknown() : this(status: AuthStatus.unknown);

  AuthState.authenticated(UserModel user, {bool offlineSession = false})
    : status = AuthStatus.authenticated,
      user = user,
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
    if (token == null) {
      state = const AuthState.unauthenticated();
      return;
    }

    final (result, user) = await _service.fetchSessionUser();
    switch (result) {
      case SessionFetchResult.success:
        if (user != null) {
          await CachedUserStore.save(user);
          state = AuthState.authenticated(user, offlineSession: false);
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
          state = AuthState.authenticated(cached, offlineSession: true);
        } else {
          state = const AuthState.unauthenticated();
        }
        break;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final result = await _service.login(email, password);
      await CachedUserStore.save(result.user);
      state = AuthState.authenticated(result.user, offlineSession: false);
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
      await CachedUserStore.save(result.user);
      state = AuthState.authenticated(result.user, offlineSession: false);
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
      final user = await _service.updateMe(
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
      await CachedUserStore.save(user);
      state = AuthState.authenticated(user, offlineSession: false);
      return true;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: state.user,
        error: _parseError(e),
        isOfflineSession: state.isOfflineSession,
      );
      return false;
    }
  }

  Future<bool> refreshMe() async {
    final token = await ApiClient.getToken();
    if (token == null) {
      state = const AuthState.unauthenticated();
      return false;
    }

    final (result, user) = await _service.fetchSessionUser();
    switch (result) {
      case SessionFetchResult.success:
        if (user != null) {
          await CachedUserStore.save(user);
          state = AuthState.authenticated(user, offlineSession: false);
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
        final fallback = state.user ?? cached;
        if (fallback != null) {
          state = AuthState.authenticated(fallback, offlineSession: true);
          return true;
        }
        state = const AuthState.unauthenticated();
        return false;
    }
  }

  void updateUser(UserModel user) {
    state = AuthState.authenticated(user, offlineSession: false);
    unawaited(CachedUserStore.save(user));
    _syncOnboardingPrefs();
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

  String _parseError(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
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
    return message;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
