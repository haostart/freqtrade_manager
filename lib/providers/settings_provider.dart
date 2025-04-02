import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  static const String _kApiKey = 'openai_api_key';
  static const String _kApiUrl = 'openai_api_url';
  static const String _kModel = 'model';
  static const String _kDarkMode = 'dark_mode';

  SettingsProvider(this._prefs);

  String? get apiKey => _prefs.getString(_kApiKey);
  String? get apiUrl => _prefs.getString('chat_api_url');
  String? get model => _prefs.getString(_kModel);
  bool get isDarkMode => _prefs.getBool(_kDarkMode) ?? false;

  Future<void> setApiKey(String value) async {
    await _prefs.setString(_kApiKey, value);
    notifyListeners();
  }

  Future<void> setApiUrl(String url) async {
    await _prefs.setString('chat_api_url', url);
    notifyListeners();
  }

  Future<void> setModel(String value) async {
    await _prefs.setString(_kModel, value);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    await _prefs.setBool(_kDarkMode, value);
    notifyListeners();
  }
} 