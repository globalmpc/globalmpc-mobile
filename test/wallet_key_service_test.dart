import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter_test/flutter_test.dart';
import 'package:mpc_mining_app/core/security/wallet_key_service.dart';

/// Interoperability proof (spec T2, unit form): these public BIP-39 test
/// vectors must derive the exact address MetaMask derives at m/44'/60'/0'/0/0.
/// If any expectation here fails, phrases created in this app would restore
/// to a DIFFERENT wallet in MetaMask — a fund-loss defect, never ship.
void main() {
  const service = WalletKeyService();

  const bip39ReferenceVector =
      'abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon abandon abandon about';
  const hardhatVector =
      'test test test test test test test test test test test junk';

  group('derivation (T2 vectors)', () {
    test('BIP-39 reference vector derives the MetaMask address', () {
      expect(
        service.deriveAddress(bip39ReferenceVector),
        '0x9858EfFD232B4033E47d90003D41EC34EcaEda94',
      );
    });

    test('hardhat vector derives account #0', () {
      expect(
        service.deriveAddress(hardhatVector),
        '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
      );
    });

    test('every BIP-39 length imports and derives (12/15/18/21/24)', () {
      // Wallets exporting 15, 18 or 21 words are valid; rejecting them would
      // lock those holders out. Strengths map 128/160/192/224/256 bits.
      for (final strength in [128, 160, 192, 224, 256]) {
        final mnemonic = bip39.generateMnemonic(strength: strength);
        final wordCount = mnemonic.split(' ').length;

        expect(WalletKeyService.validWordCounts, contains(wordCount));
        expect(service.validateMnemonic(mnemonic), isTrue);
        expect(service.deriveAddress(mnemonic).length, 42);
      }
    });

    test('derivation is whitespace- and case-insensitive', () {
      expect(
        service.deriveAddress(
          '  Test test test test TEST test\n'
          'test test test test test junk ',
        ),
        '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
      );
    });
  });

  group('validation (T7)', () {
    test('accepts valid 12-word phrases', () {
      expect(service.validateMnemonic(bip39ReferenceVector), isTrue);
      expect(service.validateMnemonic(hardhatVector), isTrue);
    });

    test('rejects a checksum-broken phrase', () {
      expect(
        service.validateMnemonic(
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon',
        ),
        isFalse,
      );
    });

    test('rejects wrong word counts and non-wordlist words', () {
      expect(service.validateMnemonic('abandon about'), isFalse);
      expect(
        service.validateMnemonic(
          'orbit copper ridge proof ember vault '
          'signal terrain anchor ledger stone north',
        ),
        isFalse,
      );
      expect(service.validateMnemonic(''), isFalse);
    });
  });

  group('generation (T1)', () {
    test('creates valid 12-word phrases that derive EIP-55 addresses', () {
      final mnemonic = service.generateMnemonic();
      expect(mnemonic.split(' ').length, 12);
      expect(service.validateMnemonic(mnemonic), isTrue);

      final address = service.deriveAddress(mnemonic);
      expect(address, startsWith('0x'));
      expect(address.length, 42);
    });

    test('two generations never collide', () {
      expect(service.generateMnemonic(), isNot(service.generateMnemonic()));
    });
  });
}
