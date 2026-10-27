import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class JsonStore {
  const JsonStore(this._prefs, this.key);

  final SharedPreferences? _prefs;
  final String key;

  List<T> read<T>(T Function(Map<String, dynamic>) fromJson, List<T> fallback) {
    final raw = _prefs?.getString(key);
    if (raw == null) return List.of(fallback);
    try {
      final data = jsonDecode(raw) as List;
      return data
          .map((e) => fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return List.of(fallback);
    }
  }

  Future<void> write<T>(
    List<T> items,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(key, jsonEncode(items.map(toJson).toList()));
  }
}
