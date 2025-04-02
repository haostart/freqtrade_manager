import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  final SharedPreferences _prefs;
  static const String _kUsername = 'username';
  static const String _kPassword = 'password';
  static const String _kRememberMe = 'remember_me';

  StorageService(this._prefs);

  static Future<void> saveCredentials(String username, String password, String apiUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUsername, username);
    await prefs.setString(_kPassword, password);
    await prefs.setString('api_url', apiUrl);
    await prefs.setBool(_kRememberMe, true);
  }

  static Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUsername);
    await prefs.remove(_kPassword);
    await prefs.remove('api_url');
    await prefs.setBool(_kRememberMe, false);
  }

  static Future<Map<String, String?>> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_kRememberMe) ?? false;
    if (!rememberMe) return {};
    
    return {
      'username': prefs.getString(_kUsername),
      'password': prefs.getString(_kPassword),
      'api_url': prefs.getString('api_url'),
    };
  }

} 