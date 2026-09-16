import 'package:flutter_test/flutter_test.dart';
import 'package:mpc_mining_app/core/security/phrase_check.dart';

void main() {
  group('pickPhraseCheckIndices', () {
    test('picks distinct in-range positions, ascending', () {
      for (var round = 0; round < 50; round++) {
        final picked = pickPhraseCheckIndices(12, 3);
        expect(picked.length, 3);
        expect(picked.toSet().length, 3, reason: 'positions must be distinct');
        expect(picked.every((i) => i >= 0 && i < 12), isTrue);
        expect(picked, equals([...picked]..sort()));
      }
    });
  });

  group('phraseCheckMatches', () {
    const words = ['legal', 'winner', 'thank', 'year'];

    test('accepts the real words at their positions', () {
      expect(
        phraseCheckMatches(
          words: words,
          indices: [1, 3],
          answers: ['winner', 'year'],
        ),
        isTrue,
      );
    });

    test('absorbs case and whitespace artefacts', () {
      expect(
        phraseCheckMatches(words: words, indices: [0], answers: ['  Legal ']),
        isTrue,
      );
    });

    test('rejects a phrase word typed at the wrong position', () {
      expect(
        phraseCheckMatches(words: words, indices: [1], answers: ['legal']),
        isFalse,
      );
    });
  });
}
