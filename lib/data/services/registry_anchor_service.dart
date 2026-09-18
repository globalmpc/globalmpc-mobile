import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/crypto.dart' show bytesToHex;
import 'package:web3dart/web3dart.dart';

import '../../core/constants/chain_config.dart';

enum RegistryBatchStatus { active, revoked, superseded }

/// One anchored batch of registry records, exactly as the contract stores
/// it. Leaves are commitments: the app can show that a batch exists and when
/// it was fixed, never what its records contain.
@immutable
class RegistryBatch {
  const RegistryBatch({
    required this.batchId,
    required this.root,
    required this.manifestHash,
    required this.recordCount,
    required this.submittedAt,
    required this.revoked,
    this.supersededBy,
  });

  final String batchId;
  final String root;
  final String manifestHash;
  final int recordCount;
  final DateTime submittedAt;
  final bool revoked;
  final String? supersededBy;

  RegistryBatchStatus get status {
    if (revoked) return RegistryBatchStatus.revoked;
    if (supersededBy != null) return RegistryBatchStatus.superseded;
    return RegistryBatchStatus.active;
  }
}

@immutable
class RegistryFeed {
  const RegistryFeed({required this.batchCount, required this.latest});

  /// Total batches ever anchored. Batches are never deleted, so this only
  /// grows.
  final int batchCount;

  /// Most recent batches, newest first.
  final List<RegistryBatch> latest;

  bool get isEmpty => batchCount == 0;
}

/// Read-only view of the registry anchor contract.
///
/// Reads go through `eth_call` on the contract's own index, never through
/// log scans, so the feed works on public RPC endpoints that cap or refuse
/// wide `eth_getLogs` ranges.
class RegistryAnchorService {
  RegistryAnchorService({
    required this.config,
    required this.anchorAddress,
    http.Client? client,
    this.pageSize = 10,
  }) : _client = Web3Client(config.rpcUrl, client ?? http.Client());

  static const _abi = '''
[
  {"inputs":[],"name":"batchCount",
   "outputs":[{"name":"","type":"uint256"}],"stateMutability":"view","type":"function"},
  {"inputs":[{"name":"index","type":"uint256"}],"name":"batchIdAt",
   "outputs":[{"name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},
  {"inputs":[{"name":"batchId","type":"bytes32"}],"name":"getBatch",
   "outputs":[{"components":[
      {"name":"root","type":"bytes32"},
      {"name":"manifestHash","type":"bytes32"},
      {"name":"recordCount","type":"uint32"},
      {"name":"submittedAt","type":"uint64"},
      {"name":"revoked","type":"bool"},
      {"name":"supersededBy","type":"bytes32"}],
     "name":"","type":"tuple"}],
   "stateMutability":"view","type":"function"}
]''';

  final ChainConfig config;
  final String anchorAddress;
  final int pageSize;
  final Web3Client _client;

  late final DeployedContract _contract = DeployedContract(
    ContractAbi.fromJson(_abi, 'RegistryAnchor'),
    EthereumAddress.fromHex(anchorAddress),
  );

  String get explorerUrl => config.explorerAddressUrl(anchorAddress);

  Future<RegistryFeed> fetchLatest() async {
    final count = (await _call('batchCount')).first as BigInt;
    final total = count.toInt();
    if (total == 0) return const RegistryFeed(batchCount: 0, latest: []);

    final first = total - 1;
    final last = total > pageSize ? total - pageSize : 0;
    final batches = await Future.wait([
      for (var index = first; index >= last; index--) _batchAt(index),
    ]);
    return RegistryFeed(batchCount: total, latest: batches);
  }

  Future<RegistryBatch> _batchAt(int index) async {
    final id = (await _call('batchIdAt', [BigInt.from(index)])).first;
    final fields = (await _call('getBatch', [id])).first as List<dynamic>;
    final supersededBy = _hex(fields[5]);
    return RegistryBatch(
      batchId: _hex(id),
      root: _hex(fields[0]),
      manifestHash: _hex(fields[1]),
      recordCount: (fields[2] as BigInt).toInt(),
      submittedAt: DateTime.fromMillisecondsSinceEpoch(
        (fields[3] as BigInt).toInt() * 1000,
        isUtc: true,
      ),
      revoked: fields[4] as bool,
      supersededBy: supersededBy == _zeroHash ? null : supersededBy,
    );
  }

  Future<List<dynamic>> _call(String name, [List<dynamic> params = const []]) =>
      _client.call(
        contract: _contract,
        function: _contract.function(name),
        params: params,
      );

  static const _zeroHash =
      '0x0000000000000000000000000000000000000000000000000000000000000000';

  static String _hex(dynamic bytes) =>
      bytesToHex(bytes as Uint8List, include0x: true, padToEvenLength: true);

  void dispose() => _client.dispose();
}
