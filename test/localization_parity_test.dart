import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpc_mining_app/core/localization/strings/en.dart';
import 'package:mpc_mining_app/core/localization/strings/ko.dart';
import 'package:mpc_mining_app/core/localization/strings/mn.dart';
import 'package:mpc_mining_app/core/localization/strings/zh.dart';

/// English is the source of truth; every shipped language must carry the
/// same keys with the same placeholders, and every key must be referenced by
/// the code. A missing key falls back to English silently at runtime, which
/// is exactly the kind of drift this test exists to catch before release.
void main() {
  final tables = <String, Map<String, String>>{
    'ko': koStrings,
    'zh': zhStrings,
    'mn': mnStrings,
  };
  final placeholder = RegExp(r'\{[a-zA-Z]+\}');

  test('every language has exactly the English key set', () {
    final english = enStrings.keys.toSet();
    tables.forEach((code, table) {
      final keys = table.keys.toSet();
      expect(
        english.difference(keys),
        isEmpty,
        reason: '$code is missing keys present in English',
      );
      expect(
        keys.difference(english),
        isEmpty,
        reason: '$code has keys that English does not define',
      );
    });
  });

  test('placeholders match English in every language', () {
    enStrings.forEach((key, value) {
      final expected = placeholder
          .allMatches(value)
          .map((m) => m.group(0))
          .toSet();
      tables.forEach((code, table) {
        final actual = placeholder
            .allMatches(table[key] ?? '')
            .map((m) => m.group(0))
            .toSet();
        expect(actual, expected, reason: '$code $key');
      });
    });
  });

  test('no value is empty', () {
    for (final entry in {'en': enStrings, ...tables}.entries) {
      entry.value.forEach((key, value) {
        expect(value.trim(), isNotEmpty, reason: '${entry.key} $key');
      });
    }
  });

  test('every English key is referenced from lib/', () {
    final source = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (f) =>
              f.path.endsWith('.dart') &&
              !f.path.contains(
                '${Platform.pathSeparator}strings${Platform.pathSeparator}',
              ),
        )
        .map((f) => f.readAsStringSync())
        .join('\n');

    /// Keys assembled at runtime from an id, e.g. `earn.${program.id}.title`.
    bool builtDynamically(String key) =>
        key.startsWith('earn.') ||
        key.startsWith('proj.tsagaan.') ||
        key.startsWith('proj.additional.') ||
        key.startsWith('geo.') ||
        key.startsWith('commodity.') ||
        key.startsWith('stage.') ||
        key.startsWith('status.') ||
        key.startsWith('layer.') ||
        key.startsWith('risk.') ||
        key.startsWith('partner.') ||
        key.startsWith('verify.') ||
        key.startsWith('scope.') ||
        key.startsWith('tx.') ||
        key.startsWith('notif.') ||
        key.startsWith('theme.') ||
        key.startsWith('wallet.tx.') ||
        key.startsWith('lang.');

    /// Keys that were already unreferenced when this rule was introduced.
    /// They are tolerated, not endorsed: remove an entry here the moment its
    /// key is deleted from the tables, and never add to this list.
    const legacy = {
      'app.category',
      'app.tagline',
      'common.comingSoon',
      'common.inProgress',
      'dash.addFunds',
      'onboard.enter',
      'onboard.b1.title',
      'onboard.b1.body',
      'onboard.b2.title',
      'onboard.b2.body',
      'onboard.b3.title',
      'onboard.b3.body',
      'proj.readiness',
      'proj.allocated',
      'proj.productionTrend',
      'proj.overall',
      'proj.allocatedSupply',
      'proj.hold',
      'proj.betaHold',
      'settings.profile',
      'settings.helpSupport',
      'settings.reveal.title',
      'settings.reveal.privacyNote',
      'settings.reveal.warning',
      'settings.reveal.stored',
      'tour.actions.title',
      'tour.actions.body',
      'unlock.pinPrivacy',
      'wallet.totalBalance',
      'wallet.demoNotice',
      'wallet.transfersLater',
      'wallet.create.step1.phraseLabel',
      'wallet.secure.failed',
      'wallet.secure.noData',
      'wallet.secure.unavailable',
      'wallet.secure.checkSettings',
      'wallet.secure.retry',
      'wallet.secure.returnWelcome',
    };

    final unused = enStrings.keys
        .where((key) => !builtDynamically(key) && !source.contains("'$key'"))
        .where((key) => !legacy.contains(key))
        .toList();
    expect(unused, isEmpty, reason: 'unreferenced localization keys');

    final stale = legacy.where((key) => !enStrings.containsKey(key)).toList();
    expect(stale, isEmpty, reason: 'legacy entries whose key no longer exists');
  });
}
