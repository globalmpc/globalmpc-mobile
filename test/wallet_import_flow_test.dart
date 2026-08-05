import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mpc_mining_app/core/localization/app_strings.dart';
import 'package:mpc_mining_app/core/localization/locale_controller.dart';
import 'package:mpc_mining_app/core/router/app_router.dart';
import 'package:mpc_mining_app/core/theme/app_theme.dart';
import 'package:mpc_mining_app/features/wallet/wallet_entry_flow_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
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

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
    );
    await tester.pumpAndSettle();

    expect(find.text('Restore your existing wallet'), findsOneWidget);
    await tester.tap(find.text('I understand'));
    await tester.pumpAndSettle();

    expect(find.text('Enter recovery phrase'), findsOneWidget);

    // Invalid phrase: blocked with a message, never advances (spec T7).
    await tester.enterText(
      find.byType(TextField),
      'random pasted design words',
    );
    await tester.pump();
    await tester.tap(find.text('Review wallet'));
    await tester.pumpAndSettle();
    expect(find.textContaining('not valid'), findsOneWidget);
    expect(find.text('This is my wallet'), findsNothing);

    // Valid phrase: advances and shows the address MetaMask would derive
    // from the same words (spec T2).
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

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
    );
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

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create new wallet'));
    await tester.pumpAndSettle();

    // The phrase is random per run: scrape it off the backup grid so the
    // verify step can be answered with the real words.
    final words = <int, String>{};
    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      final match = RegExp(r'^(\d+)\.\s+([a-z]+)$').firstMatch(text.data ?? '');
      if (match != null) words[int.parse(match.group(1)!)] = match.group(2)!;
    }
    expect(words.length, 12);

    await tester.tap(find.text('I saved these words'));
    await tester.pumpAndSettle();

    // Verification asks for three random positions, typed not selected.
    final requested = <int>[];
    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      final match = RegExp(r'^Word #(\d+)$').firstMatch(text.data ?? '');
      if (match != null) requested.add(int.parse(match.group(1)!));
    }
    expect(requested.length, 3);

    // A wrong word blocks the flow ('xxxxxx' is not a BIP-39 word)…
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
    expect(find.textContaining('does not match'), findsOneWidget);
    expect(find.text('Create an app PIN'), findsNothing);

    // …the real words advance to PIN setup.
    await tester.enterText(
      find.byKey(ValueKey('verify-word-${requested.first}')),
      words[requested.first]!,
    );
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
