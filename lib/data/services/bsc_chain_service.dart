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

/// Gas cost of a transfer as the node priced it at estimation time. The
/// final fee is settled by the chain; this is what the review screen shows
/// and what the pre-sign balance check uses.
class FeeEstimate {
  const FeeEstimate({required this.gasLimit, required this.gasPriceWei});

  final BigInt gasLimit;
  final BigInt gasPriceWei;

  BigInt get feeWei => gasLimit * gasPriceWei;
  double get feeBnb => BscChainService._toEth(feeWei);
}

/// Read/send access to the configured BSC network. Holds no keys: signing
/// credentials are passed in per call and only signed transactions leave
/// this class (spec T16).
class BscChainService {
  BscChainService(this.config, {http.Client? client})
    : _client = Web3Client(config.rpcUrl, client ?? http.Client());

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

  /// MPC balance of [address]; 0 when this build has no token configured.
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

  Transaction _transfer(DeployedContract token, String to, double amountMpc) =>
      Transaction.callContract(
        contract: token,
        function: token.function('transfer'),
        parameters: [EthereumAddress.fromHex(to), _toWei(amountMpc)],
      );

  /// Prices the transfer with the node before anything is signed, so the
  /// review screen shows the fee the chain will actually charge rather than a
  /// constant.
  Future<FeeEstimate> estimateTransferFee({
    required String from,
    required String to,
    required double amountMpc,
  }) async {
    final token = _token;
    if (token == null) {
      throw StateError('No token configured for ${config.networkLabel}');
    }
    final transfer = _transfer(token, to, amountMpc);
    final results = await Future.wait<Object>([
      _client.estimateGas(
        sender: EthereumAddress.fromHex(from),
        to: transfer.to,
        data: transfer.data,
      ),
      _client.getGasPrice(),
    ]);
    return FeeEstimate(
      gasLimit: results[0] as BigInt,
      gasPriceWei: (results[1] as EtherAmount).getInWei,
    );
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
      throw StateError('No token configured for ${config.networkLabel}');
    }

    final sender = credentials.address;
    final estimate = await estimateTransferFee(
      from: sender.hexEip55,
      to: to,
      amountMpc: amountMpc,
    );
    final balanceWei = (await _client.getBalance(sender)).getInWei;
    if (balanceWei < estimate.feeWei) {
      throw InsufficientGasException(estimate.feeBnb, _toEth(balanceWei));
    }

    return _client.sendTransaction(
      credentials,
      _transfer(token, to, amountMpc),
      chainId: config.chainId,
    );
  }

  /// Polls for the receipt of [hash] until it lands or [timeout] passes.
  /// Returns [TxStatus.pending] on timeout: the transaction may still be
  /// mined later, so the caller must not present it as failed.
  Future<TxStatus> waitForReceipt(
    String hash, {
    Duration timeout = const Duration(seconds: 90),
    Duration interval = const Duration(seconds: 3),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (true) {
      TransactionReceipt? receipt;
      try {
        receipt = await _client.getTransactionReceipt(hash);
      } catch (_) {
        // A transient RPC failure is not a verdict on the transaction.
      }
      if (receipt != null) {
        return receipt.status == true ? TxStatus.confirmed : TxStatus.failed;
      }
      if (DateTime.now().isAfter(deadline)) return TxStatus.pending;
      await Future<void>.delayed(interval);
    }
  }

  /// Recent MPC Transfer history for [address], newest first, capped at
  /// [limit]. When the provider rejects the log query or is unreachable the
  /// result is marked unavailable rather than returned as an empty history,
  /// so the wallet can say so instead of showing "no transactions".
  Future<TransferHistory> recentTransfers(
    String address, {
    int limit = 10,
  }) async {
    final token = _token;
    if (token == null) return TransferHistory.empty;
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
      final window = config.historyBlockWindow;
      final from = BlockNum.exact(head > window ? head - window : 0);
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

      return TransferHistory([
        for (final log in page)
          _toTransaction(
            log: log,
            event: transferEvent,
            address: address,
            timestamp: timestamps[log.blockNum],
          ),
      ]);
    } catch (_) {
      return TransferHistory.failed;
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
