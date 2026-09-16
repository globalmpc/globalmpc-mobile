import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mpc_mining_app/core/security/biometric_auth.dart';

class _FakeLocalAuth extends LocalAuthentication {
  _FakeLocalAuth({
    this.supported = true,
    this.enrolled = const [BiometricType.strong],
    this.outcome,
  });

  final bool supported;
  final List<BiometricType> enrolled;

  final Object? outcome;

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
    final o = outcome;
    if (o is LocalAuthExceptionCode) throw LocalAuthException(code: o);
    return o as bool;
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

    test('missing enrolment and host errors are distinguishable', () async {
      expect(
        await run(LocalAuthExceptionCode.noBiometricsEnrolled),
        BiometricResult.notEnrolled,
      );
      expect(
        await run(LocalAuthExceptionCode.uiUnavailable),
        BiometricResult.unavailable,
      );
      expect(
        await run(LocalAuthExceptionCode.noBiometricHardware),
        BiometricResult.unavailable,
      );
    });
  });
}
