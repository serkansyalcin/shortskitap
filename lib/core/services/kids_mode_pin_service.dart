import 'package:shared_preferences/shared_preferences.dart';

const _keyParentPin = 'kids_mode_parent_pin';

class KidsModePinService {
  KidsModePinService(this._prefs);

  final SharedPreferences _prefs;

  static Future<KidsModePinService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return KidsModePinService(prefs);
  }

  Future<void> setPin(String pin) async {
    await _prefs.setString(_keyParentPin, pin);
  }

  String? getPin() => _prefs.getString(_keyParentPin);

  bool hasPin() => _prefs.containsKey(_keyParentPin) && (_prefs.getString(_keyParentPin) ?? '').length >= 4;

  bool verifyPin(String input) => getPin() == input;

  Future<void> clearPin() async {
    await _prefs.remove(_keyParentPin);
  }
}
