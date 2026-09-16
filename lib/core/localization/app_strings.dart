import 'package:flutter/widgets.dart';

import 'strings/en.dart';
import 'strings/ko.dart';
import 'strings/mn.dart';
import 'strings/zh.dart';

enum AppLanguage {
  en(Locale('en'), 'English (US)', 'English', 'ENG'),
  ko(Locale('ko'), 'Korean', '한국어', 'KOR'),
  zh(Locale('zh'), 'Chinese', '中文', 'CHN'),
  mn(Locale('mn'), 'Mongolian', 'Монгол хэл', 'MON');

  const AppLanguage(
    this.locale,
    this.englishName,
    this.nativeName,
    this.shortCode,
  );

  final Locale locale;
  final String englishName;
  final String nativeName;

  final String shortCode;

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (l) => l.locale.languageCode == code,
      orElse: () => AppLanguage.en,
    );
  }
}

class AppStrings {
  const AppStrings._();

  static List<Locale> get supportedLocales =>
      AppLanguage.values.map((l) => l.locale).toList();

  static String get(String code, String key) {
    return _tables[code]?[key] ?? enStrings[key] ?? key;
  }

  static final Map<String, Map<String, String>> _tables = {
    'en': enStrings,
    'ko': koStrings,
    'zh': zhStrings,
    'mn': mnStrings,
  };
}
