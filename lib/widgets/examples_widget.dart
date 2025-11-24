import 'package:flutter/material.dart';
import '../models.dart';

class ExamplesWidget extends StatelessWidget {
  final List<ExampleUsage> examples;
  final String currentWord;
  final List<String> historyWords;

  const ExamplesWidget({
    super.key,
    required this.examples,
    required this.currentWord,
    required this.historyWords,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.1))),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.format_quote, color: Colors.purple),
            title: const Text('场景例句',
                style: TextStyle(fontWeight: FontWeight.bold)),
            tileColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.3),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children:
                  examples.map((ex) => _buildExampleItem(context, ex)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleItem(BuildContext context, ExampleUsage ex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.only(left: 16),
      decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: Colors.purple, width: 4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4)),
            child: Text(ex.context,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple)),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                height: 1.5,
                fontFamily: 'Roboto', // Sans-serif
                letterSpacing: 0.5,
              ),
              children: _highlightText(ex.sentence, context),
            ),
          ),
          const SizedBox(height: 4),
          Text(ex.explanation,
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodySmall?.color)),
        ],
      ),
    );
  }

  List<TextSpan> _highlightText(String text, BuildContext context) {
    List<TextSpan> spans = [];

    // Create a combined regex pattern for current word and history words
    final wordsToHighlight = [
      currentWord,
      ...historyWords.where((h) => h.toLowerCase() != currentWord.toLowerCase())
    ];
    if (wordsToHighlight.isEmpty) return [TextSpan(text: text)];

    final patternStr = wordsToHighlight.map((w) => RegExp.escape(w)).join('|');
    // Match word boundaries to avoid partial matches inside other words
    final pattern =
        RegExp(r"\b(" + patternStr + r")\w*\b", caseSensitive: false);

    text.splitMapJoin(
      pattern,
      onMatch: (Match m) {
        final word = m.group(0)!;
        final lowerWord = word.toLowerCase();

        if (lowerWord.startsWith(currentWord.toLowerCase())) {
          // Current Word: Blue + Bold
          spans.add(TextSpan(
              text: word,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blue)));
        } else {
          // History Word: Amber + Bold
          spans.add(TextSpan(
              text: word,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.amber)));
        }
        return word;
      },
      onNonMatch: (String s) {
        spans.add(TextSpan(text: s));
        return s;
      },
    );
    return spans;
  }
}
