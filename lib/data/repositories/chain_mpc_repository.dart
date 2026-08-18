import '../../core/security/wallet_session_store.dart';
import '../models/mining_project.dart';
import '../models/wallet_models.dart';
import '../services/bsc_chain_service.dart';
import 'mpc_repository.dart';

/// Live-chain repository. Wallet data comes from the configured network for
/// the on-device wallet; until a real wallet exists (or on desktop, which is
/// watch-only), every call falls back to the mock so no screen changes
/// behaviour. Project/content data stays on the fallback until the content
/// service exists.
class ChainMpcRepository implements MpcRepository {
  const ChainMpcRepository(this._chain, this._fallback);

  final BscChainService _chain;
  final MpcRepository _fallback;

  @override
  Future<List<MiningProject>> fetchProjects() => _fallback.fetchProjects();

  @override
  Future<MiningProject?> fetchProject(String id) => _fallback.fetchProject(id);

  @override
  Future<WalletAccount> fetchWallet() async {
    final address = await WalletSessionStore.instance.walletAddress();
    if (address == null) return _fallback.fetchWallet();

    final results = await Future.wait<Object>([
      _chain.bnbBalance(address),
      _chain.mpcBalance(address),
      _chain.recentTransfers(address),
    ]);

    return WalletAccount(
      address: address,
      mpcBalance: results[1] as double,
      network: _chain.config.networkLabel,
      transactions: (results[2] as List).cast<WalletTransaction>(),
      allocations: const {},
      bnbBalance: results[0] as double,
    );
  }
}
