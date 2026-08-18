import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpc_mining_app/core/router/app_router.dart';
import 'package:mpc_mining_app/core/security/wallet_lock_controller.dart';

/// Session auto-lock. Without this, one PIN entry left the wallet open until
/// the process died, so a phone picked up hours later was still a live wallet.
///
/// The two failure modes that matter are opposites, and both are covered here:
/// locking too late (the wallet stays open after the user walks away) and
/// locking too eagerly (the biometric prompt backgrounds the app, so the user
/// is bounced back to the unlock screen they just cleared).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const timeout = Duration(minutes: 2);

  late DateTime now;
  late WalletLockController lock;

  Future<WalletLockController> startedController({
    required bool withWallet,
  }) async {
    FlutterSecureStorage.setMockInitialValues(
      withWallet ? {'wallet_configured_v1': 'true'} : {},
    );
    final controller = WalletLockController.forTesting(
      clock: () => now,
      lockTimeout: timeout,
    );
    await controller.start();
    return controller;
  }

  void background() =>
      lock.didChangeAppLifecycleState(AppLifecycleState.paused);
  void foreground() =>
      lock.didChangeAppLifecycleState(AppLifecycleState.resumed);

  setUp(() => now = DateTime(2026, 8, 4, 12));

  tearDown(() => lock.dispose());

  group('startup', () {
    test('does not gate before start() resolves', () {
      lock = WalletLockController.forTesting(clock: () => now);

      // The router must not redirect on half-initialised state during launch.
      expect(lock.isReady, isFalse);
      expect(lock.requiresUnlock, isFalse);
    });

    test('a configured wallet starts locked', () async {
      lock = await startedController(withWallet: true);

      expect(lock.hasWallet, isTrue);
      expect(lock.isUnlocked, isFalse);
      expect(lock.requiresUnlock, isTrue);
    });

    test('no wallet means nothing to gate', () async {
      lock = await startedController(withWallet: false);

      expect(lock.hasWallet, isFalse);
      expect(lock.requiresUnlock, isFalse);
    });
  });

  group('locking on background', () {
    setUp(() async => lock = await startedController(withWallet: true));

    test('locks after being away longer than the timeout', () async {
      lock.markUnlocked();

      background();
      now = now.add(timeout).add(const Duration(seconds: 1));
      foreground();

      expect(lock.isUnlocked, isFalse);
      expect(lock.requiresUnlock, isTrue);
    });

    test('stays unlocked for a brief switch away', () async {
      lock.markUnlocked();

      background();
      now = now.add(const Duration(seconds: 20));
      foreground();

      // Copying an address out of another app must not cost a re-auth.
      expect(lock.isUnlocked, isTrue);
    });

    test('ignores inactive and hidden, which fire while still in use', () {
      lock.markUnlocked();

      // The app switcher, Control Center and the notification shade all emit
      // these. Locking on them would fire constantly, phone still in hand.
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
      ]) {
        lock.didChangeAppLifecycleState(state);
        now = now.add(const Duration(minutes: 10));
        lock.didChangeAppLifecycleState(AppLifecycleState.resumed);
        expect(lock.isUnlocked, isTrue, reason: '$state must not lock');
      }
    });

    test('measures from when the app was left, not from the first pause', () {
      lock.markUnlocked();

      // A repeated pause without an intervening resume must not restart the
      // clock, or a device that emits several pause events never locks.
      background();
      now = now.add(const Duration(minutes: 1));
      background();
      now = now.add(const Duration(minutes: 1, seconds: 1));
      foreground();

      expect(lock.isUnlocked, isFalse);
    });

    test('a resume with no preceding pause does nothing', () {
      lock.markUnlocked();

      foreground();

      expect(lock.isUnlocked, isTrue);
    });
  });

  group('system prompts', () {
    setUp(() async => lock = await startedController(withWallet: true));

    test('a biometric prompt does not count as leaving the app', () async {
      lock.markUnlocked();

      // Reproduces the unlock loop: the OS dialog backgrounds the app, and a
      // slow user drifts past the timeout while it is still on screen.
      await lock.runSystemPrompt(() async {
        background();
        now = now.add(timeout).add(const Duration(seconds: 30));
        foreground();
        return true;
      });

      expect(lock.isUnlocked, isTrue);
    });

    test('a pause after the prompt closes still locks', () async {
      lock.markUnlocked();
      await lock.runSystemPrompt(() async => true);

      background();
      now = now.add(timeout).add(const Duration(seconds: 1));
      foreground();

      expect(lock.isUnlocked, isFalse);
    });

    test('suppression unwinds even when the prompt throws', () async {
      lock.markUnlocked();

      await expectLater(
        lock.runSystemPrompt<bool>(() async => throw StateError('cancelled')),
        throwsStateError,
      );

      // A cancelled prompt must not leave locking disabled for good.
      background();
      now = now.add(timeout).add(const Duration(seconds: 1));
      foreground();
      expect(lock.isUnlocked, isFalse);
    });
  });

  group('state transitions', () {
    setUp(() async => lock = await startedController(withWallet: true));

    test('unlocking clears the gate and notifies', () {
      var notifications = 0;
      lock.addListener(() => notifications++);

      lock.markUnlocked();

      expect(lock.requiresUnlock, isFalse);
      expect(notifications, 1);
    });

    test('a created wallet starts unlocked', () async {
      lock = await startedController(withWallet: false);

      lock.markWalletCreated();

      expect(lock.hasWallet, isTrue);
      expect(lock.requiresUnlock, isFalse);
    });

    test('clearing the wallet removes the gate entirely', () {
      lock.markUnlocked();

      lock.markWalletCleared();

      // Nothing left to guard, so onboarding must not be redirected away.
      expect(lock.hasWallet, isFalse);
      expect(lock.requiresUnlock, isFalse);
    });

    test('lockNow re-gates immediately', () {
      lock.markUnlocked();

      lock.lockNow();

      expect(lock.requiresUnlock, isTrue);
    });

    test('repeat calls do not spam listeners', () {
      lock.markUnlocked();
      var notifications = 0;
      lock.addListener(() => notifications++);

      lock.markUnlocked();
      lock.markUnlocked();

      expect(notifications, 0);
    });
  });

  group('router guard', () {
    setUp(() async => lock = await startedController(withWallet: true));

    test('sends guarded routes to unlock while locked', () {
      for (final route in [
        '/',
        '/wallet',
        '/wallet/send',
        '/wallet/receive',
        '/settings',
        '/settings/recovery',
        '/settings/change-pin',
        '/profile',
        '/earn',
        '/projects',
        '/webview',
      ]) {
        expect(
          AppRouter.redirectFor(lock, route),
          '/unlock',
          reason: '$route exposes wallet state and must be gated',
        );
      }
    });

    test('leaves the unlock and recovery routes reachable', () {
      // Locking a user out of these would make a forgotten PIN unrecoverable.
      for (final route in AppRouter.unlockExemptRoutes) {
        expect(AppRouter.redirectFor(lock, route), isNull, reason: route);
      }
    });

    test('stops redirecting once unlocked', () {
      lock.markUnlocked();

      expect(AppRouter.redirectFor(lock, '/wallet'), isNull);
      expect(AppRouter.redirectFor(lock, '/settings/recovery'), isNull);
    });

    test('does not gate when no wallet exists', () async {
      lock = await startedController(withWallet: false);

      expect(AppRouter.redirectFor(lock, '/wallet'), isNull);
    });

    test('re-gates after an auto-lock', () {
      lock.markUnlocked();
      expect(AppRouter.redirectFor(lock, '/wallet'), isNull);

      background();
      now = now.add(timeout).add(const Duration(seconds: 1));
      foreground();

      expect(AppRouter.redirectFor(lock, '/wallet'), '/unlock');
    });
  });
}
