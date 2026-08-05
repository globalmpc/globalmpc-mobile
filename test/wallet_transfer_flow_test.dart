import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpc_mining_app/core/theme/app_theme.dart';
import 'package:mpc_mining_app/data/models/mining_project.dart';
import 'package:mpc_mining_app/data/models/wallet_models.dart';
import 'package:mpc_mining_app/data/repositories/mpc_repository.dart';
import 'package:mpc_mining_app/features/wallet/wallet_provider.dart';
import 'package:mpc_mining_app/features/wallet/wallet_transfer_screens.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'wallet_configured_v1': true,
      'wallet_device_pin_v1': '123456',
      'wallet_biometrics_v1': false,
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  Future<void> pumpWalletScreen(WidgetTester tester, Widget child) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final provider = WalletProvider(const _ImmediateWalletRepository());
    provider.load();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(theme: AppTheme.light(), home: child),
      ),
    );
    await tester.pump();
  }

  testWidgets('receive shows the network, address and copy action', (
    tester,
  ) async {
    await pumpWalletScreen(tester, const ReceiveScreen());

    expect(find.text('Receive MPC'), findsOneWidget);
    expect(find.text('BNB Smart Chain'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
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
    expect(
      find.text('You do not have enough unallocated MPC.'),
      findsOneWidget,
    );
  });

  testWidgets('send advances through review, PIN and success', (tester) async {
    await pumpWalletScreen(tester, const SendScreen());

    final fields = find.byType(TextField);
    await tester.enterText(
      fields.at(0),
      '0x1111111111111111111111111111111111111111',
    );
    await tester.enterText(fields.at(1), '100');
    await tester.tap(find.text('Review transaction'));
    await tester.pump();

    expect(find.text("You're sending"), findsOneWidget);
    expect(find.text('100 MPC'), findsOneWidget);

    await tester.ensureVisible(find.text('Confirm and continue'));
    await tester.tap(find.text('Confirm and continue'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.tap(find.text('Send MPC'));
    await tester.pump();

    expect(find.text('Submitting securely'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();
    expect(find.text('Transaction submitted'), findsOneWidget);
    expect(find.text('Pending confirmation'), findsOneWidget);
  });

  testWidgets('send explains how to recover from insufficient BNB', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final provider = WalletProvider(
      const _ImmediateWalletRepository(bnbBalance: 0.00003),
    );
    provider.load();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(theme: AppTheme.light(), home: const SendScreen()),
      ),
    );
    await tester.pump();

    final fields = find.byType(TextField);
    await tester.enterText(
      fields.at(0),
      '0x1111111111111111111111111111111111111111',
    );
    await tester.enterText(fields.at(1), '100');
    await tester.tap(find.text('Review transaction'));
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

class _ImmediateWalletRepository implements MpcRepository {
  const _ImmediateWalletRepository({this.bnbBalance = 0.0128});

  final double bnbBalance;

  @override
  Future<WalletAccount> fetchWallet() async => WalletAccount(
    address: '0x7A1f4C9d2E5b8A3f0C6d9E2b1A4f7C0d8E3b6A21',
    mpcBalance: 128450,
    network: 'BNB Smart Chain',
    bnbBalance: bnbBalance,
    allocations: const {'tsagaan-tolgoi': 96000},
    transactions: const [],
  );

  @override
  Future<MiningProject?> fetchProject(String id) async => null;

  @override
  Future<List<MiningProject>> fetchProjects() async => const [];
}
