import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/kids_mode_pin_service.dart';
import 'auth_provider.dart';

final kidsModeProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.activeProfile?.isChild == true;
});

class KidsUiPrefs {
  const KidsUiPrefs({this.infoCardDismissed = false});

  final bool infoCardDismissed;

  KidsUiPrefs copyWith({bool? infoCardDismissed}) {
    return KidsUiPrefs(
      infoCardDismissed: infoCardDismissed ?? this.infoCardDismissed,
    );
  }
}

class KidsUiPrefsNotifier extends StateNotifier<KidsUiPrefs> {
  KidsUiPrefsNotifier() : super(const KidsUiPrefs()) {
    _load();
  }

  static const String _infoCardDismissedKey = 'kids_mode_info_card_dismissed';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      infoCardDismissed: prefs.getBool(_infoCardDismissedKey) ?? false,
    );
  }

  Future<void> dismissInfoCard() async {
    state = state.copyWith(infoCardDismissed: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_infoCardDismissedKey, true);
  }
}

final kidsUiPrefsProvider =
    StateNotifierProvider<KidsUiPrefsNotifier, KidsUiPrefs>((ref) {
      return KidsUiPrefsNotifier();
    });

final kidsModePinServiceProvider = FutureProvider<KidsModePinService>((
  ref,
) async {
  return KidsModePinService.create();
});
