import 'dart:math';

List<int> pickPhraseCheckIndices(int wordCount, int count) =>
    (List<int>.generate(
      wordCount,
      (i) => i,
    )..shuffle(Random.secure())).take(count).toList()..sort();

bool phraseCheckMatches({
  required List<String> words,
  required List<int> indices,
  required List<String> answers,
}) => [
  for (var i = 0; i < indices.length; i++)
    answers[i].trim().toLowerCase() == words[indices[i]].toLowerCase(),
].every((match) => match);
