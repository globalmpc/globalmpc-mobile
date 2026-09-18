/// Network parameters for the chain layer.
///
/// The active configuration is assembled at compile time by
/// `AppEnvironment` from `--dart-define` values; the two constants below are
/// only the per-build defaults it starts from. The token contract address is
/// never a default: it is supplied by the environment file of the build.
class ChainConfig {
  const ChainConfig({
    required this.chainId,
    required this.rpcUrl,
    required this.explorerBase,
    required this.networkLabel,
    this.mpcTokenAddress,
    this.historyBlockWindow = defaultHistoryBlockWindow,
  });

  /// BSC Testnet (Chapel) defaults for `dev` builds.
  ///
  /// RPC host is deliberately a neutral infrastructure domain: binance.org /
  /// bnbchain.org hostnames fail DNS on some carrier networks (exchange
  /// blocklists, observed on-device 2026-07-30).
  static const ChainConfig bscTestnet = ChainConfig(
    chainId: 97,
    rpcUrl: 'https://bsc-testnet-rpc.publicnode.com',
    explorerBase: 'https://testnet.bscscan.com',
    networkLabel: 'BSC Testnet',
  );

  /// BNB Smart Chain mainnet defaults for `prod` builds. Same neutral RPC
  /// host family as the testnet entry, for the same reason.
  static const ChainConfig bscMainnet = ChainConfig(
    chainId: 56,
    rpcUrl: 'https://bsc-rpc.publicnode.com',
    explorerBase: 'https://bscscan.com',
    networkLabel: 'BNB Smart Chain',
  );

  /// How far back a transfer-history query reaches. Public RPC providers
  /// reject or truncate unbounded `eth_getLogs` scans, so the range is
  /// explicit rather than left to default to genesis; on BSC's ~3s blocks
  /// this is roughly the last three days.
  static const int defaultHistoryBlockWindow = 80000;

  final int chainId;
  final String rpcUrl;
  final String explorerBase;
  final String networkLabel;
  final String? mpcTokenAddress;
  final int historyBlockWindow;

  bool get hasToken => mpcTokenAddress != null;

  bool get isMainnet => chainId == bscMainnet.chainId;

  /// Compact network name for pills and badges. Mainnet has a conventional
  /// short form; any other chain is named by its configured label so a
  /// build on an unexpected network is never called something it is not.
  String get networkShort => isMainnet ? 'BSC' : networkLabel;

  String explorerTxUrl(String hash) => '$explorerBase/tx/$hash';
  String explorerAddressUrl(String address) => '$explorerBase/address/$address';
}
