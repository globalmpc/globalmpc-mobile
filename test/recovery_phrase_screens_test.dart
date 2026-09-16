import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mpc_mining_app/core/localization/app_strings.dart';
import 'package:mpc_mining_app/core/localization/locale_controller.dart';
import 'package:mpc_mining_app/core/theme/app_theme.dart';
import 'package:mpc_mining_app/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const phrase =
      'legal winner thank year wave sausage worth useful legal winner thank '
      'yellow';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      'wallet_configured_v1': 'true',
      'wallet_device_pin_v1': '123456',
      'wallet_biometrics_v1': 'false',
      'wallet_mnemonic_v1': phrase,
    });
  });

  Future<void> pumpScreen(WidgetTester tester, Widget child) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final prefs = await SharedPreferences.getInstance();
    final locale = LocaleController(prefs);
    await locale.setLanguage(AppLanguage.en);
    await tester.pumpWidget(
      LocaleControllerScope.provide(
        controller: locale,
        child: MaterialApp(theme: AppTheme.light(), home: child),
      ),
    );
    await tester.pump();
  }

  Future<void> pumpOnRouter(WidgetTester tester, GoRouter router) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final prefs = await SharedPreferences.getInstance();
    final locale = LocaleController(prefs);
    await locale.setLanguage(AppLanguage.en);
    await tester.pumpWidget(
      LocaleControllerScope.provide(
        controller: locale,
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('reveal shows the stored mnemonic, never a static phrase', (
    tester,
  ) async {
    await pumpScreen(tester, const RecoveryAuthScreen());

    await tester.tap(find.text('Continue with PIN'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.tap(find.text('Verify PIN'));
    await tester.pumpAndSettle();

    expect(find.text('4. year'), findsOneWidget);
    expect(find.text('9. legal'), findsOneWidget);
    expect(find.text('12. yellow'), findsOneWidget);
    expect(find.textContaining('ledger'), findsNothing);
    expect(find.textContaining('orbit'), findsNothing);
    expect(find.textContaining('quartz'), findsNothing);
  });

  testWidgets('reveal with no stored mnemonic explains instead of faking', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({
      'wallet_configured_v1': 'true',
      'wallet_device_pin_v1': '123456',
    });
    await pumpScreen(tester, const RecoveryAuthScreen());

    await tester.tap(find.text('Continue with PIN'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.tap(find.text('Verify PIN'));
    await tester.pumpAndSettle();

    expect(
      find.text('No recovery phrase is stored on this device.'),
      findsOneWidget,
    );
    expect(find.text('4. year'), findsNothing);
  });

  testWidgets('verify backup asks for the PIN before any phrase word shows', (
    tester,
  ) async {
    await pumpScreen(tester, const VerifyBackupScreen());
    await tester.pumpAndSettle();

    expect(find.text('Word 4'), findsNothing);
    expect(find.textContaining('winner'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('verify backup quizzes three random typed positions', (
    tester,
  ) async {
    await pumpScreen(tester, const VerifyBackupScreen());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Reveal phrase'));
    await tester.pumpAndSettle();

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields.length, 3);
    final positions = fields
        .map(
          (f) =>
              int.parse(((f.key! as ValueKey<String>).value.split('-').last)),
        )
        .toSet();
    expect(positions.length, 3, reason: 'positions must be distinct');
    expect(positions.every((p) => p >= 1 && p <= 12), isTrue);
  });

  testWidgets('verify backup rejects words that are not from the phrase', (
    tester,
  ) async {
    await pumpScreen(tester, const VerifyBackupScreen());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Reveal phrase'));
    await tester.pumpAndSettle();

    for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
      await tester.enterText(find.byWidget(field), 'copper');
    }
    await tester.pump();

    await tester.tap(
      find.text('I stored the phrase somewhere private and offline.'),
    );
    await tester.pump();
    await tester.tap(find.text('Mark backup as verified'));
    await tester.pump();

    expect(
      find.text("Those words don't match your recovery phrase."),
      findsOneWidget,
    );
  });

  testWidgets('verify backup passes when the real words are typed', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/settings/recovery/verify',
      routes: [
        GoRoute(
          path: '/settings/recovery/verify',
          builder: (_, __) => const VerifyBackupScreen(),
        ),
        GoRoute(
          path: '/settings/recovery/verified',
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('VERIFIED-DONE'))),
        ),
      ],
    );
    await pumpOnRouter(tester, router);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Reveal phrase'));
    await tester.pumpAndSettle();

    final phraseWords = phrase.split(' ');
    for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
      final position = int.parse(
        ((field.key! as ValueKey<String>).value.split('-').last),
      );
      await tester.enterText(find.byWidget(field), phraseWords[position - 1]);
    }
    await tester.pump();

    await tester.tap(
      find.text('I stored the phrase somewhere private and offline.'),
    );
    await tester.pump();
    await tester.tap(find.text('Mark backup as verified'));
    await tester.pumpAndSettle();

    expect(find.text('VERIFIED-DONE'), findsOneWidget);
  });
}
