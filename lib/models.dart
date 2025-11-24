import 'dart:convert';

class AppSettings {
  String provider; // 'gemini' or 'local'
  String localApiUrl;
  String localModelName;
  String geminiApiKey;
  List<String> savedModels; // Saved history for local models

  AppSettings({
    this.provider = 'gemini',
    this.localApiUrl = 'http://localhost:11434/v1/chat/completions',
    this.localModelName = 'llama3',
    this.geminiApiKey = '',
    this.savedModels = const ['llama3', 'mistral', 'gemma', 'qwen2'],
  });

  Map<String, dynamic> toJson() => {
        'provider': provider,
        'localApiUrl': localApiUrl,
        'localModelName': localModelName,
        'geminiApiKey': geminiApiKey,
        'savedModels': savedModels,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      provider: json['provider'] ?? 'gemini',
      localApiUrl:
          json['localApiUrl'] ?? 'http://localhost:11434/v1/chat/completions',
      localModelName: json['localModelName'] ?? 'llama3',
      geminiApiKey: json['geminiApiKey'] ?? '',
      savedModels: (json['savedModels'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['llama3', 'mistral', 'gemma', 'qwen2'],
    );
  }
}

class EtymologyPart {
  final String part;
  final String meaning;
  final String originLanguage;

  EtymologyPart(
      {required this.part,
      required this.meaning,
      required this.originLanguage});

  factory EtymologyPart.fromJson(Map<String, dynamic> json) {
    return EtymologyPart(
      part: json['part'] ?? '',
      meaning: json['meaning'] ?? '',
      originLanguage: json['originLanguage'] ?? '',
    );
  }
}

class HistoryEvent {
  final String era;
  final String meaning;
  final String description;

  HistoryEvent(
      {required this.era, required this.meaning, required this.description});

  factory HistoryEvent.fromJson(Map<String, dynamic> json) {
    return HistoryEvent(
      era: json['era'] ?? '',
      meaning: json['meaning'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class Cognate {
  final String word;
  final String pronunciation;
  final String relation;
  final String definition;

  Cognate(
      {required this.word,
      required this.pronunciation,
      required this.relation,
      required this.definition});

  factory Cognate.fromJson(Map<String, dynamic> json) {
    return Cognate(
      word: json['word'] ?? '',
      pronunciation: json['pronunciation'] ?? '',
      relation: json['relation'] ?? '',
      definition: json['definition'] ?? '',
    );
  }
}

class ExampleUsage {
  final String context;
  final String sentence;
  final String explanation;

  ExampleUsage(
      {required this.context,
      required this.sentence,
      required this.explanation});

  factory ExampleUsage.fromJson(Map<String, dynamic> json) {
    return ExampleUsage(
      context: json['context'] ?? '',
      sentence: json['sentence'] ?? '',
      explanation: json['explanation'] ?? '',
    );
  }
}

class Etymology {
  final String root;
  final List<EtymologyPart> parts;
  final String description;

  Etymology(
      {required this.root, required this.parts, required this.description});

  factory Etymology.fromJson(Map<String, dynamic> json) {
    return Etymology(
      root: json['root'] ?? '',
      parts: (json['parts'] as List<dynamic>?)
              ?.map((e) => EtymologyPart.fromJson(e))
              .toList() ??
          [],
      description: json['description'] ?? '',
    );
  }
}

class WordAnalysis {
  final String word;
  final String pronunciation;
  final String basicDefinition;
  final Etymology etymology;
  final List<HistoryEvent> history;
  final List<Cognate> cognates;
  final List<ExampleUsage> examples;

  WordAnalysis({
    required this.word,
    required this.pronunciation,
    required this.basicDefinition,
    required this.etymology,
    required this.history,
    required this.cognates,
    required this.examples,
  });

  factory WordAnalysis.fromJson(Map<String, dynamic> json) {
    return WordAnalysis(
      word: json['word'] ?? '',
      pronunciation: json['pronunciation'] ?? '',
      basicDefinition: json['basicDefinition'] ?? '',
      etymology: Etymology.fromJson(json['etymology'] ?? {}),
      history: (json['history'] as List<dynamic>?)
              ?.map((e) => HistoryEvent.fromJson(e))
              .toList() ??
          [],
      cognates: (json['cognates'] as List<dynamic>?)
              ?.map((e) => Cognate.fromJson(e))
              .toList() ??
          [],
      examples: (json['examples'] as List<dynamic>?)
              ?.map((e) => ExampleUsage.fromJson(e))
              .toList() ??
          [],
    );
  }
}
