import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpc_mining_app/core/constants/chain_config.dart';
import 'package:mpc_mining_app/core/localization/app_strings.dart';
import 'package:mpc_mining_app/core/localization/locale_controller.dart';
import 'package:mpc_mining_app/core/theme/app_theme.dart';
import 'package:mpc_mining_app/data/models/wallet_models.dart';
import 'package:mpc_mining_app/data/repositories/mpc_repository.dart';
import 'package:mpc_mining_app/data/models/mining_project.dart';
import 'package:mpc_mining_app/data/services/registry_anchor_service.dart';
import 'package:mpc_mining_app/features/dashboard/widgets/dashboard_token_card.dart';
import 'package:mpc_mining_app/features/earn/earn_screen.dart';
import 'package:mpc_mining_app/features/presale/presale_card.dart';
import 'package:mpc_mining_app/features/projects/widgets/project_detail_cards.dart';
import 'package:mpc_mining_app/features/registry/registry_provider.dart';
import 'package:mpc_mining_app/features/registry/registry_screen.dart';
import 'package:mpc_mining_app/features/registry/widgets/dashboard_registry_card.dart';
import 'package:mpc_mining_app/features/settings/about_settings_screen.dart';
import 'package:mpc_mining_app/features/settings/network_settings_screen.dart';
import 'package:mpc_mining_app/features/settings/security_settings_screen.dart';
import 'package:mpc_mining_app/features/settings/support_settings_screen.dart';
import 'package:mpc_mining_app/features/transfer/send_result_step.dart';
import 'package:mpc_mining_app/features/transfer/send_review_step.dart';
import 'package:mpc_mining_app/features/wallet/wallet_provider.dart';
import 'package:mpc_mining_app/features/wallet/wallet_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Renders every screen touched by the environment and registry work at the
/// smallest supported phone size with enlarged text, in every shipped
/// language and both themes. A RenderFlex overflow surfaces as a test
/// exception, so a clipped layout fails here rather than on a user's phone.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const smallPhone = Size(320, 568);
  const bigText = TextScaler.linear(1.3);

  final feed = RegistryFeed(
    batchCount: 1234,
    latest: [
      for (var i = 0; i < 3; i++)
        RegistryBatch(
          batchId: '0x${'ab'.padLeft(64, '0')}$i',
          root: '0x${'cd'.padLeft(64, '1')}',
          manifestHash: '0x${'ef'.padLeft(64, '2')}',
          recordCount: 987654,
          submittedAt: DateTime.utc(2026, 9, 17, 12 + i),
          revoked: i == 1,
          supersededBy: i == 2 ? '0x${'ab'.padLeft(64, '0')}1' : null,
        ),
    ],
  );

  final account = WalletAccount(
    address: '0x7A1f4C9d2E5b8A3f0C6d9E2b1A4f7C0d8E3b6A21',
    mpcBalance: 123456789.1234,
    network: 'BSC Testnet',
    bnbBalance: 0.0128,
    allocations: const {'tsagaan-tolgoi': 96000},
    transactions: const [],
    historyUnavailable: true,
  );

  final subjects = <String, Widget Function()>{
    'registry screen with batches': () => RegistryScreen(key: UniqueKey()),
    'registry card': () => Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [DashboardRegistryCard()],
      ),
    ),
    'token card': () => Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [DashboardTokenHeroCard()],
      ),
    ),
    'project token card': () => Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [ProjectContractCard()],
      ),
    ),
    'presale card': () => Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [PresaleCard(url: 'https://presale.example')],
      ),
    ),
    'send success with hash': () => Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SendResultStep(
            success: true,
            amount: 123456789.1234,
            recipientAddress: '0x1111111111111111111111111111111111111111',
            networkLabel: 'BNB Smart Chain',
            txHash: '0x${'f'.padLeft(64, 'f')}',
            txStatus: TxStatus.confirmed,
            explorerUrl: 'https://explorer.example/tx/0x',
          ),
        ),
      ),
    ),
    'send failure with reason': () => Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SendResultStep(
            success: false,
            amount: 100,
            recipientAddress: '0x1111111111111111111111111111111111111111',
            networkLabel: 'BNB Smart Chain',
            failureMessage: 'x' * 120,
            onRetry: () {},
          ),
        ),
      ),
    ),
    'send review estimating': () => Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SendReviewStep(
            amount: 123456789.1234,
            recipientAddress: '0x1111111111111111111111111111111111111111',
            bnbBalance: 0,
            networkFee: null,
            feeUnavailable: false,
            networkLabel: 'BNB Smart Chain',
            onRetryFee: () {},
            onConfirm: () {},
            onEdit: () {},
          ),
        ),
      ),
    ),
    'send review fee unavailable': () => Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SendReviewStep(
            amount: 100,
            recipientAddress: '0x1111111111111111111111111111111111111111',
            bnbBalance: 0,
            networkFee: null,
            feeUnavailable: true,
            networkLabel: 'BNB Smart Chain',
            onRetryFee: () {},
            onConfirm: () {},
            onEdit: () {},
          ),
        ),
      ),
    ),
    'send review not enough bnb': () => Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SendReviewStep(
            amount: 100,
            recipientAddress: '0x1111111111111111111111111111111111111111',
            bnbBalance: 0,
            networkFee: 0.00012,
            feeUnavailable: false,
            networkLabel: 'BNB Smart Chain',
            onRetryFee: () {},
            onConfirm: () {},
            onEdit: () {},
          ),
        ),
      ),
    ),
    'network settings': () => const NetworkSettingsScreen(),
    'security settings': () => const SecuritySettingsScreen(),
    'support settings': () => const SupportSettingsScreen(),
    'about': () => const AboutSettingsScreen(),
    'legal': () => const LegalSettingsScreen(),
    'earn': () => const EarnScreen(),
    'wallet with history unavailable': () => const WalletScreen(),
  };

  for (final language in AppLanguage.values) {
    for (final dark in [false, true]) {
      for (final entry in subjects.entries) {
        testWidgets(
          '${entry.key} fits ${language.englishName} ${dark ? 'dark' : 'light'}',
          (tester) async {
            await tester.binding.setSurfaceSize(smallPhone);
            addTearDown(() => tester.binding.setSurfaceSize(null));
            SharedPreferences.setMockInitialValues({});
            final prefs = await SharedPreferences.getInstance();
            final locale = LocaleController(prefs);
            await locale.setLanguage(language);

            final registry = RegistryProvider(_FeedService(feed));
            await registry.load();
            final wallet = WalletProvider(_AccountRepository(account));
            await wallet.load();

            await tester.pumpWidget(
              LocaleControllerScope.provide(
                controller: locale,
                child: MultiProvider(
                  providers: [
                    ChangeNotifierProvider.value(value: registry),
                    ChangeNotifierProvider.value(value: wallet),
                  ],
                  child: MaterialApp(
                    theme: dark ? AppTheme.dark() : AppTheme.light(),
                    builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(textScaler: bigText),
                      child: child!,
                    ),
                    home: entry.value(),
                  ),
                ),
              ),
            );
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));

            final exception = tester.takeException();
            expect(
              exception,
              isNull,
              reason:
                  '${entry.key} overflows in ${language.englishName}. Give '
                  'the text room; do not ship a clipped screen.\n'
                  '${exception is FlutterError ? exception.toStringDeep() : exception}',
            );
          },
        );
      }
    }
  }

  testWidgets('registry screen states render without overflow', (tester) async {
    await tester.binding.setSurfaceSize(smallPhone);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final locale = LocaleController(prefs);
    await locale.setLanguage(AppLanguage.mn);

    for (final provider in [
      RegistryProvider(null),
      RegistryProvider(
        _FeedService(const RegistryFeed(batchCount: 0, latest: [])),
      ),
      RegistryProvider(_FeedService(null)),
    ]) {
      await provider.load();
      await tester.pumpWidget(
        LocaleControllerScope.provide(
          controller: locale,
          child: ChangeNotifierProvider.value(
            value: provider,
            child: MaterialApp(
              theme: AppTheme.light(),
              home: RegistryScreen(key: UniqueKey()),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });
}

/// Serves a fixed feed, or fails when given none.
class _FeedService extends RegistryAnchorService {
  _FeedService(this.feed)
    : super(
        config: ChainConfig.bscTestnet,
        anchorAddress: '0x0000000000000000000000000000000000000002',
      );

  final RegistryFeed? feed;

  @override
  Future<RegistryFeed> fetchLatest() async {
    final result = feed;
    if (result == null) throw StateError('unreachable');
    return result;
  }
}

class _AccountRepository implements MpcRepository {
  const _AccountRepository(this.account);

  final WalletAccount account;

  @override
  Future<WalletAccount> fetchWallet() async => account;

  @override
  Future<MiningProject?> fetchProject(String id) async => null;

  @override
  Future<List<MiningProject>> fetchProjects() async => const [];
}
