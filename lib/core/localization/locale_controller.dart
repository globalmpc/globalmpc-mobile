import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_strings.dart';

/// Holds the active language, persists the choice, and resolves translations.
/// Read a string anywhere with `context.tr('key')`.
class LocaleController extends ChangeNotifier {
  LocaleController(this._prefs) {
    final saved = _prefs.getString(_key);
    if (saved != null) _language = AppLanguage.fromCode(saved);
  }

  static const _key = 'app_language_code';
  final SharedPreferences _prefs;

  /// Default market language is Korean; a saved preference always wins.
  AppLanguage _language = AppLanguage.ko;
  AppLanguage get language => _language;
  Locale get locale => _language.locale;

  Future<void> setLanguage(AppLanguage language) async {
    if (language == _language) return;
    _language = language;
    notifyListeners();
    await _prefs.setString(_key, language.locale.languageCode);
  }

  String t(String key) => AppStrings.get(_language.locale.languageCode, key);
}

/// Ergonomic lookup: `context.tr('nav.home')`.
///
/// Uses `read` deliberately — the app root watches [LocaleController] to drive
/// `MaterialApp.locale`, so a language change rebuilds the whole subtree and
/// these lookups re-evaluate.
extension TrContext on BuildContext {
  String tr(String key) => LocaleControllerScope.of(this).t(key);
}

/// Thin accessor so widgets don't import provider just for a string.
class LocaleControllerScope {
  const LocaleControllerScope._();

  static LocaleController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_InheritedLocaleController>();
    assert(scope != null, 'LocaleControllerScope not found in widget tree');
    return scope!.controller;
  }

  static Widget provide({
    required LocaleController controller,
    required Widget child,
  }) {
    return _InheritedLocaleController(controller: controller, child: child);
  }
}

class _InheritedLocaleController extends InheritedNotifier<LocaleController> {
  const _InheritedLocaleController({
    required this.controller,
    required super.child,
  }) : super(notifier: controller);

  final LocaleController controller;
}
