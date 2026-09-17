import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mpc_mining_app/core/localization/app_strings.dart';
import 'package:mpc_mining_app/core/localization/locale_controller.dart';
import 'package:mpc_mining_app/core/state/view_state.dart';
import 'package:mpc_mining_app/core/theme/app_theme.dart';
import 'package:mpc_mining_app/core/utils/formatters.dart';
import 'package:mpc_mining_app/data/models/wallet_models.dart';
import 'package:mpc_mining_app/features/dashboard/widgets/dashboard_balance_hero.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const account = WalletAccount(
    address: '0x7A1f4C9d2E5b8A3f0C6d9E2b1A4f7C0d8E3b6A21',
    mpcBalance: 128450,
    network: 'BNB Smart Chain',
    bnbBalance: 0.0128,
    allocations: {'tsagaan-tolgoi': 96000},
    transactions: [],
  );

  Future<void> pumpHero(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final locale = LocaleController(prefs);
    await locale.setLanguage(AppLanguage.en);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(
            body: ShowCaseWidget(
              builder: (_) => DashboardBalanceHero(
                state: const ViewState.success(account),
                settingsKey: GlobalKey(),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/wallet',
          builder: (_, __) => const Scaffold(body: Text('wallet-screen')),
        ),
      ],
    );
    await tester.pumpWidget(
      LocaleControllerScope.provide(
        controller: locale,
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tapping the balance stays on the home screen', (tester) async {
    await pumpHero(tester);

    await tester.tap(find.text(Fmt.token(account.mpcBalance)));
    await tester.tap(find.text('Est. Total Value (MPC)'));
    await tester.pumpAndSettle();

    expect(find.text('wallet-screen'), findsNothing);
    expect(find.byType(DashboardBalanceHero), findsOneWidget);
  });

  testWidgets('the eye toggle hides and reveals the balance', (tester) async {
    await pumpHero(tester);
    final toggle = find.byKey(const Key('balance-visibility-toggle'));

    await tester.tapAt(tester.getTopLeft(toggle) + const Offset(1, 1));
    await tester.pumpAndSettle();
    expect(find.text('••••••'), findsOneWidget);
    expect(find.text('wallet-screen'), findsNothing);

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.text(Fmt.token(account.mpcBalance)), findsOneWidget);
  });
}
