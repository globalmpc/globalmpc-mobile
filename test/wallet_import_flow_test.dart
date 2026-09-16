import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mpc_mining_app/core/localization/app_strings.dart';
import 'package:mpc_mining_app/core/localization/locale_controller.dart';
import 'package:mpc_mining_app/core/router/app_router.dart';
import 'package:mpc_mining_app/core/theme/app_theme.dart';
import 'package:mpc_mining_app/features/entry/entry_flow_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('welcome Import wallet button opens the import flow', (
    tester,
  ) async {
    final router = AppRouter.create(initialLocation: '/onboarding');
    await pumpLocalizedOnboarding(tester, router);
    await tester.pumpAndSettle();

    expect(find.text('Import wallet'), findsOneWidget);
    await tester.tap(find.text('Import wallet'));
    await tester.pumpAndSettle();

    expect(find.text('Restore your existing wallet'), findsOneWidget);
  });

  testWidgets('welcome Create wallet button opens a working create flow', (
    tester,
  ) async {
    final router = AppRouter.create(initialLocation: '/onboarding');
    await pumpLocalizedOnboarding(tester, router);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create wallet'));
    await tester.pumpAndSettle();
    expect(find.text('A wallet only you control'), findsOneWidget);

    await tester.tap(find.text('Create new wallet'));
    await tester.pumpAndSettle();
    expect(find.text('Back up your recovery phrase'), findsOneWidget);
  });

  testWidgets('import flow primary actions respond and advance', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/wallet/import',
      routes: [
        GoRoute(
          path: '/wallet/import',
          builder: (_, __) =>
              const WalletEntryFlowScreen(mode: WalletEntryMode.import),
        ),
      ],
    );

    await pumpLocalizedOnboarding(tester, router);
    await tester.pumpAndSettle();

    expect(find.text('Restore your existing wallet'), findsOneWidget);
    await tester.tap(find.text('I understand'));
    await tester.pumpAndSettle();

    expect(find.text('Enter recovery phrase'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'random pasted design words',
    );
    await tester.pump();
    await tester.tap(find.text('Review wallet'));
    await tester.pumpAndSettle();
    expect(find.textContaining('not valid'), findsOneWidget);
    expect(find.text('This is my wallet'), findsNothing);

    await tester.enterText(
      find.byType(TextField),
      'test test test test test test test test test test test junk',
    );
    await tester.pump();
    await tester.tap(find.text('Review wallet'));
    await tester.pumpAndSettle();

    expect(find.text('This is my wallet'), findsOneWidget);
    expect(
      find.text('0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'),
      findsOneWidget,
    );
  });

  testWidgets('returning user route shows Welcome Back PIN unlock', (
    tester,
  ) async {
    final router = AppRouter.create(initialLocation: '/unlock');
    await pumpLocalizedOnboarding(tester, router);
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Unlock wallet'), findsOneWidget);
    expect(find.text('Use biometrics'), findsOneWidget);
    expect(find.text('Forgot PIN? Restore wallet'), findsOneWidget);
  });

  testWidgets('Finish setup securely saves and reaches wallet-created state', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/wallet/create',
      routes: [
        GoRoute(
          path: '/wallet/create',
          builder: (_, __) =>
              const WalletEntryFlowScreen(mode: WalletEntryMode.create),
        ),
      ],
    );

    await pumpLocalizedOnboarding(tester, router);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create new wallet'));
    await tester.pumpAndSettle();

    final words = <int, String>{};
    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      final match = RegExp(r'^(\d+)\.\s+([a-z]+)$').firstMatch(text.data ?? '');
      if (match != null) words[int.parse(match.group(1)!)] = match.group(2)!;
    }
    expect(words.length, 12);

    await tester.tap(find.text('I saved these words'));
    await tester.pumpAndSettle();

    final requested = <int>[];
    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      final match = RegExp(r'^Word #(\d+)$').firstMatch(text.data ?? '');
      if (match != null) requested.add(int.parse(match.group(1)!));
    }
    expect(requested.length, 3);

    await tester.enterText(
      find.byKey(ValueKey('verify-word-${requested.first}')),
      'xxxxxx',
    );
    for (final n in requested.skip(1)) {
      await tester.enterText(find.byKey(ValueKey('verify-word-$n')), words[n]!);
    }
    await tester.pump();
    await tester.tap(find.text('Verify backup'));
    await tester.pumpAndSettle();
    expect(find.textContaining("didn't match"), findsOneWidget);
    expect(find.text('Create an app PIN'), findsNothing);

    final retryRequested = <int>[];
    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      final match = RegExp(r'^Word #(\d+)$').firstMatch(text.data ?? '');
      if (match != null) retryRequested.add(int.parse(match.group(1)!));
    }
    expect(retryRequested.length, 3);
    for (final n in retryRequested) {
      await tester.enterText(find.byKey(ValueKey('verify-word-$n')), words[n]!);
    }
    await tester.pump();
    await tester.tap(find.text('Verify backup'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.tap(find.text('Confirm PIN'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Finish setup'));
    await tester.pumpAndSettle();

    expect(find.text('Wallet created'), findsOneWidget);
  });
}

Future<void> pumpLocalizedOnboarding(
  WidgetTester tester,
  GoRouter router,
) async {
  final prefs = await SharedPreferences.getInstance();
  final localeController = LocaleController(prefs);
  await localeController.setLanguage(AppLanguage.en);

  await tester.pumpWidget(
    LocaleControllerScope.provide(
      controller: localeController,
      child: MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
    ),
  );
}
