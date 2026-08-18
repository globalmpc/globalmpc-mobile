import 'package:http/http.dart' as http;
import 'package:web3dart/crypto.dart' show bytesToHex;
import 'package:web3dart/web3dart.dart';

import '../../core/constants/chain_config.dart';
import '../models/wallet_models.dart';

/// Thrown before signing when the account cannot pay gas (spec T9): the UI
/// must explain that sending MPC costs BNB, not fail inside the node.
class InsufficientGasException implements Exception {
  const InsufficientGasException(this.requiredBnb, this.availableBnb);

  final double requiredBnb;
  final double availableBnb;
}

/// Read/send access to the configured BSC network. Holds no keys: signing
/// credentials are passed in per call and only signed transactions leave
/// this class (spec T16).
class BscChainService {
  BscChainService(this.config)
    : _client = Web3Client(config.rpcUrl, http.Client());

  static const _erc20Abi = '''
[
  {"constant":true,"inputs":[{"name":"account","type":"address"}],
   "name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"type":"function"},
  {"constant":false,"inputs":[{"name":"to","type":"address"},{"name":"amount","type":"uint256"}],
   "name":"transfer","outputs":[{"name":"","type":"bool"}],"type":"function"},
  {"anonymous":false,"inputs":[
     {"indexed":true,"name":"from","type":"address"},
     {"indexed":true,"name":"to","type":"address"},
     {"indexed":false,"name":"value","type":"uint256"}],
   "name":"Transfer","type":"event"}
]''';

  final ChainConfig config;
  final Web3Client _client;

  DeployedContract? get _token {
    final address = config.mpcTokenAddress;
    if (address == null) return null;
    return DeployedContract(
      ContractAbi.fromJson(_erc20Abi, 'MPC'),
      EthereumAddress.fromHex(address),
    );
  }

  Future<double> bnbBalance(String address) async {
    final amount = await _client.getBalance(EthereumAddress.fromHex(address));
    return _toEth(amount.getInWei);
  }

  /// MPC balance of [address]; 0 when no test token is configured yet.
  Future<double> mpcBalance(String address) async {
    final token = _token;
    if (token == null) return 0;
    final result = await _client.call(
      contract: token,
      function: token.function('balanceOf'),
      params: [EthereumAddress.fromHex(address)],
    );
    return _toEth(result.first as BigInt);
  }

  /// Signs an MPC transfer locally and broadcasts it. Verifies gas funds
  /// first so failures are explained before anything is signed.
  Future<String> sendMpc({
    required EthPrivateKey credentials,
    required String to,
    required double amountMpc,
  }) async {
    final token = _token;
    if (token == null) {
      throw StateError('No test token configured for ${config.networkLabel}');
    }

    final sender = credentials.address;
    final gasPrice = await _client.getGasPrice();
    final transfer = Transaction.callContract(
      contract: token,
      function: token.function('transfer'),
      parameters: [EthereumAddress.fromHex(to), _toWei(amountMpc)],
    );

    final gasEstimate = await _client.estimateGas(
      sender: sender,
      to: transfer.to,
      data: transfer.data,
    );
    final feeWei = gasEstimate * gasPrice.getInWei;
    final balanceWei = (await _client.getBalance(sender)).getInWei;
    if (balanceWei < feeWei) {
      throw InsufficientGasException(_toEth(feeWei), _toEth(balanceWei));
    }

    return _client.sendTransaction(
      credentials,
      transfer,
      chainId: config.chainId,
    );
  }

  /// How far back a history query reaches. Public RPC providers reject or
  /// truncate unbounded `eth_getLogs` scans, so the range is explicit rather
  /// than left to default to genesis; on BSC's ~3s blocks this is roughly the
  /// last three days.
  static const int historyBlockWindow = 80000;

  /// Recent MPC Transfer history for [address], newest first, capped at
  /// [limit]. Best-effort: public RPC log limits or outages degrade to an
  /// empty list rather than breaking the wallet screen.
  Future<List<WalletTransaction>> recentTransfers(
    String address, {
    int limit = 10,
  }) async {
    final token = _token;
    if (token == null) return const [];
    try {
      final transferEvent = token.event('Transfer');
      final topic0 = bytesToHex(
        transferEvent.signature,
        include0x: true,
        padToEvenLength: true,
      );
      final addressTopic =
          '0x${address.substring(2).toLowerCase().padLeft(64, '0')}';

      final head = await _client.getBlockNumber();
      final from = BlockNum.exact(
        head > historyBlockWindow ? head - historyBlockWindow : 0,
      );
      final to = BlockNum.exact(head);

      final results = await Future.wait([
        _client.getLogs(
          FilterOptions(
            fromBlock: from,
            toBlock: to,
            address: token.address,
            topics: [
              [topic0],
              [addressTopic],
            ],
          ),
        ),
        _client.getLogs(
          FilterOptions(
            fromBlock: from,
            toBlock: to,
            address: token.address,
            topics: [
              [topic0],
              [],
              [addressTopic],
            ],
          ),
        ),
      ]);

      // A self-send matches both queries, and FilterEvent has no value
      // equality, so dedupe on the log's own identity rather than the object.
      final logs = <String, FilterEvent>{};
      for (final log in [...results[0], ...results[1]]) {
        logs['${log.transactionHash}:${log.logIndex}'] = log;
      }

      // Newest first means highest block, then highest log index within it.
      // The RPC returns ascending order and the two queries are interleaved,
      // so this cannot be left to insertion order.
      final ordered = logs.values.toList()
        ..sort((a, b) {
          final byBlock = (b.blockNum ?? 0).compareTo(a.blockNum ?? 0);
          return byBlock != 0
              ? byBlock
              : (b.logIndex ?? 0).compareTo(a.logIndex ?? 0);
        });
      final page = ordered.take(limit).toList();

      // Block timestamps are fetched only for the page actually shown, so the
      // cost stays bounded by [limit] rather than by history size.
      final timestamps = await _blockTimestamps(
        page.map((log) => log.blockNum).whereType<int>().toSet(),
      );

      return [
        for (final log in page)
          _toTransaction(
            log: log,
            event: transferEvent,
            address: address,
            timestamp: timestamps[log.blockNum],
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  WalletTransaction _toTransaction({
    required FilterEvent log,
    required ContractEvent event,
    required String address,
    required DateTime? timestamp,
  }) {
    final decoded = event.decodeResults(
      log.topics ?? const [],
      log.data ?? '0x',
    );
    final from = (decoded[0] as EthereumAddress).hexEip55;
    final outgoing = from.toLowerCase() == address.toLowerCase();
    final counterparty = outgoing
        ? (decoded[1] as EthereumAddress).hexEip55
        : from;
    return WalletTransaction(
      hash: log.transactionHash ?? '',
      kind: outgoing ? TxKind.send : TxKind.receive,
      direction: outgoing ? TxDirection.outgoing : TxDirection.incoming,
      amount: _toEth(decoded[2] as BigInt),
      counterparty: counterparty,
      // Falls back to now only if the block lookup failed, so a degraded
      // timestamp never blocks showing the transfer itself.
      timestamp: timestamp ?? DateTime.now(),
      networkFeeBnb: 0,
    );
  }

  Future<Map<int, DateTime>> _blockTimestamps(Set<int> blocks) async {
    final entries = await Future.wait(
      blocks.map((block) async {
        try {
          final info = await _client.getBlockInformation(
            blockNumber: BlockNum.exact(block).toBlockParam(),
            isContainFullObj: false,
          );
          return MapEntry(block, info.timestamp);
        } catch (_) {
          return null;
        }
      }),
    );
    return Map.fromEntries(entries.whereType<MapEntry<int, DateTime>>());
  }

  void dispose() => _client.dispose();

  static double _toEth(BigInt wei) => wei.toDouble() / 1e18;

  /// Converts a UI amount to wei without binary-float drift on the low
  /// digits: scale in decimal (micro-token precision), then shift.
  static BigInt _toWei(double amount) =>
      BigInt.from((amount * 1e6).round()) * BigInt.from(10).pow(12);
}
