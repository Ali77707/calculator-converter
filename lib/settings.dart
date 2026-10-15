import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  Settings._();

  static const String themeKey = 'theme_mode';
  static const String converterFromKey = 'converter_from';
  static const String converterToKey = 'converter_to';

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  static Future<String?> loadThemeMode() async {
    final prefs = await _prefs;
    return prefs.getString(themeKey);
  }

  static Future<void> saveThemeMode(String mode) async {
    final prefs = await _prefs;
    await prefs.setString(themeKey, mode);
  }

  static Future<(String?, String?)> loadCurrencyPair() async {
    final prefs = await _prefs;
    return (prefs.getString(converterFromKey), prefs.getString(converterToKey));
  }

  static Future<void> saveCurrencyPair(String from, String to) async {
    final prefs = await _prefs;
    await prefs.setString(converterFromKey, from);
    await prefs.setString(converterToKey, to);
  }
}
