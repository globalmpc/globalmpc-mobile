import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpc_mining_app/core/localization/app_strings.dart';
import 'package:mpc_mining_app/core/localization/locale_controller.dart';
import 'package:mpc_mining_app/core/theme/app_theme.dart';
import 'package:mpc_mining_app/features/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The welcome screen is the first surface a user sees, and its copy changes
/// length with the selected language.
///
/// 1. It must render without overflow in every supported language on the
///    smallest device we support.
/// 2. The language control must offer every shipped language, not a subset.
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
    // iPhone SE / small Android: the tightest vertical budget we ship to.
    const smallPhone = Size(320, 568);

    for (final language in AppLanguage.values) {
      testWidgets('${language.englishName} renders without overflow', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(smallPhone);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await pumpWelcome(tester, language);

        // A RenderFlex overflow is reported as a FlutterError during paint,
        // which `pumpWidget` surfaces through takeException.
        expect(
          tester.takeException(),
          isNull,
          reason:
              'onboarding overflows in ${language.englishName}. Shorten the '
              'copy or give the text block room; do not ship a clipped '
              'first screen.',
        );

        // The copy is actually localized, not falling through to a key.
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

    await tester.tap(find.byIcon(Icons.language_rounded));
    await tester.pumpAndSettle();

    for (final language in AppLanguage.values) {
      // English renders its native and English name identically, so the tile
      // legitimately carries the same text twice.
      expect(
        find.text(language.nativeName),
        findsAtLeastNWidgets(1),
        reason: '${language.englishName} is missing from the picker',
      );
    }
  });
}
