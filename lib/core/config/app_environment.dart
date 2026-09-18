import 'package:flutter/foundation.dart';

import '../constants/chain_config.dart';

/// Which deployment a build targets. Selected at compile time so a single
/// binary can never switch networks at runtime.
enum BuildEnvironment { dev, prod }

/// Build-time configuration for the app.
///
/// Every value is a `--dart-define`, normally supplied as a group with
/// `--dart-define-from-file=env/<name>.env` (see `env/example.env`). Values
/// that identify contracts or deployment-specific links are not part of the
/// source tree: they arrive through the environment file, and a `prod` build
/// refuses to start without the ones it needs rather than falling back to a
/// development network.
class AppEnvironment {
  const AppEnvironment({
    required this.build,
    required this.chain,
    this.registryAnchorAddress,
    this.presaleUrl,
    required this.termsUrl,
    required this.privacyUrl,
    required this.helpUrl,
    this.storeUrl,
  });

  /// The configuration this process was compiled with.
  static AppEnvironment current = AppEnvironment.fromDefines();

  @visibleForTesting
  static void override(AppEnvironment environment) => current = environment;

  @visibleForTesting
  static void reset() => current = AppEnvironment.fromDefines();

  final BuildEnvironment build;
  final ChainConfig chain;

  /// Address of the registry anchor contract on [chain], or null when this
  /// build has no registry feed.
  final String? registryAnchorAddress;

  /// External presale website, or null when the presale entry is hidden.
  final String? presaleUrl;

  final String termsUrl;
  final String privacyUrl;
  final String helpUrl;

  /// Store listing used by the "Rate us" row, or null while there is none.
  final String? storeUrl;

  bool get isProduction => build == BuildEnvironment.prod;
  bool get hasRegistry => registryAnchorAddress != null;
  bool get hasPresale => presaleUrl != null;
  bool get hasStoreListing => storeUrl != null;

  static const _envKey = 'MPC_ENV';
  static const _chainIdKey = 'MPC_CHAIN_ID';
  static const _rpcUrlKey = 'MPC_RPC_URL';
  static const _explorerUrlKey = 'MPC_EXPLORER_URL';
  static const _networkLabelKey = 'MPC_NETWORK_LABEL';
  static const _tokenAddressKey = 'MPC_TOKEN_ADDRESS';
  static const _registryAnchorKey = 'MPC_REGISTRY_ANCHOR_ADDRESS';
  static const _historyWindowKey = 'MPC_HISTORY_BLOCK_WINDOW';
  static const _presaleUrlKey = 'MPC_PRESALE_URL';
  static const _termsUrlKey = 'MPC_TERMS_URL';
  static const _privacyUrlKey = 'MPC_PRIVACY_URL';
  static const _helpUrlKey = 'MPC_HELP_URL';
  static const _storeUrlKey = 'MPC_STORE_URL';

  static const _defaultTermsUrl =
      'https://www.globalmpc.tech/legal/terms-of-use';
  static const _defaultPrivacyUrl =
      'https://www.globalmpc.tech/legal/privacy-policy';
  static const _defaultHelpUrl = 'https://www.globalmpc.tech/';

  /// Defines are only readable as compile-time constants, which is why each
  /// key is spelled out here rather than looked up in a loop.
  static const Map<String, String> _defines = {
    _envKey: String.fromEnvironment(_envKey),
    _chainIdKey: String.fromEnvironment(_chainIdKey),
    _rpcUrlKey: String.fromEnvironment(_rpcUrlKey),
    _explorerUrlKey: String.fromEnvironment(_explorerUrlKey),
    _networkLabelKey: String.fromEnvironment(_networkLabelKey),
    _tokenAddressKey: String.fromEnvironment(_tokenAddressKey),
    _registryAnchorKey: String.fromEnvironment(_registryAnchorKey),
    _historyWindowKey: String.fromEnvironment(_historyWindowKey),
    _presaleUrlKey: String.fromEnvironment(_presaleUrlKey),
    _termsUrlKey: String.fromEnvironment(_termsUrlKey),
    _privacyUrlKey: String.fromEnvironment(_privacyUrlKey),
    _helpUrlKey: String.fromEnvironment(_helpUrlKey),
    _storeUrlKey: String.fromEnvironment(_storeUrlKey),
  };

  factory AppEnvironment.fromDefines() => AppEnvironment.fromValues(_defines);

  /// Builds a configuration from raw key/value pairs, applying the defaults
  /// for the selected build and rejecting combinations that would ship a
  /// misconfigured binary.
  factory AppEnvironment.fromValues(Map<String, String> values) {
    String read(String key) => (values[key] ?? '').trim();

    final build = _parseBuild(read(_envKey));
    final defaults = build == BuildEnvironment.prod
        ? ChainConfig.bscMainnet
        : ChainConfig.bscTestnet;

    final chainId = _parseChainId(read(_chainIdKey), fallback: defaults.chainId);
    if (build == BuildEnvironment.prod && chainId != ChainConfig.bscMainnet.chainId) {
      throw StateError(
        'A prod build must target chain ${ChainConfig.bscMainnet.chainId}, '
        'got $chainId.',
      );
    }
    if (build == BuildEnvironment.dev && chainId == ChainConfig.bscMainnet.chainId) {
      throw StateError('A dev build must not target the mainnet chain id.');
    }

    final tokenAddress = _parseAddress(read(_tokenAddressKey), _tokenAddressKey);
    if (build == BuildEnvironment.prod && tokenAddress == null) {
      throw StateError('$_tokenAddressKey is required for a prod build.');
    }

    final chain = ChainConfig(
      chainId: chainId,
      rpcUrl: _parseUrl(read(_rpcUrlKey), _rpcUrlKey) ?? defaults.rpcUrl,
      explorerBase:
          _parseUrl(read(_explorerUrlKey), _explorerUrlKey) ??
          defaults.explorerBase,
      networkLabel: read(_networkLabelKey).isEmpty
          ? defaults.networkLabel
          : read(_networkLabelKey),
      mpcTokenAddress: tokenAddress,
      historyBlockWindow: _parseWindow(
        read(_historyWindowKey),
        fallback: defaults.historyBlockWindow,
      ),
    );

    return AppEnvironment(
      build: build,
      chain: chain,
      registryAnchorAddress: _parseAddress(
        read(_registryAnchorKey),
        _registryAnchorKey,
      ),
      presaleUrl: _parseUrl(read(_presaleUrlKey), _presaleUrlKey),
      termsUrl: _parseUrl(read(_termsUrlKey), _termsUrlKey) ?? _defaultTermsUrl,
      privacyUrl:
          _parseUrl(read(_privacyUrlKey), _privacyUrlKey) ?? _defaultPrivacyUrl,
      helpUrl: _parseUrl(read(_helpUrlKey), _helpUrlKey) ?? _defaultHelpUrl,
      storeUrl: _parseUrl(read(_storeUrlKey), _storeUrlKey),
    );
  }

  static BuildEnvironment _parseBuild(String raw) => switch (raw.toLowerCase()) {
    '' || 'dev' || 'develop' || 'development' => BuildEnvironment.dev,
    'prod' || 'production' => BuildEnvironment.prod,
    _ => throw StateError('$_envKey must be dev or prod, got "$raw".'),
  };

  static int _parseChainId(String raw, {required int fallback}) {
    if (raw.isEmpty) return fallback;
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      throw StateError('$_chainIdKey must be a positive integer, got "$raw".');
    }
    return parsed;
  }

  static int _parseWindow(String raw, {required int fallback}) {
    if (raw.isEmpty) return fallback;
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      throw StateError(
        '$_historyWindowKey must be a positive integer, got "$raw".',
      );
    }
    return parsed;
  }

  static final _addressPattern = RegExp(r'^0x[0-9a-fA-F]{40}$');

  static String? _parseAddress(String raw, String key) {
    if (raw.isEmpty) return null;
    if (!_addressPattern.hasMatch(raw)) {
      throw StateError('$key must be a 0x-prefixed 20-byte hex address.');
    }
    return raw;
  }

  static String? _parseUrl(String raw, String key) {
    if (raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw StateError('$key must be an https URL, got "$raw".');
    }
    return raw;
  }
}
