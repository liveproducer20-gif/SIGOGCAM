import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'app_user.dart';

class AuthSession {
  static String? token;
  static AppUser? user;
  static SharedPreferences? _prefs;
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user_v1';

  static void Function()? onSessionExpired;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    token = _prefs!.getString(_tokenKey);
    final savedUser = _prefs!.getString(_userKey);
    if (savedUser != null) {
      try {
        user = AppUser.fromJson(
          Map<String, dynamic>.from(jsonDecode(savedUser) as Map),
        );
      } catch (_) {
        user = null;
        await _prefs!.remove(_userKey);
      }
    }
  }

  static void setToken(String? value) {
    token = value;
    _saveToken(value);
  }

  static void setUser(AppUser value) {
    user = value;
    _prefs?.setString(_userKey, jsonEncode(value.toJson()));
  }

  static void clear() {
    token = null;
    user = null;
    _saveToken(null);
    _prefs?.remove(_userKey);
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
