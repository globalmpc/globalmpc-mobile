import 'package:flutter_test/flutter_test.dart';
import 'package:mpc_mining_app/core/config/app_environment.dart';
import 'package:mpc_mining_app/core/constants/chain_config.dart';

/// The environment file is the only way a binary learns which network and
/// token it serves, so its parsing rules are pinned here: a prod build can
/// never fall back to a development network, and a malformed value fails
/// the build rather than shipping.
void main() {
  const token = '0x0000000000000000000000000000000000000001';

  test('no defines resolve to the dev testnet without a token', () {
    final env = AppEnvironment.fromValues(const {});
    expect(env.build, BuildEnvironment.dev);
    expect(env.isProduction, isFalse);
    expect(env.chain.chainId, ChainConfig.bscTestnet.chainId);
    expect(env.chain.rpcUrl, ChainConfig.bscTestnet.rpcUrl);
    expect(env.chain.networkLabel, ChainConfig.bscTestnet.networkLabel);
    expect(env.chain.hasToken, isFalse);
    expect(env.chain.isMainnet, isFalse);
    expect(env.hasRegistry, isFalse);
    expect(env.hasPresale, isFalse);
    expect(env.hasStoreListing, isFalse);
    expect(env.termsUrl, startsWith('https://'));
    expect(env.privacyUrl, startsWith('https://'));
  });

  test('prod uses the mainnet defaults and the configured token', () {
    final env = AppEnvironment.fromValues(const {
      'MPC_ENV': 'production',
      'MPC_TOKEN_ADDRESS': token,
    });
    expect(env.build, BuildEnvironment.prod);
    expect(env.chain.chainId, 56);
    expect(env.chain.isMainnet, isTrue);
    expect(env.chain.networkShort, 'BSC');
    expect(env.chain.mpcTokenAddress, token);
    expect(env.chain.explorerBase, ChainConfig.bscMainnet.explorerBase);
  });

  test('prod refuses to build without a token address', () {
    expect(
      () => AppEnvironment.fromValues(const {'MPC_ENV': 'prod'}),
      throwsA(isA<StateError>()),
    );
  });

  test('prod refuses any chain but mainnet', () {
    expect(
      () => AppEnvironment.fromValues(const {
        'MPC_ENV': 'prod',
        'MPC_CHAIN_ID': '97',
        'MPC_TOKEN_ADDRESS': token,
      }),
      throwsA(isA<StateError>()),
    );
  });

  test('dev refuses the mainnet chain id', () {
    expect(
      () => AppEnvironment.fromValues(const {
        'MPC_ENV': 'dev',
        'MPC_CHAIN_ID': '56',
      }),
      throwsA(isA<StateError>()),
    );
  });

  test('explicit values override the defaults', () {
    final env = AppEnvironment.fromValues(const {
      'MPC_ENV': 'develop',
      'MPC_CHAIN_ID': '97',
      'MPC_RPC_URL': 'https://rpc.example',
      'MPC_EXPLORER_URL': 'https://explorer.example',
      'MPC_NETWORK_LABEL': 'Example Testnet',
      'MPC_TOKEN_ADDRESS': token,
      'MPC_REGISTRY_ANCHOR_ADDRESS': token,
      'MPC_HISTORY_BLOCK_WINDOW': '5000',
      'MPC_PRESALE_URL': 'https://presale.example',
      'MPC_STORE_URL': 'https://store.example/app',
    });
    expect(env.chain.rpcUrl, 'https://rpc.example');
    expect(env.chain.explorerBase, 'https://explorer.example');
    expect(env.chain.networkLabel, 'Example Testnet');
    // A non-mainnet chain is named by its own label, never by a fixed one.
    expect(env.chain.networkShort, 'Example Testnet');
    expect(env.chain.historyBlockWindow, 5000);
    expect(
      env.chain.explorerTxUrl('0xabc'),
      'https://explorer.example/tx/0xabc',
    );
    expect(env.registryAnchorAddress, token);
    expect(env.presaleUrl, 'https://presale.example');
    expect(env.storeUrl, 'https://store.example/app');
  });

  test('malformed values fail instead of being ignored', () {
    expect(
      () => AppEnvironment.fromValues(const {'MPC_ENV': 'staging'}),
      throwsA(isA<StateError>()),
    );
    expect(
      () => AppEnvironment.fromValues(const {'MPC_TOKEN_ADDRESS': '0x1234'}),
      throwsA(isA<StateError>()),
    );
    expect(
      () => AppEnvironment.fromValues(const {
        'MPC_PRESALE_URL': 'http://presale.example',
      }),
      throwsA(isA<StateError>()),
    );
    expect(
      () => AppEnvironment.fromValues(const {'MPC_CHAIN_ID': 'chapel'}),
      throwsA(isA<StateError>()),
    );
    expect(
      () => AppEnvironment.fromValues(const {'MPC_HISTORY_BLOCK_WINDOW': '0'}),
      throwsA(isA<StateError>()),
    );
  });

  test('the source tree carries no token contract address', () {
    // The token is supplied by the environment file of each build. Nothing
    // in lib/ may hardcode one, or the environment stops being the source
    // of truth.
    final env = AppEnvironment.fromValues(const {});
    expect(env.chain.mpcTokenAddress, isNull);
    expect(ChainConfig.bscTestnet.mpcTokenAddress, isNull);
    expect(ChainConfig.bscMainnet.mpcTokenAddress, isNull);
  });
}
