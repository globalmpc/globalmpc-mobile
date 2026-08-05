import 'package:flutter_test/flutter_test.dart';
import 'package:mpc_mining_app/core/security/pin_credential.dart';
import 'package:mpc_mining_app/core/security/wallet_session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device PIN handling: how it is stored, and how many guesses an attacker
/// holding the phone gets. Six digits is only 10^6 combinations and the unlock
/// screen submits on the sixth digit, so the lockout is the control that makes
/// a stolen device survivable.
///
/// These run against the macOS SharedPreferences tier, which is also the tier
/// where a stored PIN would be sitting in a plain file.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const correctPin = '123456';
  const wrongPin = '000000';

  late DateTime now;
  late WalletSessionStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 8, 4, 12);
    store = WalletSessionStore.forTesting(
      clock: () => now,
      pinIterations: 1000,
    );
  });

  Future<String?> storedPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('wallet_device_pin_v1');
  }

  Future<void> failTimes(int times) async {
    for (var i = 0; i < times; i++) {
      await store.verifyPin(wrongPin);
    }
  }

  group('PIN at rest', () {
    test('is hashed, never written in the clear', () async {
      await store.configure(pin: correctPin, biometrics: false);

      final stored = await storedPin();
      expect(stored, isNotNull);
      expect(stored, isNot(correctPin));
      expect(PinCredential.isHashed(stored!), isTrue);
    });

    test('changing the PIN rewrites it hashed', () async {
      await store.configure(pin: correctPin, biometrics: false);
      await store.updatePin('654321');

      expect(PinCredential.isHashed((await storedPin())!), isTrue);
      expect(await store.verifyPin('654321'), isTrue);
      expect(await store.verifyPin(correctPin), isFalse);
    });

    test('verifies the correct PIN and rejects a wrong one', () async {
      await store.configure(pin: correctPin, biometrics: false);

      expect(await store.verifyPin(correctPin), isTrue);
      expect(await store.verifyPin(wrongPin), isFalse);
    });

    test('rejects any PIN when no wallet is configured', () async {
      expect(await store.verifyPin(correctPin), isFalse);
    });
  });

  group('legacy plaintext migration', () {
    test('unlocks, then upgrades the record in place', () async {
      // Simulates a wallet enrolled before hashing landed.
      SharedPreferences.setMockInitialValues({
        'wallet_device_pin_v1': correctPin,
        'wallet_configured_v1': true,
      });

      expect(await store.verifyPin(correctPin), isTrue);
      final upgraded = await storedPin();
      expect(PinCredential.isHashed(upgraded!), isTrue);

      // And the upgraded record still accepts the same PIN.
      expect(await store.verifyPin(correctPin), isTrue);
      expect(await store.verifyPin(wrongPin), isFalse);
    });

    test('a wrong PIN does not overwrite the legacy record', () async {
      SharedPreferences.setMockInitialValues({
        'wallet_device_pin_v1': correctPin,
        'wallet_configured_v1': true,
      });

      expect(await store.verifyPin(wrongPin), isFalse);
      expect(await storedPin(), correctPin);
    });
  });

  group('brute-force lockout', () {
    test('allows up to the attempt limit before locking', () async {
      await store.configure(pin: correctPin, biometrics: false);

      await failTimes(WalletSessionStore.maxPinAttempts - 1);
      expect(await store.pinLockoutRemaining(), isNull);
      expect(
        await store.pinFailureCount(),
        WalletSessionStore.maxPinAttempts - 1,
      );

      // The correct PIN still works right up to the limit.
      expect(await store.verifyPin(correctPin), isTrue);
    });

    test('locks after the limit and refuses even the correct PIN', () async {
      await store.configure(pin: correctPin, biometrics: false);

      await failTimes(WalletSessionStore.maxPinAttempts);

      final remaining = await store.pinLockoutRemaining();
      expect(remaining, isNotNull);
      expect(remaining, lessThanOrEqualTo(WalletSessionStore.lockoutLadder[0]));
      // This is the point of the control: guessing stops entirely, so the
      // attacker cannot keep sweeping while the window is open.
      expect(await store.verifyPin(correctPin), isFalse);
    });

    test('clears once the window expires', () async {
      await store.configure(pin: correctPin, biometrics: false);
      await failTimes(WalletSessionStore.maxPinAttempts);

      now = now
          .add(WalletSessionStore.lockoutLadder[0])
          .add(const Duration(seconds: 1));

      expect(await store.pinLockoutRemaining(), isNull);
      expect(await store.verifyPin(correctPin), isTrue);
    });

    test('escalates the wait on each further failure', () async {
      await store.configure(pin: correctPin, biometrics: false);
      await failTimes(WalletSessionStore.maxPinAttempts);

      Duration ladderStep(int index) => WalletSessionStore.lockoutLadder[index];

      for (
        var step = 1;
        step < WalletSessionStore.lockoutLadder.length;
        step++
      ) {
        // Wait out the current window, then guess wrong once more.
        now = now.add(ladderStep(step - 1)).add(const Duration(seconds: 1));
        expect(await store.pinLockoutRemaining(), isNull);

        await store.verifyPin(wrongPin);

        final remaining = await store.pinLockoutRemaining();
        expect(remaining, isNotNull, reason: 'step $step must re-lock');
        expect(
          remaining,
          greaterThan(ladderStep(step - 1)),
          reason: 'step $step must wait longer than step ${step - 1}',
        );
      }
    });

    test('caps rather than growing without bound', () async {
      await store.configure(pin: correctPin, biometrics: false);
      final ladder = WalletSessionStore.lockoutLadder;
      await failTimes(WalletSessionStore.maxPinAttempts + ladder.length + 5);

      final remaining = await store.pinLockoutRemaining();
      expect(remaining, isNotNull);
      // A wallet is recoverable only from the phrase, so an unbounded (or
      // wiping) lockout would be a griefing vector, not a protection.
      expect(remaining, lessThanOrEqualTo(ladder.last));
    });

    test('a success resets the counter', () async {
      await store.configure(pin: correctPin, biometrics: false);

      await failTimes(WalletSessionStore.maxPinAttempts - 1);
      expect(await store.verifyPin(correctPin), isTrue);
      expect(await store.pinFailureCount(), 0);

      // Full budget available again.
      await failTimes(WalletSessionStore.maxPinAttempts - 1);
      expect(await store.pinLockoutRemaining(), isNull);
    });

    test('configure and updatePin clear an active lockout', () async {
      await store.configure(pin: correctPin, biometrics: false);
      await failTimes(WalletSessionStore.maxPinAttempts);
      expect(await store.pinLockoutRemaining(), isNotNull);

      await store.updatePin('654321');

      expect(await store.pinLockoutRemaining(), isNull);
      expect(await store.pinFailureCount(), 0);
      expect(await store.verifyPin('654321'), isTrue);
    });

    test('clear() wipes the lockout state with everything else', () async {
      await store.configure(pin: correctPin, biometrics: false);
      await failTimes(WalletSessionStore.maxPinAttempts);

      await store.clear();

      expect(await store.pinLockoutRemaining(), isNull);
      expect(await store.pinFailureCount(), 0);
      expect(await store.hasWallet(), isFalse);
      expect(await storedPin(), isNull);
    });
  });

  group('wallet state', () {
    test('reports configured only after configure()', () async {
      expect(await store.hasWallet(), isFalse);
      await store.configure(pin: correctPin, biometrics: true);
      expect(await store.hasWallet(), isTrue);
      expect(await store.biometricsEnabled(), isTrue);
    });

    test('never persists the mnemonic on the desktop tier', () async {
      await store.saveWalletSecrets(
        mnemonic: 'abandon abandon abandon',
        address: '0x9858EfFD232B4033E47d90003D41EC34EcaEda94',
      );

      final prefs = await SharedPreferences.getInstance();
      expect(await store.readMnemonic(), isNull);
      expect(
        prefs.getKeys().any(
          (key) => (prefs.get(key)?.toString() ?? '').contains('abandon'),
        ),
        isFalse,
        reason: 'the phrase must not reach plain SharedPreferences',
      );
      expect(
        await store.walletAddress(),
        '0x9858EfFD232B4033E47d90003D41EC34EcaEda94',
      );
    });
  });
}
