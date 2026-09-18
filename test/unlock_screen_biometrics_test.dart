import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mpc_mining_app/core/localization/app_strings.dart';
import 'package:mpc_mining_app/core/localization/locale_controller.dart';
import 'package:mpc_mining_app/core/security/biometric_auth.dart';
import 'package:mpc_mining_app/core/security/wallet_lock_controller.dart';
import 'package:mpc_mining_app/core/theme/app_theme.dart';
import 'package:mpc_mining_app/features/onboarding/unlock_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The unlock screen's biometric path, driven through a scripted platform:
/// the automatic prompt unlocks, refused access is explained rather than
/// misreported as "nothing enrolled", an empty enrolled list still gets a
/// prompt, and a prompt that never completes cannot block the user's next
/// attempt.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      'wallet_configured_v1': 'true',
      'wallet_device_pin_v1': '123456',
      'wallet_biometrics_v1': 'true',
    });
    WalletLockController.instance.lockNow();
  });

  Future<void> pumpUnlock(WidgetTester tester, BiometricAuth auth) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final prefs = await SharedPreferences.getInstance();
    final locale = LocaleController(prefs);
    await locale.setLanguage(AppLanguage.en);
    final router = GoRouter(
      initialLocation: '/unlock',
      routes: [
        GoRoute(
          path: '/unlock',
          builder: (_, __) => UnlockScreen(biometrics: auth),
        ),
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('home-marker')),
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
    await tester.pump();
  }

  /// Lets the post-frame lockout check and the auto-prompt delay elapse.
  Future<void> settleAutoPrompt(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('the automatic prompt unlocks the wallet on success', (
    tester,
  ) async {
    final platform = _ScriptedLocalAuth(outcomes: [true]);
    await pumpUnlock(tester, BiometricAuth(platform));
    await settleAutoPrompt(tester);
    await tester.pumpAndSettle();

    expect(platform.prompts, 1);
    expect(find.text('home-marker'), findsOneWidget);
    expect(WalletLockController.instance.isUnlocked, isTrue);
  });

  testWidgets('refused access is explained, not reported as unenrolled', (
    tester,
  ) async {
    // What iOS reports after the user tapped "Don't Allow": hardware exists,
    // the enrolled list is empty, and the prompt itself fails.
    final platform = _ScriptedLocalAuth(
      enrolled: const [],
      outcomes: [LocalAuthExceptionCode.noBiometricHardware],
    );
    await pumpUnlock(tester, BiometricAuth(platform));
    await settleAutoPrompt(tester);

    expect(platform.prompts, 1, reason: 'an empty list still gets a prompt');
    expect(find.textContaining('turned off'), findsOneWidget);
    expect(find.textContaining('enrol', findRichText: false), findsNothing);
    expect(find.text('home-marker'), findsNothing);
  });

  testWidgets('a genuinely unenrolled device gets the enrolment hint', (
    tester,
  ) async {
    final platform = _ScriptedLocalAuth(
      enrolled: const [],
      outcomes: [LocalAuthExceptionCode.noBiometricsEnrolled],
    );
    await pumpUnlock(tester, BiometricAuth(platform));
    await settleAutoPrompt(tester);

    expect(find.textContaining('Enrol a fingerprint or face'), findsOneWidget);
  });

  testWidgets('a hung prompt is cancelled when the user asks again', (
    tester,
  ) async {
    final platform = _ScriptedLocalAuth(outcomes: [null, true]);
    const promptTimeout = Duration(seconds: 5);
    await pumpUnlock(tester, BiometricAuth(platform, promptTimeout));
    await settleAutoPrompt(tester);
    expect(platform.prompts, 1);
    expect(find.text('home-marker'), findsNothing);

    await tester.tap(find.text('Use biometrics'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use biometrics').last);
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(platform.stopCalls, 1);
    expect(platform.prompts, 2);
    expect(find.text('home-marker'), findsOneWidget);

    // The abandoned first prompt still times out on its own; let it, so
    // nothing is left pending.
    await tester.pump(promptTimeout + const Duration(seconds: 1));
    await tester.pump();
  });

  testWidgets('a wallet without biometrics never prompts', (tester) async {
    FlutterSecureStorage.setMockInitialValues({
      'wallet_configured_v1': 'true',
      'wallet_device_pin_v1': '123456',
      'wallet_biometrics_v1': 'false',
    });
    final platform = _ScriptedLocalAuth(outcomes: [true]);
    await pumpUnlock(tester, BiometricAuth(platform));
    await settleAutoPrompt(tester);

    expect(platform.prompts, 0);
    expect(find.text('Welcome back'), findsOneWidget);
  });
}

/// Plays back one scripted outcome per prompt: `true`/`false` for the
/// platform's answer, a [LocalAuthExceptionCode] for a thrown error, or
/// `null` for a prompt that never completes.
class _ScriptedLocalAuth extends LocalAuthentication {
  _ScriptedLocalAuth({
    required this.outcomes,
    this.enrolled = const [BiometricType.strong],
  });

  final List<Object?> outcomes;
  final List<BiometricType> enrolled;
  int prompts = 0;
  int stopCalls = 0;

  @override
  Future<bool> get canCheckBiometrics async => true;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => enrolled;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<Object> authMessages = const <Object>[],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    final outcome = outcomes[prompts++];
    if (outcome == null) return Completer<bool>().future;
    if (outcome is LocalAuthExceptionCode) {
      throw LocalAuthException(code: outcome);
    }
    return outcome as bool;
  }

  @override
  Future<bool> stopAuthentication() async {
    stopCalls++;
    return true;
  }
}
