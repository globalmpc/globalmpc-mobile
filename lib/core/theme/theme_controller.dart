import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._prefs) {
    _mode = _parse(_prefs.getString(_key));
  }

  static const _key = 'app_theme_mode';
  final SharedPreferences _prefs;

  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _prefs.setString(_key, mode.name);
  }

  String get labelKey => 'theme.${_mode.name}';

  static ThemeMode _parse(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'system' => ThemeMode.system,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.light,
  };
}
