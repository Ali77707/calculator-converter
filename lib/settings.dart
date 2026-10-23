import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  Settings._();

  static const String themeKey = 'theme_mode';

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
}
