import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  static String? token;
  static SharedPreferences? _prefs;
  static const _tokenKey = 'auth_token';

  static void Function()? onSessionExpired;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    token = _prefs!.getString(_tokenKey);
  }

  static void setToken(String? value) {
    token = value;
    _saveToken(value);
  }

  static void clear() {
    token = null;
    _saveToken(null);
  }

  static Future<void> _saveToken(String? value) async {
    final prefs = _prefs;
    if (prefs == null) return;
    if (value != null) {
      await prefs.setString(_tokenKey, value);
    } else {
      await prefs.remove(_tokenKey);
    }
  }
}
