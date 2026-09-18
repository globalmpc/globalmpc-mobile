import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mpc_mining_app/core/security/biometric_auth.dart';

class _FakeLocalAuth extends LocalAuthentication {
  _FakeLocalAuth({
    this.supported = true,
    this.enrolled = const [BiometricType.strong],
    this.outcome,
    this.hang = false,
  });

  final bool supported;
  final List<BiometricType> enrolled;

  final Object? outcome;

  /// Never completes the prompt, like a system-cancelled prompt the
  /// platform is holding until the app resumes.
  final bool hang;
  int stopCalls = 0;

  @override
  Future<bool> get canCheckBiometrics async => supported;

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
    if (hang) return Completer<bool>().future;
    final o = outcome;
    if (o is LocalAuthExceptionCode) throw LocalAuthException(code: o);
    return o as bool;
  }

  @override
  Future<bool> stopAuthentication() async {
    stopCalls++;
    return true;
  }
}

void main() {
  group('availability', () {
    test('ready only when hardware exists and something is enrolled', () async {
      expect(
        await BiometricAuth(_FakeLocalAuth()).availability(),
        BiometricAvailability.ready,
      );
      expect(
        await BiometricAuth(_FakeLocalAuth(enrolled: const [])).availability(),
        BiometricAvailability.notEnrolled,
      );
      expect(
        await BiometricAuth(_FakeLocalAuth(supported: false)).availability(),
        BiometricAvailability.unsupported,
      );
    });
  });

  group('authenticate', () {
    Future<BiometricResult> run(Object outcome) => BiometricAuth(
      _FakeLocalAuth(outcome: outcome),
    ).authenticate(reason: 'test');

    test('success passes through', () async {
      expect(await run(true), BiometricResult.success);
    });

    test('cancel is a non-event, never a failure', () async {
      expect(await run(false), BiometricResult.cancelled);
      expect(
        await run(LocalAuthExceptionCode.userCanceled),
        BiometricResult.cancelled,
      );
      expect(
        await run(LocalAuthExceptionCode.systemCanceled),
        BiometricResult.cancelled,
      );
      expect(
        await run(LocalAuthExceptionCode.authInProgress),
        BiometricResult.cancelled,
      );
    });

    test('OS lockouts are reported as lockedOut', () async {
      expect(
        await run(LocalAuthExceptionCode.temporaryLockout),
        BiometricResult.lockedOut,
      );
      expect(
        await run(LocalAuthExceptionCode.biometricLockout),
        BiometricResult.lockedOut,
      );
    });

    test('missing enrolment, refused access and host errors differ', () async {
      expect(
        await run(LocalAuthExceptionCode.noBiometricsEnrolled),
        BiometricResult.notEnrolled,
      );
      // What iOS reports when the user refused this app access to Face ID.
      expect(
        await run(LocalAuthExceptionCode.noBiometricHardware),
        BiometricResult.disabledForApp,
      );
      expect(
        await run(LocalAuthExceptionCode.uiUnavailable),
        BiometricResult.unavailable,
      );
      expect(
        await run(LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable),
        BiometricResult.unavailable,
      );
    });

    test('a prompt that never completes is cancelled after the timeout', () async {
      final fake = _FakeLocalAuth(hang: true);
      final auth = BiometricAuth(fake, const Duration(milliseconds: 50));

      final result = await auth.authenticate(reason: 'test');

      expect(result, BiometricResult.cancelled);
      expect(fake.stopCalls, 1);
    });
  });

  test('every non-trivial result has a message key', () {
    for (final result in BiometricResult.values) {
      final key = biometricMessageKey(result);
      final silent =
          result == BiometricResult.success ||
          result == BiometricResult.cancelled;
      expect(key == null, silent, reason: '$result');
    }
  });
}
