import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpc_mining_app/core/config/app_environment.dart';
import 'package:mpc_mining_app/core/constants/chain_config.dart';
import 'package:mpc_mining_app/core/localization/app_strings.dart';
import 'package:mpc_mining_app/core/localization/locale_controller.dart';
import 'package:mpc_mining_app/core/theme/app_theme.dart';
import 'package:mpc_mining_app/data/models/mining_project.dart';
import 'package:mpc_mining_app/data/models/wallet_models.dart';
import 'package:mpc_mining_app/data/repositories/mpc_repository.dart';
import 'package:mpc_mining_app/data/services/bsc_chain_service.dart';
import 'package:mpc_mining_app/features/wallet/wallet_provider.dart';
import 'package:mpc_mining_app/features/transfer/receive_screen.dart';
import 'package:mpc_mining_app/features/transfer/send_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';

/// Public BIP-39 reference phrase; it is a fixture, not a wallet.
const _fixturePhrase =
    'abandon abandon abandon abandon abandon abandon '
    'abandon abandon abandon abandon abandon about';

const _fixtureConfig = ChainConfig(
  chainId: 97,
  rpcUrl: 'https://rpc.example',
  explorerBase: 'https://explorer.example',
  networkLabel: 'BSC Testnet',
  mpcTokenAddress: '0x0000000000000000000000000000000000000001',
);

const _recipient = '0x1111111111111111111111111111111111111111';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      'wallet_configured_v1': 'true',
      'wallet_device_pin_v1': '123456',
      'wallet_biometrics_v1': 'false',
      'wallet_mnemonic_v1': _fixturePhrase,
    });
  });

  Future<void> pumpWalletScreen(
    WidgetTester tester,
    Widget child, {
    double bnbBalance = 0.0128,
    BscChainService? chain,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final provider = WalletProvider(
      _ImmediateWalletRepository(bnbBalance: bnbBalance),
    );
    provider.load();
    final prefs = await SharedPreferences.getInstance();
    final locale = LocaleController(prefs);
    await locale.setLanguage(AppLanguage.en);
    await tester.pumpWidget(
      LocaleControllerScope.provide(
        controller: locale,
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            Provider<BscChainService>.value(value: chain ?? _FakeChain()),
          ],
          child: MaterialApp(theme: AppTheme.light(), home: child),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> reachPin(WidgetTester tester) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), _recipient);
    await tester.enterText(fields.at(1), '100');
    await tester.tap(find.text('Review transaction'));
    await tester.pump();
    // The fee estimate resolves on the next frame; the confirm button stays
    // disabled until it does.
    await tester.pump();
    expect(find.text('~0.00012 BNB'), findsOneWidget);
    await tester.ensureVisible(find.text('Confirm and continue'));
    await tester.tap(find.text('Confirm and continue'));
    await tester.pump();
  }

  testWidgets('receive shows the active network, address and copy action', (
    tester,
  ) async {
    await pumpWalletScreen(tester, const ReceiveScreen());

    expect(find.text('Receive MPC'), findsOneWidget);
    expect(
      find.text(AppEnvironment.current.chain.networkLabel),
      findsOneWidget,
    );
    expect(find.text('Copy address'), findsOneWidget);
    expect(find.text('Share address'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
  });

  testWidgets('send blocks invalid address and unavailable balance', (
    tester,
  ) async {
    await pumpWalletScreen(tester, const SendScreen());

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'not-an-address');
    await tester.enterText(fields.at(1), '999999999');
    await tester.tap(find.text('Review transaction'));
    await tester.pump();

    expect(find.text('Enter a valid BNB Smart Chain address.'), findsOneWidget);
    expect(find.textContaining('unallocated MPC'), findsOneWidget);
  });

  testWidgets('send rejects a mixed-case address with a bad checksum', (
    tester,
  ) async {
    await pumpWalletScreen(tester, const SendScreen());

    final fields = find.byType(TextField);
    // Correct checksum of this address is 0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed.
    await tester.enterText(
      fields.at(0),
      '0x5aaeb6053F3E94C9b9A09f33669435E7Ef1BeAed',
    );
    await tester.enterText(fields.at(1), '100');
    await tester.tap(find.text('Review transaction'));
    await tester.pump();

    expect(find.textContaining('checksum'), findsOneWidget);
    expect(find.text("You're sending"), findsNothing);
  });

  testWidgets('send shows the estimated fee and blocks until it is known', (
    tester,
  ) async {
    final chain = _FakeChain(holdEstimate: true);
    await pumpWalletScreen(tester, const SendScreen(), chain: chain);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), _recipient);
    await tester.enterText(fields.at(1), '100');
    await tester.tap(find.text('Review transaction'));
    await tester.pump();

    expect(find.text("You're sending"), findsOneWidget);
    expect(find.text('Estimating fee…'), findsOneWidget);
    final confirm = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirm and continue'),
    );
    expect(confirm.onPressed, isNull);

    chain.releaseEstimate();
    await tester.pump();
    await tester.pump();
    expect(find.text('~0.00012 BNB'), findsOneWidget);
  });

  testWidgets('a broadcast send shows its hash and live chain status', (
    tester,
  ) async {
    final chain = _FakeChain();
    await pumpWalletScreen(tester, const SendScreen(), chain: chain);
    await reachPin(tester);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.tap(find.text('Send MPC'));
    await tester.pumpAndSettle();

    expect(find.text('Transaction Submitted'), findsOneWidget);
    expect(chain.sentTo, _recipient);
    expect(chain.sentAmount, 100);
    expect(find.textContaining('0xfeedface'), findsOneWidget);
    expect(find.text('View on block explorer'), findsOneWidget);
    expect(find.text('Confirmed on chain'), findsOneWidget);
  });

  testWidgets('a device without a stored key never shows a success screen', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({
      'wallet_configured_v1': 'true',
      'wallet_device_pin_v1': '123456',
      'wallet_biometrics_v1': 'false',
    });
    final chain = _FakeChain();
    await pumpWalletScreen(tester, const SendScreen(), chain: chain);
    await reachPin(tester);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.tap(find.text('Send MPC'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Transaction Submitted'), findsNothing);
    // Title bar and body both carry the failure heading.
    expect(find.text('Transaction not sent'), findsWidgets);
    expect(find.textContaining('No wallet key is stored'), findsOneWidget);
    expect(chain.sentTo, isNull);
  });

  testWidgets('send explains how to recover from insufficient BNB', (
    tester,
  ) async {
    await pumpWalletScreen(tester, const SendScreen(), bnbBalance: 0.00003);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), _recipient);
    await tester.enterText(fields.at(1), '100');
    await tester.tap(find.text('Review transaction'));
    await tester.pump();
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pump();
    await tester.ensureVisible(find.text('Confirm and continue'));
    await tester.tap(find.text('Confirm and continue'));
    await tester.pumpAndSettle();

    expect(find.text('BNB needed for network fee'), findsOneWidget);
    expect(find.text('Receive BNB'), findsOneWidget);
    expect(
      find.text('Your MPC balance will not be used for this fee.'),
      findsOneWidget,
    );
  });
}

/// Stand-in for the chain: prices every transfer at 0.00012 BNB, accepts
/// every send with a fixed hash, and reports it confirmed immediately.
class _FakeChain extends BscChainService {
  _FakeChain({this.holdEstimate = false}) : super(_fixtureConfig);

  final bool holdEstimate;
  String? sentTo;
  double? sentAmount;
  final _release = <void Function()>[];

  static final _estimate = FeeEstimate(
    gasLimit: BigInt.from(24000),
    gasPriceWei: BigInt.from(5000000000),
  );

  void releaseEstimate() {
    for (final release in _release) {
      release();
    }
    _release.clear();
  }

  @override
  Future<FeeEstimate> estimateTransferFee({
    required String from,
    required String to,
    required double amountMpc,
  }) async {
    if (!holdEstimate) return _estimate;
    final completer = Completer<FeeEstimate>();
    _release.add(() => completer.complete(_estimate));
    return completer.future;
  }

  @override
  Future<String> sendMpc({
    required EthPrivateKey credentials,
    required String to,
    required double amountMpc,
  }) async {
    sentTo = to;
    sentAmount = amountMpc;
    return '0xfeedface000000000000000000000000000000000000000000000000deadbeef';
  }

  @override
  Future<TxStatus> waitForReceipt(
    String hash, {
    Duration timeout = const Duration(seconds: 90),
    Duration interval = const Duration(seconds: 3),
  }) async => TxStatus.confirmed;
}

class _ImmediateWalletRepository implements MpcRepository {
  const _ImmediateWalletRepository({this.bnbBalance = 0.0128});

  final double bnbBalance;

  @override
  Future<WalletAccount> fetchWallet() async => WalletAccount(
    address: '0x7A1f4C9d2E5b8A3f0C6d9E2b1A4f7C0d8E3b6A21',
    mpcBalance: 128450,
    network: 'BSC Testnet',
    bnbBalance: bnbBalance,
    allocations: const {'tsagaan-tolgoi': 96000},
    transactions: const [],
  );

  @override
  Future<MiningProject?> fetchProject(String id) async => null;

  @override
  Future<List<MiningProject>> fetchProjects() async => const [];
}
