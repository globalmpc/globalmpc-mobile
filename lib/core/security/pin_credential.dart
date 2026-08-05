import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';

/// Salted PBKDF2-HMAC-SHA256 encoding of the device PIN (spec S6).
///
/// The PIN is never persisted in the clear. Platform secure storage already
/// encrypts at rest, but a PIN is frequently reused by the user elsewhere, so
/// a storage blob that leaks must not also hand over the PIN itself. On the
/// macOS dev shell — where the fallback is plain [SharedPreferences] — this is
/// the only thing standing between the file and the PIN.
///
/// Primitives come from pointycastle; this class only formats, derives and
/// compares, per the same clean-room boundary [WalletKeyService] states: we
/// build the lifecycle layer, never the primitives.
class PinCredential {
  const PinCredential._();

  static const String _scheme = 'pbkdf2_sha256';

  /// Cost chosen so a PIN check stays imperceptible on device (~100ms) while
  /// still pricing up an offline sweep of the 10^6 six-digit space.
  static const int defaultIterations = 60000;

  static const int _saltBytes = 16;
  static const int _keyBytes = 32;

  /// Encodes [pin] as `pbkdf2_sha256$<iterations>$<salt>$<key>`.
  ///
  /// [salt] is injectable for tests only; production always draws from the
  /// platform CSPRNG.
  static String hash(
    String pin, {
    int iterations = defaultIterations,
    Uint8List? salt,
  }) {
    final resolvedSalt = salt ?? _randomSalt();
    final derived = _derive(pin, resolvedSalt, iterations);
    return '$_scheme\$$iterations\$${base64.encode(resolvedSalt)}'
        '\$${base64.encode(derived)}';
  }

  /// Whether [stored] is in the hashed format rather than a legacy plaintext
  /// PIN written by an earlier build.
  static bool isHashed(String stored) => stored.startsWith('$_scheme\$');

  /// Constant-time check of [pin] against [stored].
  ///
  /// Accepts legacy plaintext records so wallets created before hashing was
  /// introduced still unlock; [WalletSessionStore] re-writes those to the
  /// hashed form on the next successful unlock.
  static bool matches({required String pin, required String stored}) {
    if (!isHashed(stored)) {
      return _constantTimeEquals(utf8.encode(pin), utf8.encode(stored));
    }
    final parts = stored.split(r'$');
    if (parts.length != 4) return false;
    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations <= 0) return false;
    final Uint8List salt;
    final Uint8List expected;
    try {
      salt = base64.decode(parts[2]);
      expected = base64.decode(parts[3]);
    } on FormatException {
      return false;
    }
    return _constantTimeEquals(_derive(pin, salt, iterations), expected);
  }

  static Uint8List _derive(String pin, Uint8List salt, int iterations) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, iterations, _keyBytes));
    return derivator.process(Uint8List.fromList(utf8.encode(pin)));
  }

  static Uint8List _randomSalt() {
    final rng = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(_saltBytes, (_) => rng.nextInt(256)),
    );
  }

  /// Compares without an early exit, so timing does not reveal how much of the
  /// value matched. Length is folded into the result rather than short-
  /// circuited on.
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    var diff = a.length ^ b.length;
    final max = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < max; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      diff |= x ^ y;
    }
    return diff == 0;
  }
}
