import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpc_mining_app/core/localization/app_strings.dart';
import 'package:mpc_mining_app/core/localization/locale_controller.dart';
import 'package:mpc_mining_app/core/router/app_router.dart';
import 'package:mpc_mining_app/core/theme/app_theme.dart';
import 'package:mpc_mining_app/core/theme/theme_controller.dart';
import 'package:mpc_mining_app/data/repositories/mock_mpc_repository.dart';
import 'package:mpc_mining_app/features/wallet/wallet_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression: the remove-wallet dialog used to dispose its confirmation
/// controller as soon as `showDialog` returned, while the dismiss animation
/// was still rebuilding the dialog. On device that surfaced as
/// "A TextEditingController was used after being disposed", followed by a
/// ~99,000px RenderFlex overflow and a duplicate-GlobalKey cascade.
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

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final prefs = await SharedPreferences.getInstance();
    final locale = LocaleController(prefs);
    await locale.setLanguage(AppLanguage.en);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
            value: WalletProvider(const MockMpcRepository())..load(),
          ),
          ChangeNotifierProvider.value(value: ThemeController(prefs)),
        ],
        child: LocaleControllerScope.provide(
          controller: locale,
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: AppRouter.create(initialLocation: '/settings'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openRemoveDialog(WidgetTester tester) async {
    final button = find.text('Remove wallet from this device');
    await tester.scrollUntilVisible(
      button,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Remove wallet?'), findsOneWidget);
  }

  testWidgets('confirming removal dismisses cleanly', (tester) async {
    await pumpSettings(tester);
    await openRemoveDialog(tester);

    await tester.enterText(find.byType(TextField).last, 'REMOVE');
    await tester.pump();
    await tester.tap(find.text('Remove from device'));

    // Pump *through* the dismiss animation: the old defect only surfaced
    // in the frames after the pop resolved.
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling removal dismisses cleanly', (tester) async {
    await pumpSettings(tester);
    await openRemoveDialog(tester);

    await tester.enterText(find.byType(TextField).last, 'REMO');
    await tester.pump();
    await tester.tap(find.text('Keep wallet'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Remove wallet?'), findsNothing);
  });

  testWidgets('removal stays blocked until REMOVE is typed exactly', (
    tester,
  ) async {
    await pumpSettings(tester);
    await openRemoveDialog(tester);

    FilledButton confirmButton() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Remove from device'),
    );

    expect(confirmButton().onPressed, isNull);

    await tester.enterText(find.byType(TextField).last, 'remove');
    await tester.pump();
    expect(confirmButton().onPressed, isNull);

    await tester.enterText(find.byType(TextField).last, 'REMOVE');
    await tester.pump();
    expect(confirmButton().onPressed, isNotNull);
  });
}
