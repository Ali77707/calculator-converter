import 'package:flutter/material.dart';

import 'settings.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  Future<void> load() async {
    final saved = await Settings.loadThemeMode();
    _mode = switch (saved) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.light,
    };
    notifyListeners();
  }

  Future<void> toggle() async {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    await Settings.saveThemeMode(isDark ? 'dark' : 'light');
  }
}

final ThemeController themeController = ThemeController();
