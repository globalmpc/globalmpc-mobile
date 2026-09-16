import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricAvailability { ready, notEnrolled, unsupported }

enum BiometricResult { success, cancelled, lockedOut, notEnrolled, unavailable }

class BiometricAuth {
  BiometricAuth([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<BiometricAvailability> availability() async {
    try {
      if (!await _auth.canCheckBiometrics) {
        return BiometricAvailability.unsupported;
      }
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isEmpty
          ? BiometricAvailability.notEnrolled
          : BiometricAvailability.ready;
    } on LocalAuthException {
      return BiometricAvailability.unsupported;
    } on PlatformException {
      return BiometricAvailability.unsupported;
    } on MissingPluginException {
      return BiometricAvailability.unsupported;
    }
  }

  Future<BiometricResult> authenticate({required String reason}) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      return ok ? BiometricResult.success : BiometricResult.cancelled;
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout ||
        LocalAuthExceptionCode.userRequestedFallback ||
        LocalAuthExceptionCode.authInProgress => BiometricResult.cancelled,
        LocalAuthExceptionCode.temporaryLockout ||
        LocalAuthExceptionCode.biometricLockout => BiometricResult.lockedOut,
        LocalAuthExceptionCode.noBiometricsEnrolled =>
          BiometricResult.notEnrolled,
        _ => BiometricResult.unavailable,
      };
    } on PlatformException {
      return BiometricResult.unavailable;
    } on MissingPluginException {
      return BiometricResult.unavailable;
    }
  }
}
