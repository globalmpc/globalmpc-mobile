/// Network configuration for the live chain layer.
///
/// Testnet-only by design: mainnet parameters are deliberately absent from
/// this file until the clean-room gates (WALLET_SPEC §5c, M2 checklists and
/// audits) pass. Nothing on this branch can sign against chain ID 56.
class ChainConfig {
  const ChainConfig._({
    required this.chainId,
    required this.rpcUrl,
    required this.explorerBase,
    required this.networkLabel,
    this.mpcTokenAddress,
  });

  /// BSC Testnet (Chapel). The token address is the Remix-deployed test MPC
  /// ERC-20 (mint-at-will, worthless), never the mainnet contract; null until
  /// that deploy exists, in which case balances read 0 and sends are blocked.
  ///
  /// RPC host is deliberately a neutral infrastructure domain: binance.org /
  /// bnbchain.org hostnames fail DNS on some carrier networks (exchange
  /// blocklists, observed on-device 2026-07-30).
  static const ChainConfig bscTestnet = ChainConfig._(
    chainId: 97,
    rpcUrl: 'https://bsc-testnet-rpc.publicnode.com',
    explorerBase: 'https://testnet.bscscan.com',
    networkLabel: 'BSC Testnet',
    mpcTokenAddress: null,
  );

  final int chainId;
  final String rpcUrl;
  final String explorerBase;
  final String networkLabel;
  final String? mpcTokenAddress;

  bool get hasToken => mpcTokenAddress != null;

  String explorerTxUrl(String hash) => '$explorerBase/tx/$hash';
  String explorerAddressUrl(String address) => '$explorerBase/address/$address';
}
