import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mpc_mining_app/core/constants/chain_config.dart';
import 'package:mpc_mining_app/data/services/registry_anchor_service.dart';
import 'package:web3dart/crypto.dart';

/// Drives the registry reader against a scripted JSON-RPC endpoint, so the
/// ABI wiring (selectors, tuple decoding, ordering) is verified without a
/// network and without a deployed contract.
void main() {
  const anchor = '0x0000000000000000000000000000000000000002';
  const config = ChainConfig(
    chainId: 97,
    rpcUrl: 'https://rpc.example',
    explorerBase: 'https://explorer.example',
    networkLabel: 'Example Testnet',
  );

  String selector(String signature) =>
      bytesToHex(keccakUtf8(signature).sublist(0, 4), include0x: true);

  String word(BigInt value) => value.toRadixString(16).padLeft(64, '0');
  String bytes32(int seed) => seed.toRadixString(16).padLeft(64, '0');

  final ids = [bytes32(0xa1), bytes32(0xa2), bytes32(0xa3)];

  /// Batch 0 was superseded by batch 1; batch 2 is revoked.
  String batch(int index) {
    final supersededBy = index == 0 ? ids[1] : bytes32(0);
    return '0x'
        '${bytes32(0x100 + index)}' // root
        '${bytes32(0x200 + index)}' // manifestHash
        '${word(BigInt.from(10 + index))}' // recordCount
        '${word(BigInt.from(1_700_000_000 + index * 3600))}' // submittedAt
        '${word(BigInt.from(index == 2 ? 1 : 0))}' // revoked
        '$supersededBy';
  }

  http.Client scripted() => MockClient((request) async {
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    final params = body['params'] as List<dynamic>;
    final call = params.first as Map<String, dynamic>;
    final data = (call['data'] as String).toLowerCase();
    expect(call['to'].toString().toLowerCase(), anchor);
    expect(body['method'], 'eth_call');

    String result;
    if (data.startsWith(selector('batchCount()'))) {
      result = '0x${word(BigInt.from(ids.length))}';
    } else if (data.startsWith(selector('batchIdAt(uint256)'))) {
      final index = int.parse(data.substring(10), radix: 16);
      result = '0x${ids[index]}';
    } else if (data.startsWith(selector('getBatch(bytes32)'))) {
      final id = data.substring(10);
      result = batch(ids.indexOf(id));
    } else {
      fail('unexpected call $data');
    }
    return http.Response(
      jsonEncode({'jsonrpc': '2.0', 'id': body['id'], 'result': result}),
      200,
      headers: {'content-type': 'application/json'},
    );
  });

  test('reads the newest batches first with their status', () async {
    final service = RegistryAnchorService(
      config: config,
      anchorAddress: anchor,
      client: scripted(),
      pageSize: 2,
    );

    final feed = await service.fetchLatest();

    expect(feed.batchCount, 3);
    expect(feed.latest.map((b) => b.batchId), ['0x${ids[2]}', '0x${ids[1]}']);
    final newest = feed.latest.first;
    expect(newest.recordCount, 12);
    expect(newest.revoked, isTrue);
    expect(newest.status, RegistryBatchStatus.revoked);
    expect(newest.supersededBy, isNull);
    expect(
      newest.submittedAt,
      DateTime.fromMillisecondsSinceEpoch(
        (1_700_000_000 + 7200) * 1000,
        isUtc: true,
      ),
    );
    expect(feed.latest[1].status, RegistryBatchStatus.active);
    expect(feed.latest[1].root, '0x${bytes32(0x101)}');
    expect(feed.latest[1].manifestHash, '0x${bytes32(0x201)}');
  });

  test('a superseded batch points at its replacement', () async {
    final service = RegistryAnchorService(
      config: config,
      anchorAddress: anchor,
      client: scripted(),
      pageSize: 10,
    );

    final feed = await service.fetchLatest();

    expect(feed.latest.length, 3);
    final oldest = feed.latest.last;
    expect(oldest.status, RegistryBatchStatus.superseded);
    expect(oldest.supersededBy, '0x${ids[1]}');
  });

  test('an empty registry reads as empty, not as an error', () async {
    final service = RegistryAnchorService(
      config: config,
      anchorAddress: anchor,
      client: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': body['id'],
            'result': '0x${word(BigInt.zero)}',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final feed = await service.fetchLatest();

    expect(feed.isEmpty, isTrue);
    expect(feed.latest, isEmpty);
    expect(service.explorerUrl, 'https://explorer.example/address/$anchor');
  });
}
