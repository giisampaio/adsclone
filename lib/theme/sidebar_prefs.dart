import 'package:shared_preferences/shared_preferences.dart';

/// Preferência de sidebar expandida (web).
abstract final class SidebarPrefs {
  static const _key = 'sidebar_expanded';

  /// `null` se o utilizador nunca guardou — o UI pode usar largura do ecrã.
  static Future<bool?> load() async {
    final sp = await SharedPreferences.getInstance();
    if (!sp.containsKey(_key)) return null;
    return sp.getBool(_key);
  }

  static Future<void> save(bool expanded) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_key, expanded);
  }
}
