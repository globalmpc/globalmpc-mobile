import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpc_mining_app/core/localization/app_strings.dart';
import 'package:mpc_mining_app/core/localization/strings/en.dart';
import 'package:mpc_mining_app/core/localization/strings/ko.dart';
import 'package:mpc_mining_app/core/localization/strings/mn.dart';
import 'package:mpc_mining_app/core/localization/strings/zh.dart';

/// Enforces the product definition structurally, so it cannot drift back by a
/// copy edit.
///
/// MPC is a non-custodial wallet for the mining-tokenization ecosystem and has
/// no single-country product boundary. A country may still be named, but only
/// as the location of a specific asset — the `geo.*` namespace. Any other
/// string that names a country is stating that the *product* is bound to it,
/// which is what these tests reject.
///
/// The mirror rule matters just as much: Mongolian localization and Mongolian
/// asset geography are supported and must stay that way. Deleting them is not
/// the fix for the rule above, so they are asserted here too.
void main() {
  final tables = <String, Map<String, String>>{
    'en': enStrings,
    'ko': koStrings,
    'mn': mnStrings,
    'zh': zhStrings,
  };

  /// Every way the four shipped languages can name the country. Matches
  /// inflected Korean and Mongolian forms by prefix (몽골의, Монголын, …).
  final country = RegExp('Mongolia|몽골|Монгол|蒙古', caseSensitive: false);

  /// The only namespace allowed to name a country: an asset's location.
  bool statesAssetLocation(String key) => key.startsWith('geo.');

  test('no product-level string binds MPC to one country', () {
    final found = <String>[];
    tables.forEach((code, table) {
      table.forEach((key, value) {
        if (statesAssetLocation(key)) return;
        if (country.hasMatch(value)) found.add('$code  $key  "$value"');
      });
    });

    expect(
      found,
      isEmpty,
      reason:
          'MPC has no single-country product boundary. A country belongs in '
          'the geo.* namespace, as the location of one asset, not in a string '
          'that says what the product is.\n\nFound:\n${found.join('\n')}',
    );
  });

  test('the package description states the product, not a country', () {
    final description = RegExp(
      r'^description:\s*"(.+)"',
      multiLine: true,
    ).firstMatch(File('pubspec.yaml').readAsStringSync())?.group(1);

    expect(description, isNotNull, reason: 'pubspec.yaml has no description');
    expect(
      country.hasMatch(description!),
      isFalse,
      reason: 'the published package description names a country: $description',
    );
    expect(description.toLowerCase(), contains('non-custodial wallet'));
  });

  test('the README headline states the product, not a country', () {
    final heading = File('README.md')
        .readAsLinesSync()
        .firstWhere((line) => line.startsWith('# '));

    expect(
      country.hasMatch(heading),
      isFalse,
      reason: 'the README headline names a country: $heading',
    );
  });

  test('the README cites the published whitepaper, not internal plans', () {
    final readme = File('README.md').readAsStringSync();
    expect(readme.contains('globalmpc.tech'), isTrue);
    expect(
      readme.toLowerCase().contains('notion'),
      isFalse,
      reason:
          'this README is mirrored publicly; do not point at internal plans',
    );
  });

  test('Mongolian asset geography stays supported', () {
    for (final code in tables.keys) {
      final value = AppStrings.get(code, 'geo.mongolia');
      expect(value, isNot(equals('geo.mongolia')), reason: 'missing for $code');
      expect(value, isNotEmpty);
    }
  });

  test('Mongolian stays a shipped app language', () {
    expect(
      AppLanguage.values.map((l) => l.locale.languageCode),
      contains('mn'),
    );
  });

  test('token supply is labelled planned in every locale', () {
    for (final code in tables.keys) {
      final label = AppStrings.get(code, 'dash.totalSupply');
      expect(label, isNot(equals('dash.totalSupply')), reason: code);
      expect(
        label.toLowerCase(),
        anyOf(contains('planned'), contains('계획'), contains('төлөвлөсөн'), contains('计划')),
        reason: '$code dash.totalSupply must mark supply as planned, got "$label"',
      );
    }
  });
}
