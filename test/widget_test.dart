// Smoke tests for the MPC app.

import 'package:flutter_test/flutter_test.dart';
import 'package:mpc_mining_app/core/constants/earn_facts.dart';
import 'package:mpc_mining_app/core/constants/mpc_facts.dart';
import 'package:mpc_mining_app/core/localization/app_strings.dart';
import 'package:mpc_mining_app/core/localization/strings/en.dart';
import 'package:mpc_mining_app/core/localization/strings/ko.dart';
import 'package:mpc_mining_app/core/localization/strings/mn.dart';
import 'package:mpc_mining_app/core/localization/strings/zh.dart';
import 'package:mpc_mining_app/core/utils/formatters.dart';
import 'package:mpc_mining_app/data/repositories/mock_mpc_repository.dart';

void main() {
  test('formatters render expected shapes', () {
    expect(Fmt.compact(10000000000), '10B');
    expect(Fmt.grouped(10000000000), '10,000,000,000');
    expect(
      Fmt.shortAddress('0x1234567890abcdef1234567890abcdef12345678'),
      '0x1234…5678',
    );
    expect(Fmt.percent(0.42), '42%');
  });

  test('MPC facts stay pinned to the published token', () {
    expect(MpcFacts.totalSupply, 10000000000);
    // The chain of record is what the whitepaper publishes. Changing it
    // requires an explicit decision, not a drive-by edit; this is the
    // tripwire. The contract address is build configuration, never a fact
    // in source.
    expect(MpcFacts.network, 'BNB Smart Chain');
    expect(MpcFacts.infraStack.length, 4);
  });

  test('mock repository returns grounded projects and wallet', () async {
    const repo = MockMpcRepository();

    final projects = await repo.fetchProjects();
    expect(projects, isNotEmpty);
    expect(projects.first.id, 'tsagaan-tolgoi');

    final byId = await repo.fetchProject('tsagaan-tolgoi');
    expect(byId, isNotNull);
    // Four layer statuses, no fabricated percentages.
    expect(byId!.pipeline.length, 4);
    // Whitepaper 2.1: no layer may read "Secured" before an independent
    // Competent Person signed report exists. This test pins that rule.
    expect(byId.securedLayers, 0);

    final wallet = await repo.fetchWallet();
    expect(wallet.mpcBalance, greaterThan(0));
    expect(wallet.allocatedTotal, greaterThan(0));
  });

  test('Earn is honest — planned capabilities, no invented rate', () {
    // Staking + farming, both gated on KYC + listing.
    expect(
      EarnFacts.programs.map((p) => p.id),
      containsAll(['staking', 'farming']),
    );
    expect(EarnFacts.gates.map((g) => g.id), containsAll(['kyc', 'listing']));

    // Honesty rule: the reward figure must never quote a number pre-listing.
    for (final code in ['en', 'ko', 'mn']) {
      final rate = AppStrings.get(code, 'earn.ratePending');
      expect(rate, isNotEmpty);
      expect(
        rate,
        isNot(matches(RegExp(r'\d'))),
        reason: 'earn.ratePending[$code] must not show a numeric rate',
      );
    }
  });

  test('localization covers project and layer keys in every language', () {
    const keys = [
      'proj.tsagaan.name',
      'proj.additional.name',
      'facts.tagline',
      'layer.resource.title',
      'layer.capital.title',
      'verify.jorc',
      'scope.onChain',
      'tx.issuance',
    ];
    for (final code in ['en', 'ko', 'mn', 'zh']) {
      for (final key in keys) {
        final value = AppStrings.get(code, key);
        expect(value, isNot(equals(key)), reason: 'missing $key for $code');
        expect(value, isNotEmpty);
      }
    }
    expect(
      AppStrings.get('ko', 'proj.tsagaan.name'),
      isNot(contains('Tsagaan')),
    );
    expect(
      AppStrings.get('ko', 'layer.resource.title'),
      isNot(equals('Resource Layer')),
    );
  });

  test('every locale carries every key (A4 gate: no missing keys)', () {
    final locales = {'ko': koStrings, 'mn': mnStrings, 'zh': zhStrings};
    for (final entry in locales.entries) {
      final missing = enStrings.keys
          .where((k) => !entry.value.containsKey(k))
          .toList();
      expect(
        missing,
        isEmpty,
        reason: '${entry.key} is missing keys: $missing',
      );
    }
  });

  test('forbidden yield wording never appears (A4 gate, whitepaper App. D)', () {
    // Appendix D bans these outright; the CI gate makes the ban structural.
    const banned = [
      'guaranteed',
      'fixed yield',
      '100% redeemable',
      '원금 보장',
      '확정 수익',
      '100% 상환',
    ];
    final locales = {
      'en': enStrings,
      'ko': koStrings,
      'mn': mnStrings,
      'zh': zhStrings,
    };
    for (final locale in locales.entries) {
      for (final kv in locale.value.entries) {
        final value = kv.value.toLowerCase();
        for (final phrase in banned) {
          expect(
            value.contains(phrase.toLowerCase()),
            isFalse,
            reason:
                '"${kv.key}" in ${locale.key} contains banned phrase "$phrase"',
          );
        }
      }
    }
  });
}
