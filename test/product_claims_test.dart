import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces two product commitments stated in the README.
///
/// - "The app publishes no price": no fiat amount or conversion may be
///   rendered by the UI. Showing one requires a live price source and an
///   explicit product decision, not a constant.
/// - Demo data never masquerades as user data: feature screens must not
///   hardcode wallet-address placeholders a user could read as their own.
///   Loading and error states use explicit labels, and demo values live in
///   the clearly labelled mock repository.
///
/// Failures print the exact file and line so the fix is a one-line edit.
void main() {
  final root = Directory.current;

  List<File> dartFilesUnder(String dir) {
    final target = Directory('${root.path}/$dir');
    if (!target.existsSync()) return const [];
    return target
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
  }

  String relative(File file) =>
      file.path.replaceFirst('${root.path}${Platform.pathSeparator}', '');

  List<String> hits(RegExp pattern, Iterable<File> files) {
    final found = <String>[];
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (pattern.hasMatch(lines[i])) {
          found.add('${relative(file)}:${i + 1}  ${lines[i].trim()}');
        }
      }
    }
    return found;
  }

  test('the UI renders no fiat price or conversion', () {
    final found = hits(
      RegExp(r'\\\$\d|\\\$\{|USD|usdValue|\bfiat\b'),
      dartFilesUnder('lib'),
    );
    expect(
      found,
      isEmpty,
      reason:
          'The README commits to publishing no price. Show token amounts '
          'only.\n\nFound at:\n${found.join('\n')}',
    );
  });

  test('feature screens hardcode no placeholder wallet address', () {
    final found = hits(
      RegExp("'0x[0-9a-fA-F]{2,}…[0-9a-fA-F]+'"),
      dartFilesUnder('lib/features'),
    );
    expect(
      found,
      isEmpty,
      reason:
          'Derive addresses from state, or show an explicit loading or '
          'unavailable label.\n\nFound at:\n${found.join('\n')}',
    );
  });
}
