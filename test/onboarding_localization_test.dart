import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpc_mining_app/core/localization/app_strings.dart';
import 'package:mpc_mining_app/core/localization/locale_controller.dart';
import 'package:mpc_mining_app/core/theme/app_theme.dart';
import 'package:mpc_mining_app/features/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpWelcome(WidgetTester tester, AppLanguage language) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final controller = LocaleController(prefs);
    await controller.setLanguage(language);

    await tester.pumpWidget(
      LocaleControllerScope.provide(
        controller: controller,
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const OnboardingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('welcome screen fits every language', () {
    const smallPhone = Size(320, 568);

    for (final language in AppLanguage.values) {
      testWidgets('${language.englishName} renders without overflow', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(smallPhone);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await pumpWelcome(tester, language);

        expect(
          tester.takeException(),
          isNull,
          reason:
              'onboarding overflows in ${language.englishName}. Shorten the '
              'copy or give the text block room; do not ship a clipped '
              'first screen.',
        );

        expect(
          find.text(
            AppStrings.get(language.locale.languageCode, 'onboard.create'),
          ),
          findsOneWidget,
        );
      });
    }
  });

  testWidgets('the language control reaches every shipped language', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpWelcome(tester, AppLanguage.en);

    await tester.tap(find.text(AppLanguage.en.shortCode));
    await tester.pumpAndSettle();

    for (final language in AppLanguage.values) {
      expect(
        find.text(language.nativeName),
        findsAtLeastNWidgets(1),
        reason: '${language.englishName} is missing from the picker',
      );
    }
  });
}
