import 'package:flutter/widgets.dart';

import 'strings/en.dart';
import 'strings/ko.dart';
import 'strings/mn.dart';
import 'strings/zh.dart';

/// Supported app languages.
///
/// Each language's strings live in its own file under `strings/` (en.dart,
/// ko.dart, zh.dart, mn.dart). English is the source of truth; missing keys in
/// any other language fall back to English, then to the key itself.
enum AppLanguage {
  en(Locale('en'), 'English', 'English'),
  ko(Locale('ko'), 'Korean', '한국어'),
  zh(Locale('zh'), 'Chinese', '中文'),
  mn(Locale('mn'), 'Mongolian', 'Монгол');

  const AppLanguage(this.locale, this.englishName, this.nativeName);

  final Locale locale;
  final String englishName;
  final String nativeName;

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (l) => l.locale.languageCode == code,
      orElse: () => AppLanguage.en,
    );
  }
}

/// Translation lookup. Keys are dotted-by-feature and defined per language in
/// the `strings/` files. Missing keys fall back to English, then to the key.
class AppStrings {
  const AppStrings._();

  static List<Locale> get supportedLocales =>
      AppLanguage.values.map((l) => l.locale).toList();

  static String get(String code, String key) {
    return _tables[code]?[key] ?? enStrings[key] ?? key;
  }

  static const Map<String, Map<String, String>> _tables = {
    'en': enStrings,
    'ko': koStrings,
    'zh': zhStrings,
    'mn': mnStrings,
  };
}
