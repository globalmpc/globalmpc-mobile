import 'dart:async';

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// What the availability probe can tell before any prompt is shown.
///
/// [notEnrolled] is deliberately broad: on iOS the enrolled list is also
/// empty when the user has refused this app access to Face ID, and only the
/// error from an actual prompt distinguishes the two. Callers should treat
/// it as "try, then explain", not as a reason to skip the prompt.
enum BiometricAvailability { ready, notEnrolled, unsupported }

enum BiometricResult {
  success,
  cancelled,
  lockedOut,
  notEnrolled,

  /// Hardware exists but this app may not use it right now, typically because
  /// the user refused the system permission. Fixed in device settings, not
  /// in the app.
  disabledForApp,
  unavailable,
}

/// Localization key that explains [result] to the user, or null when there
/// is nothing to say (success, or a prompt the user dismissed themselves).
String? biometricMessageKey(BiometricResult result) => switch (result) {
  BiometricResult.success || BiometricResult.cancelled => null,
  BiometricResult.lockedOut => 'settings.bio.locked',
  BiometricResult.notEnrolled => 'settings.bio.enrol',
  BiometricResult.disabledForApp => 'bio.disabledForApp',
  BiometricResult.unavailable => 'settings.bio.unavailable',
};

class BiometricAuth {
  BiometricAuth([LocalAuthentication? auth, this.promptTimeout = defaultTimeout])
    : _auth = auth ?? LocalAuthentication();

  /// Upper bound on a single prompt. A prompt the system cancelled is held
  /// open by the platform until the app comes back to the foreground, which
  /// can be never; without a bound the caller would wait forever and every
  /// later attempt would be refused as already in progress.
  static const Duration defaultTimeout = Duration(minutes: 2);

  final LocalAuthentication _auth;
  final Duration promptTimeout;

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
      final ok = await _auth
          .authenticate(
            localizedReason: reason,
            biometricOnly: true,
            persistAcrossBackgrounding: true,
          )
          .timeout(promptTimeout);
      return ok ? BiometricResult.success : BiometricResult.cancelled;
    } on TimeoutException {
      await cancel();
      return BiometricResult.cancelled;
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
        // Reported by iOS when the app was denied biometric access, and by
        // both platforms only after availability() already saw hardware, so
        // the honest reading is "present but not usable by this app".
        LocalAuthExceptionCode.noBiometricHardware =>
          BiometricResult.disabledForApp,
        _ => BiometricResult.unavailable,
      };
    } on PlatformException {
      return BiometricResult.unavailable;
    } on MissingPluginException {
      return BiometricResult.unavailable;
    }
  }

  /// Dismisses a prompt that is still open so a fresh one can be started.
  Future<void> cancel() async {
    try {
      await _auth.stopAuthentication();
    } on LocalAuthException {
      // Nothing was in progress, or the platform has no notion of stopping.
    } on PlatformException {
      // Same as above.
    } on MissingPluginException {
      // Test embedder.
    }
  }
}
