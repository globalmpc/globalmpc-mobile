import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpc_mining_app/core/security/pin_credential.dart';

/// The PIN guards local wallet access and is frequently reused by the user on
/// other systems. If any expectation here fails, a leaked storage blob hands
/// over the PIN itself rather than only an unusable derivative.
void main() {
  // Low cost keeps the suite fast; production uses defaultIterations.
  const iterations = 1000;
  final salt = Uint8List.fromList(List<int>.generate(16, (i) => i));

  group('encoding', () {
    test('never stores the PIN in a recoverable form', () {
      final stored = PinCredential.hash('123456', iterations: iterations);

      expect(stored, isNot(contains('123456')));
      expect(base64.decode(stored.split(r'$')[3]), hasLength(32));
    });

    test('is tagged, versioned and parseable', () {
      final stored = PinCredential.hash(
        '123456',
        iterations: iterations,
        salt: salt,
      );
      final parts = stored.split(r'$');

      expect(parts, hasLength(4));
      expect(parts[0], 'pbkdf2_sha256');
      expect(int.parse(parts[1]), iterations);
      expect(base64.decode(parts[2]), salt);
      expect(PinCredential.isHashed(stored), isTrue);
    });

    test('salts per record, so identical PINs do not collide', () {
      final a = PinCredential.hash('123456', iterations: iterations);
      final b = PinCredential.hash('123456', iterations: iterations);

      // Equal PINs must not produce equal records, or the store leaks which
      // users share a PIN and a single cracked hash covers all of them.
      expect(a, isNot(b));
      expect(PinCredential.matches(pin: '123456', stored: a), isTrue);
      expect(PinCredential.matches(pin: '123456', stored: b), isTrue);
    });

    test('is deterministic for a fixed salt and cost', () {
      expect(
        PinCredential.hash('123456', iterations: iterations, salt: salt),
        PinCredential.hash('123456', iterations: iterations, salt: salt),
      );
    });
  });

  group('verification', () {
    test('accepts the correct PIN and rejects near misses', () {
      final stored = PinCredential.hash('123456', iterations: iterations);

      expect(PinCredential.matches(pin: '123456', stored: stored), isTrue);
      for (final wrong in ['123457', '023456', '12345', '1234567', '']) {
        expect(
          PinCredential.matches(pin: wrong, stored: stored),
          isFalse,
          reason: '$wrong must not unlock',
        );
      }
    });

    test('a different cost factor still verifies', () {
      // The cost is read back from the record, so raising the production
      // default must not lock out wallets enrolled at the old cost.
      final old = PinCredential.hash('123456', iterations: 500);

      expect(PinCredential.matches(pin: '123456', stored: old), isTrue);
    });

    test('rejects malformed records instead of throwing', () {
      for (final broken in [
        'pbkdf2_sha256\$1000\$notbase64!!\$also-bad',
        'pbkdf2_sha256\$1000\$${base64.encode(salt)}',
        'pbkdf2_sha256\$0\$${base64.encode(salt)}\$${base64.encode(salt)}',
        'pbkdf2_sha256\$abc\$${base64.encode(salt)}\$${base64.encode(salt)}',
      ]) {
        expect(
          PinCredential.matches(pin: '123456', stored: broken),
          isFalse,
          reason: 'corrupt record must fail closed, not crash',
        );
      }
    });
  });

  group('legacy plaintext records', () {
    test('still verify, so existing wallets are not locked out', () {
      // Wallets enrolled before hashing landed hold the raw PIN.
      expect(PinCredential.isHashed('123456'), isFalse);
      expect(PinCredential.matches(pin: '123456', stored: '123456'), isTrue);
      expect(PinCredential.matches(pin: '000000', stored: '123456'), isFalse);
    });
  });
}
