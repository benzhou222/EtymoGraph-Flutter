import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models.dart';

class AIService {
  static const String _jsonPromptTemplate = '''
You are a etymology analysis tool. Respond ONLY with valid JSON. Do not include any markdown formatting, backticks, or explanations.
The JSON structure must match this structure exactly:
{
  "word": "string",
  "pronunciation": "string (IPA)",
  "basicDefinition": "string (Simplified Chinese)",
  "etymology": {
    "root": "string",
    "parts": [{"part": "string", "meaning": "string", "originLanguage": "string"}],
    "description": "string (Simplified Chinese)"
  },
  "history": [{"era": "string", "meaning": "string", "description": "string"}],
  "cognates": [{"word": "string", "pronunciation": "string", "relation": "string (Detailed etymological analysis: explain how root + affixes combine)", "definition": "string"}],
  "examples": [{"context": "string", "sentence": "string (Original English, DO NOT TRANSLATE)", "explanation": "string (Simplified Chinese usage analysis)"}]
}
''';

  Future<WordAnalysis> analyzeWord(
      String word, List<String> history, AppSettings settings) async {
    // 1. Prepare Context from History (Limit to 8 to avoid context overflow)
    final recentWords = history
        .where((w) => w.toLowerCase() != word.toLowerCase())
        .take(8)
        .toList();

    // 2. Construct Stronger History Instruction
    final historyInstruction = recentWords.isNotEmpty
        ? '''
        IMPORTANT - MEMORY REINFORCEMENT TASK:
        The user has recently studied these words: [${recentWords.join(', ')}].
        
        INSTRUCTION FOR "examples" ARRAY:
        You MUST attempt to construct the English example sentences so that they contain BOTH the current word "$word" AND at least one word from the list above.
        Create a semantic connection between "$word" and the history words.
        
        Example: If current word is "adverse" and history has "benefit", generate a sentence like "The adverse weather did not negate the benefits of the journey."
        '''
        : "";

    final userPrompt = '''
    请详细分析单词 "$word"。
    
    任务清单：
    1. 分析其词根（特别是拉丁语/希腊语词源），解释每一部分的含义。
    2. 追溯其含义在历史上的演变过程。
    3. 列出 8-10 个具有相同词根的同源词（不要过多），提供音标和简述联系。
    4. 同源词的 'relation' 字段：必须进行详细的构词法分析（例如：前缀+词根=含义），解释其与词根的深层联系。
    5. 例句生成 (examples)：根据不同场景提供含有该单词的英语例句，并附带中文解释。
    
    $historyInstruction
    
    数据约束：
    - 输出必须是严格的 JSON 格式。
    - 所有中文解释使用简体中文。
    - Examples 中的 sentence 字段必须保留英语原文，严禁翻译。
    - 同源词列表 (cognates) 中绝不要包含单词 "$word" 本身。
    ''';

    WordAnalysis rawData;
    if (settings.provider == 'local') {
      rawData = await _analyzeWithLocal(word, userPrompt, settings);
    } else {
      rawData = await _analyzeWithGemini(userPrompt, settings);
    }

    // Deduplication logic
    return _deduplicateCognates(rawData, word);
  }

  WordAnalysis _deduplicateCognates(WordAnalysis data, String currentWord) {
    final seenWords = <String>{currentWord.trim().toLowerCase()};
    final uniqueCognates = <Cognate>[];

    for (var cognate in data.cognates) {
      if (cognate.word.trim().isEmpty) continue;
      final normalized = cognate.word.trim().toLowerCase();

      if (!seenWords.contains(normalized)) {
        seenWords.add(normalized);
        uniqueCognates.add(cognate);
      }
    }

    return WordAnalysis(
      word: data.word,
      pronunciation: data.pronunciation,
      basicDefinition: data.basicDefinition,
      etymology: data.etymology,
      history: data.history,
      cognates: uniqueCognates,
      examples: data.examples,
    );
  }

  Future<WordAnalysis> _analyzeWithGemini(
      String prompt, AppSettings settings) async {
    if (settings.geminiApiKey.isEmpty) {
      throw Exception(
          "Gemini API Key is empty. Please configure it in settings.");
    }

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: settings.geminiApiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      systemInstruction:
          Content.text("你是一位世界级的词源学家。请提供准确的单词分析。输出语言必须为简体中文，但英语例句需保留原文。"),
    );

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null) throw Exception("Empty response from Gemini");

      final jsonMap = jsonDecode(text);
      return WordAnalysis.fromJson(jsonMap);
    } catch (e) {
      throw Exception("Gemini Error: $e");
    }
  }

  Future<WordAnalysis> _analyzeWithLocal(
      String word, String prompt, AppSettings settings) async {
    try {
      var urlStr = settings.localApiUrl.trim();
      // Normalize URL
      if (urlStr.endsWith('/')) urlStr = urlStr.substring(0, urlStr.length - 1);
      if (!urlStr.endsWith('/v1/chat/completions') &&
          !urlStr.endsWith('/chat/completions')) {
        if (urlStr.endsWith('/v1')) {
          urlStr += '/chat/completions';
        } else {
          urlStr += '/v1/chat/completions';
        }
      }

      final url = Uri.parse(urlStr);

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "model": settings.localModelName,
          "messages": [
            {"role": "system", "content": _jsonPromptTemplate},
            {"role": "user", "content": prompt}
          ],
          "stream": false,
          "format": "json",
          "temperature": 0.2,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            "Local LLM HTTP Error: ${response.statusCode} - ${response.body}");
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final content = data['choices']?[0]['message']?['content'];

      if (content == null)
        throw Exception("Empty response content from Local LLM");

      String jsonString = content;
      final firstOpen = content.indexOf('{');
      final lastClose = content.lastIndexOf('}');
      if (firstOpen != -1 && lastClose != -1 && lastClose > firstOpen) {
        jsonString = content.substring(firstOpen, lastClose + 1);
      } else {
        jsonString =
            content.replaceAll('```json', '').replaceAll('```', '').trim();
      }

      // Fix common JSON errors from local models
      jsonString = jsonString.replaceAllMapped(
          RegExp(r'\\u(?![a-fA-F0-9]{4})'), (match) => "\\\\u");

      return WordAnalysis.fromJson(jsonDecode(jsonString));
    } catch (e) {
      throw Exception("Local LLM Error: $e");
    }
  }
}
