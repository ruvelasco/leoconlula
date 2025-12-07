class SilabasModel {
  final String word;
  final String raeUrl;
  final List<String> syllables;
  final String stressed;
  final int stressedType;
  final int stressedLetter;
  final int numSyllables;
  final String hasTl;
  final String hasPrefix;

  SilabasModel({
    required this.word,
    required this.raeUrl,
    required this.syllables,
    required this.stressed,
    required this.stressedType,
    required this.stressedLetter,
    required this.numSyllables,
    required this.hasTl,
    required this.hasPrefix,
  });

  factory SilabasModel.fromJson(Map<String, dynamic> json) {
    return SilabasModel(
      word: json['word'] as String,
      raeUrl: json['raeUrl'] as String,
      syllables: List<String>.from(json['syllables'] ?? []),
      stressed: json['stressed'] as String,
      stressedType: json['stressedType'] as int,
      stressedLetter: json['stressedLetter'] as int,
      numSyllables: json['numSyllables'] as int,
      hasTl: json['hasTl'] as String,
      hasPrefix: json['hasPrefix'] as String,
    );
  }
}