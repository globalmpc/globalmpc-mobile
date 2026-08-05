import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpc_mining_app/core/localization/app_strings.dart';
import 'package:mpc_mining_app/core/localization/locale_controller.dart';
import 'package:mpc_mining_app/core/router/app_router.dart';
import 'package:mpc_mining_app/core/security/wallet_lock_controller.dart';
import 'package:mpc_mining_app/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End-to-end cover for the router guard wiring.
///
/// `AppRouter.redirectFor` is unit-tested on its own, but a correct decision
/// function wired up wrongly still ships a broken app: either an unguarded
/// wallet, or a redirect loop that traps the user on the unlock screen with no
/// way forward. These pump the real router.
void main() {
  late WalletLockController lock;

  Future<void> pumpAt(WidgetTester tester, String location) async {
    final prefs = await SharedPreferences.getInstance();
    final localeController = LocaleController(prefs);
    await localeController.setLanguage(AppLanguage.en);

    final router = AppRouter.create(initialLocation: location, lock: lock);
    await tester.pumpWidget(
      LocaleControllerScope.provide(
        controller: localeController,
        child: MaterialApp.router(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> startLock({required bool withWallet}) async {
    SharedPreferences.setMockInitialValues(
      withWallet ? {'wallet_configured_v1': true} : {},
    );
    lock = WalletLockController.forTesting();
    await lock.start();
  }

  tearDown(() => lock.dispose());

  testWidgets('a locked wallet cannot reach the wallet screen', (tester) async {
    await startLock(withWallet: true);

    await pumpAt(tester, '/wallet');

    // Landed on the unlock screen instead.
    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      find.text('Enter your device PIN to unlock your wallet.'),
      findsOneWidget,
    );
  });

  testWidgets('a locked wallet cannot reach settings', (tester) async {
    await startLock(withWallet: true);

    await pumpAt(tester, '/settings/recovery');

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('the unlock screen itself is reachable, not a loop', (
    tester,
  ) async {
    await startLock(withWallet: true);

    // If /unlock were itself guarded, the router would redirect forever and
    // pumpAndSettle would time out rather than reaching a frame.
    await pumpAt(tester, '/unlock');

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('import stays reachable so a forgotten PIN is recoverable', (
    tester,
  ) async {
    await startLock(withWallet: true);

    await pumpAt(tester, '/wallet/import');

    // Redirecting this to /unlock would strand a user who forgot their PIN,
    // since the phrase is the only way back in.
    expect(find.text('Welcome back'), findsNothing);
    expect(find.text('Restore your existing wallet'), findsOneWidget);
  });

  testWidgets('onboarding is untouched when no wallet exists', (tester) async {
    await startLock(withWallet: false);

    await pumpAt(tester, '/onboarding');

    expect(find.text('Welcome back'), findsNothing);
    expect(find.text('Import wallet'), findsOneWidget);
  });
}
