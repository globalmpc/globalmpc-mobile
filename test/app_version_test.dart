import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpc_mining_app/core/constants/app_info.dart';
import 'package:mpc_mining_app/core/localization/app_strings.dart';
import 'package:mpc_mining_app/core/localization/locale_controller.dart';
import 'package:mpc_mining_app/core/theme/app_theme.dart';
import 'package:mpc_mining_app/features/settings/about_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('appVersion matches pubspec', () {
    final match = RegExp(
      r'^version:\s*(\d+)\.(\d+)\.(\d+)',
      multiLine: true,
    ).firstMatch(File('pubspec.yaml').readAsStringSync());
    expect(match, isNotNull);
    expect(
      appVersion,
      '${match!.group(1)}.${match.group(2)}.${match.group(3)}',
    );
  });

  test('locale strings carry no hardcoded version footer', () {
    for (final lang in ['en', 'ko', 'zh', 'mn']) {
      final source = File(
        'lib/core/localization/strings/${lang}_screens.dart',
      ).readAsStringSync();
      expect(source.contains('versionFooter'), isFalse, reason: lang);
    }
  });

  testWidgets('about screen shows the pubspec version', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final prefs = await SharedPreferences.getInstance();
    final locale = LocaleController(prefs);
    await locale.setLanguage(AppLanguage.en);
    await tester.pumpWidget(
      LocaleControllerScope.provide(
        controller: locale,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AboutSettingsScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Version $appVersion'), findsOneWidget);
  });
}
