import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpc_mining_app/core/localization/locale_controller.dart';
import 'package:mpc_mining_app/features/onboarding/widgets/unlock_pin_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('hiding the language selector does not refocus the PIN field', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final controller = LocaleController(prefs);
    final pin = TextEditingController();
    addTearDown(pin.dispose);

    Widget panel({required bool showLanguageSelector}) =>
        LocaleControllerScope.provide(
          controller: controller,
          child: MaterialApp(
            home: UnlockPinPanel(
              pinController: pin,
              busy: false,
              error: null,
              onPinChanged: () {},
              onUnlock: () {},
              onRestore: () {},
              onShowBiometrics: () {},
              onCreateWallet: () {},
              showLanguageSelector: showLanguageSelector,
            ),
          ),
        );

    await tester.pumpWidget(panel(showLanguageSelector: true));
    await tester.pump();
    final fieldState = tester.state(find.byType(EditableText));
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    await tester.pumpWidget(panel(showLanguageSelector: false));
    await tester.pump();

    expect(tester.state(find.byType(EditableText)), same(fieldState));
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isFalse,
    );
  });

  testWidgets('unlock actions stay above the open keyboard', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const keyboardHeight = 300.0;
    const screen = Size(390, 844);
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: keyboardHeight);
    addTearDown(tester.view.reset);

    final pin = TextEditingController(text: '123456');
    addTearDown(pin.dispose);
    var unlocked = 0;
    var created = 0;

    await tester.pumpWidget(
      LocaleControllerScope.provide(
        controller: LocaleController(prefs),
        child: MaterialApp(
          home: UnlockPinPanel(
            pinController: pin,
            busy: false,
            error: null,
            onPinChanged: () {},
            onUnlock: () => unlocked++,
            onRestore: () {},
            onShowBiometrics: () {},
            onCreateWallet: () => created++,
            showLanguageSelector: false,
          ),
        ),
      ),
    );
    await tester.pump();

    final keyboardTop = screen.height - keyboardHeight;
    final unlockButton = find.byType(FilledButton);
    final createLink = find.text('Create wallet');
    expect(tester.getRect(unlockButton).bottom, lessThanOrEqualTo(keyboardTop));
    expect(tester.getRect(createLink).bottom, lessThanOrEqualTo(keyboardTop));

    await tester.tap(unlockButton);
    await tester.tap(createLink);
    expect(unlocked, 1);
    expect(created, 1);
  });
}
