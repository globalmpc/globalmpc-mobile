import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pin_credential.dart';

class WalletSessionStore {
  WalletSessionStore._({DateTime Function()? clock, int? pinIterations})
    : _now = clock ?? DateTime.now,
      _pinIterations = pinIterations ?? PinCredential.defaultIterations;

  static final WalletSessionStore instance = WalletSessionStore._();

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
  static const _backupVerifiedKey = 'wallet_backup_verified_v1';

  static const int maxPinAttempts = 5;

  static const List<Duration> lockoutLadder = [
    Duration(seconds: 30),
    Duration(minutes: 2),
    Duration(minutes: 10),
    Duration(minutes: 30),
    Duration(hours: 1),
  ];

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

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

  Future<Duration?> pinLockoutRemaining() async {
    final raw = await _readValue(_pinLockUntilKey);
    final millis = int.tryParse(raw ?? '');
    if (millis == null) return null;
    final remaining = DateTime.fromMillisecondsSinceEpoch(
      millis,
    ).difference(_now());
    return remaining > Duration.zero ? remaining : null;
  }

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

  Future<void> clearPinFailures() => _clearPinFailures();

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

  Future<void> saveWalletSecrets({
    required String mnemonic,
    required String address,
  }) async {
    await _storage.write(key: _mnemonicKey, value: mnemonic);
    await _storage.write(key: _addressKey, value: address);
  }

  Future<String?> walletAddress() async {
    try {
      return await _storage.read(key: _addressKey);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<String?> readMnemonic() async {
    try {
      return await _storage.read(key: _mnemonicKey);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<bool> verifyPin(String pin) async {
    if (await pinLockoutRemaining() != null) return false;
    final stored = await _readValue(_pinKey);
    if (stored == null) return false;
    if (!PinCredential.matches(pin: pin, stored: stored)) {
      await _registerPinFailure();
      return false;
    }

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

  Future<bool> isBackupVerified() async {
    try {
      return await _readValue(_backupVerifiedKey) == 'true';
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> setBackupVerified(bool value) async {
    await _writeValue(_backupVerifiedKey, value ? 'true' : 'false');
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
