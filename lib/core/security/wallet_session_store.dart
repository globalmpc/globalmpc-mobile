import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pin_credential.dart';

/// Device-local wallet access state and, on mobile, the wallet secrets.
///
/// This does not recover a wallet after secure storage is removed. A reinstall
/// or forgotten PIN returns the user to recovery-phrase import.
///
/// Every entry, including the recovery phrase, lives in [FlutterSecureStorage]
/// on every platform. There is no plaintext fallback tier: an unencrypted
/// preferences store is not an acceptable home for wallet state, so a platform
/// without secure storage fails closed rather than degrading silently.
class WalletSessionStore {
  WalletSessionStore._({DateTime Function()? clock, int? pinIterations})
    : _now = clock ?? DateTime.now,
      _pinIterations = pinIterations ?? PinCredential.defaultIterations;

  static final WalletSessionStore instance = WalletSessionStore._();

  /// Isolated instance with an injectable clock, so lockout expiry can be
  /// tested without sleeping, and a reduced PBKDF2 cost so a suite that
  /// exercises many PIN attempts does not spend seconds in key derivation.
  /// Production always uses [PinCredential.defaultIterations].
  @visibleForTesting
  static WalletSessionStore forTesting({
    DateTime Function()? clock,
    int? pinIterations,
  }) => WalletSessionStore._(clock: clock, pinIterations: pinIterations);

  final DateTime Function() _now;
  final int _pinIterations;

  static const _configuredKey = 'wallet_configured_v1';
  static const _pinKey = 'wallet_device_pin_v1';
  static const _biometricsKey = 'wallet_biometrics_v1';
  static const _mnemonicKey = 'wallet_mnemonic_v1';
  static const _addressKey = 'wallet_address_v1';
  static const _pinFailuresKey = 'wallet_pin_failures_v1';
  static const _pinLockUntilKey = 'wallet_pin_lock_until_v1';

  /// Wrong PINs tolerated before the keypad locks. Six digits is only 10^6
  /// combinations and the unlock screen submits automatically on the sixth
  /// digit, so an unattended device would otherwise be swept by a scripted
  /// attacker (spec S6).
  static const int maxPinAttempts = 5;

  /// Lock duration after each further failure once [maxPinAttempts] is hit.
  /// Escalates so a wrong-but-honest user waits seconds while an attacker
  /// hits hours; capped rather than wiping, since the wallet is recoverable
  /// only from the phrase and a wipe-on-fail would be a griefing vector.
  static const List<Duration> lockoutLadder = [
    Duration(seconds: 30),
    Duration(minutes: 2),
    Duration(minutes: 10),
    Duration(minutes: 30),
    Duration(hours: 1),
  ];

  // Android is deliberately left on plugin defaults. Verified against
  // flutter_secure_storage 10.3.1 sources rather than assumed:
  //
  // - The default is AES_GCM_NoPadding for the data, under a per-app key
  //   wrapped with RSA-OAEP-SHA256 held in the Android Keystore (hardware
  //   backed where the device offers it). That is real encryption at rest.
  // - Do NOT "harden" this by setting `encryptedSharedPreferences: true`.
  //   That selects Jetpack Security's EncryptedSharedPreferences, which
  //   Google has deprecated; the plugin logs "DEPRECATED and will be removed
  //   in a later version" when it finds data there and ships migration code
  //   to move apps off it. Turning it on walks toward a dead backend.
  // - Changing either cipher option on an installed app re-keys storage. Any
  //   entry written under the old scheme stops being readable, which for this
  //   app means the mnemonic is gone and the wallet is recoverable only from
  //   the phrase. Treat these options as append-only.
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Reads a scalar, transparently picking the platform tier. Returns null on
  /// the plugin-less test embedder rather than throwing, matching the
  /// fail-closed posture of the callers.
  Future<String?> _readValue(String key) async {
    try {
      return await _storage.read(key: key);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<void> _writeValue(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<void> _deleteValue(String key) async {
    try {
      await _storage.delete(key: key);
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  /// Time left on the PIN lockout, or null when entry is currently allowed.
  Future<Duration?> pinLockoutRemaining() async {
    final raw = await _readValue(_pinLockUntilKey);
    final millis = int.tryParse(raw ?? '');
    if (millis == null) return null;
    final remaining = DateTime.fromMillisecondsSinceEpoch(
      millis,
    ).difference(_now());
    return remaining > Duration.zero ? remaining : null;
  }

  /// Consecutive wrong PINs since the last success. Drives the "N attempts
  /// left" warning before the lockout actually bites.
  Future<int> pinFailureCount() async =>
      int.tryParse(await _readValue(_pinFailuresKey) ?? '') ?? 0;

  Future<void> _registerPinFailure() async {
    final failures = await pinFailureCount() + 1;
    await _writeValue(_pinFailuresKey, '$failures');
    if (failures < maxPinAttempts) return;
    final step = (failures - maxPinAttempts).clamp(0, lockoutLadder.length - 1);
    final until = _now().add(lockoutLadder[step]);
    await _writeValue(_pinLockUntilKey, '${until.millisecondsSinceEpoch}');
  }

  Future<void> _clearPinFailures() async {
    await _deleteValue(_pinFailuresKey);
    await _deleteValue(_pinLockUntilKey);
  }

  Future<bool> hasWallet() async {
    try {
      return await _storage.read(key: _configuredKey) == 'true';
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> configure({
    required String pin,
    required bool biometrics,
  }) async {
    await _writeValue(
      _pinKey,
      PinCredential.hash(pin, iterations: _pinIterations),
    );
    await _clearPinFailures();
    await _storage.write(key: _biometricsKey, value: '$biometrics');
    await _storage.write(key: _configuredKey, value: 'true');
  }

  /// Persists the wallet secrets after create/import. The mnemonic only ever
  /// enters platform secure storage.
  Future<void> saveWalletSecrets({
    required String mnemonic,
    required String address,
  }) async {
    await _storage.write(key: _mnemonicKey, value: mnemonic);
    await _storage.write(key: _addressKey, value: address);
  }

  /// EIP-55 address of the stored wallet, or null when none is configured.
  Future<String?> walletAddress() async {
    try {
      return await _storage.read(key: _addressKey);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// The stored recovery phrase, for signing only. Callers must never log,
  /// display outside the reveal screen, or place it in any network payload
  /// (spec S1/T16). Null when no wallet is configured.
  Future<String?> readMnemonic() async {
    try {
      return await _storage.read(key: _mnemonicKey);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Checks [pin] against the stored credential.
  ///
  /// Returns false while a lockout is in force, so every caller (unlock,
  /// send confirmation, PIN change) is rate-limited without having to
  /// implement it separately. Callers that want to explain the refusal read
  /// [pinLockoutRemaining].
  Future<bool> verifyPin(String pin) async {
    if (await pinLockoutRemaining() != null) return false;
    final stored = await _readValue(_pinKey);
    if (stored == null) return false;
    if (!PinCredential.matches(pin: pin, stored: stored)) {
      await _registerPinFailure();
      return false;
    }
    // Wallets created before PIN hashing landed still hold plaintext; upgrade
    // in place now that the correct PIN is in hand.
    if (!PinCredential.isHashed(stored)) {
      await _writeValue(
        _pinKey,
        PinCredential.hash(pin, iterations: _pinIterations),
      );
    }
    await _clearPinFailures();
    return true;
  }

  Future<bool> biometricsEnabled() async {
    try {
      return await _storage.read(key: _biometricsKey) == 'true';
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(key: _biometricsKey, value: '$enabled');
  }

  Future<void> updatePin(String pin) async {
    await _writeValue(
      _pinKey,
      PinCredential.hash(pin, iterations: _pinIterations),
    );
    await _clearPinFailures();
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
