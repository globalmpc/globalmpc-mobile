import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:web3dart/web3dart.dart';

/// On-device BIP-39 / BIP-44 key lifecycle. Non-custodial by construction:
/// nothing in this class performs I/O — no network, no storage, no logging.
/// Persistence is the caller's job via [WalletSessionStore]; broadcast is the
/// chain service's job and only ever carries signed transactions.
///
/// Derivation is MetaMask/Trust-compatible (`m/44'/60'/0'/0/0`), which is what
/// makes a phrase created here restore to the same address elsewhere, and
/// vice versa (spec test T2). Crypto primitives come from audited libraries
/// only (bip39, bip32, web3dart) per the clean-room boundary: we build the
/// lifecycle layer, never the primitives.
class WalletKeyService {
  const WalletKeyService();

  /// MetaMask's default derivation path: BIP-44, coin type 60 (Ethereum,
  /// shared by BSC), account 0, external chain, index 0.
  static const String derivationPath = "m/44'/60'/0'/0/0";

  /// Every mnemonic length BIP-39 defines (128–256 bits of entropy). Wallets
  /// that export 15, 18 or 21 words are valid and must import cleanly, so the
  /// UI may not narrow this to the common 12/24 case.
  static const Set<int> validWordCounts = {12, 15, 18, 21, 24};

  /// 128-bit entropy -> 12 words, from the platform CSPRNG inside bip39.
  String generateMnemonic() => bip39.generateMnemonic(strength: 128);

  /// BIP-39 checksum validation. Accepts 12 or 24 words, any spacing/case.
  bool validateMnemonic(String phrase) =>
      bip39.validateMnemonic(_normalize(phrase));

  /// Phrase -> secp256k1 private key. Same path for create and restore.
  EthPrivateKey deriveKey(String mnemonic) {
    final seed = bip39.mnemonicToSeed(_normalize(mnemonic));
    final node = bip32.BIP32.fromSeed(seed).derivePath(derivationPath);
    final privateKey = node.privateKey;
    if (privateKey == null) {
      throw StateError('Derivation produced no private key');
    }
    return EthPrivateKey(privateKey);
  }

  /// EIP-55 checksummed address for [mnemonic]. The value MetaMask must
  /// reproduce when the same phrase is imported there (T2).
  String deriveAddress(String mnemonic) => deriveKey(mnemonic).address.hexEip55;

  String _normalize(String phrase) =>
      phrase.trim().toLowerCase().split(RegExp(r'\s+')).join(' ');
}
