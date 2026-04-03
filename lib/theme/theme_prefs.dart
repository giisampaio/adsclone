import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted user choice for [ThemeMode].
abstract final class ThemePrefs {
  static const _key = 'theme_mode';

  static Future<ThemeMode> load() async {
    final sp = await SharedPreferences.getInstance();
    switch (sp.getString(_key)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static Future<void> save(ThemeMode mode) async {
    final sp = await SharedPreferences.getInstance();
    final v = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await sp.setString(_key, v);
  }
}
