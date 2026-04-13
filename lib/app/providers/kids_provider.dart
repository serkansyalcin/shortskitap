import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/kids_mode_pin_service.dart';
import 'auth_provider.dart';

const _kidsModePrefsKey = 'kids_mode_enabled';

class KidsModeNotifier extends StateNotifier<bool> {
  KidsModeNotifier(this._ref) : super(false) {
    final authUser = _ref.read(authProvider).user;
    if (authUser != null) {
      state = authUser.childrenModeEnabled;
      unawaited(_persistLocally(authUser.childrenModeEnabled));
    } else {
      unawaited(_restoreFromLocal());
    }
  }

  final Ref _ref;

  Future<void> handleAuthStateChanged(AuthState authState) async {
    final authUser = authState.user;
    if (authUser != null) {
      final enabled = authUser.childrenModeEnabled;
      if (state != enabled) {
        state = enabled;
      }
      await _persistLocally(enabled);
      return;
    }

    final enabled = await _readLocal();
    if (state != enabled) {
      state = enabled;
    }
  }

  Future<bool> setEnabled(bool enabled) async {
    final authState = _ref.read(authProvider);
    if (authState.isAuthenticated) {
      final ok = await _ref
          .read(authProvider.notifier)
          .updateProfile(childrenModeEnabled: enabled);
      if (!ok) {
        return false;
      }
    }

    state = enabled;
    await _persistLocally(enabled);
    return true;
  }

  Future<void> _restoreFromLocal() async {
    final enabled = await _readLocal();
    if (state != enabled) {
      state = enabled;
    }
  }

  Future<bool> _readLocal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kidsModePrefsKey) ?? false;
  }

  Future<void> _persistLocally(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kidsModePrefsKey, enabled);
  }
}

final kidsModeProvider = StateNotifierProvider<KidsModeNotifier, bool>((ref) {
  final notifier = KidsModeNotifier(ref);
  ref.listen<AuthState>(authProvider, (_, next) {
    unawaited(notifier.handleAuthStateChanged(next));
  });
  return notifier;
});

final kidsModePinServiceProvider = FutureProvider<KidsModePinService>((
  ref,
) async {
  return KidsModePinService.create();
});
