import '../api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyParentPinExists = 'kids_mode_parent_pin_exists';

class KidsModePinService {
  KidsModePinService(this._prefs);

  final SharedPreferences _prefs;

  static Future<KidsModePinService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return KidsModePinService(prefs);
  }

  Future<void> setPin(String pin) async {
    await ApiClient.instance.put('/me/parent-pin', data: {'pin': pin});
    await _prefs.setBool(_keyParentPinExists, true);
  }

  bool hasPin() => _prefs.getBool(_keyParentPinExists) ?? false;

  Future<bool> verifyPin(String input) async {
    final response = await ApiClient.instance.post(
      '/me/parent-pin/verify',
      data: {'pin': input},
    );
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    final valid = data['valid'] == true;
    if (valid) {
      await _prefs.setBool(_keyParentPinExists, true);
    }
    return valid;
  }

  Future<void> clearPin() async {
    await _prefs.remove(_keyParentPinExists);
  }
}
