import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_client.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  const AuthState({required this.status, this.user, this.error});

  const AuthState.unknown() : this(status: AuthStatus.unknown);

  const AuthState.authenticated(UserModel user)
    : this(status: AuthStatus.authenticated, user: user);

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

    final user = await _service.getMe();
    if (user != null) {
      state = AuthState.authenticated(user);
    } else {
      await ApiClient.clearToken();
      state = const AuthState.unauthenticated();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final result = await _service.login(email, password);
      state = AuthState.authenticated(result.user);
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
      state = AuthState.authenticated(result.user);
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
    state = const AuthState.unauthenticated();
  }

  Future<bool> deleteAccount(String password) async {
    try {
      await _service.deleteAccount(password);
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
        avatarBytes: avatarBytes,
        avatarFileName: avatarFileName,
      );
      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: state.user,
        error: _parseError(e),
      );
      return false;
    }
  }

  Future<bool> refreshMe() async {
    try {
      final user = await _service.getMe();
      if (user == null) {
        await ApiClient.clearToken();
        state = const AuthState.unauthenticated();
        return false;
      }

      final currentUser = state.user;
      if (currentUser != null && _isSameUser(currentUser, user)) {
        return true;
      }

      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = AuthState(
        status: state.status,
        user: state.user,
        error: _parseError(e),
      );
      return false;
    }
  }

  void updateUser(UserModel user) {
    state = AuthState.authenticated(user);
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

  bool _isSameUser(UserModel a, UserModel b) {
    return a.id == b.id &&
        a.name == b.name &&
        a.username == b.username &&
        a.email == b.email &&
        a.avatarUrl == b.avatarUrl &&
        a.provider == b.provider &&
        a.isPremium == b.isPremium &&
        a.premiumExpiresAt == b.premiumExpiresAt &&
        a.dailyGoal == b.dailyGoal &&
        a.preferredTheme == b.preferredTheme &&
        a.preferredFontSize == b.preferredFontSize &&
        a.termsAcceptedAt == b.termsAcceptedAt &&
        a.privacyPolicyAcceptedAt == b.privacyPolicyAcceptedAt;
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
