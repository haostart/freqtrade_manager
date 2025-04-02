import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  static const String _kApiKey = 'openai_api_key';
  static const String _kApiUrl = 'openai_api_url';
  static const String _kModel = 'model';

  SettingsProvider(this._prefs);

  String? get apiKey => _prefs.getString(_kApiKey);
  String? get apiUrl => _prefs.getString('chat_api_url');
  String? get model => _prefs.getString(_kModel);

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
} 