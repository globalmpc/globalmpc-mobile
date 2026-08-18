import '../models/mining_project.dart';
import '../models/wallet_models.dart';

/// Data boundary for the app. Screens depend on this interface only, so the
/// mock source can be swapped for real BSC / API calls later without touching
/// the UI or providers.
abstract interface class MpcRepository {
  Future<List<MiningProject>> fetchProjects();
  Future<MiningProject?> fetchProject(String id);
  Future<WalletAccount> fetchWallet();
}
