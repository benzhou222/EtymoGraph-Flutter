import 'package:flutter/material.dart';
import '../models.dart';

class EtymologyVisualizer extends StatelessWidget {
  final WordAnalysis data;

  const EtymologyVisualizer({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.3),
              border: Border(
                  bottom: BorderSide(
                      color: Theme.of(context).dividerColor.withOpacity(0.1))),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.call_split, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Text('词根拆解',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 30,
                  runSpacing: 12,
                  children: [
                    ...data.etymology.parts
                        .map((part) => _buildPartNode(context, part)),
                    const Icon(Icons.arrow_forward, color: Colors.grey),
                    _buildWordNode(context, data.word),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  '"${data.etymology.description}"',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartNode(BuildContext context, EtymologyPart part) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(part.part,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue)),
              Text(part.originLanguage,
                  style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
            ],
          ),
        ),
        Container(width: 1, height: 8, color: Colors.grey.shade300),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4)),
          child: Text(part.meaning, style: const TextStyle(fontSize: 11)),
        ),
      ],
    );
  }

  Widget _buildWordNode(BuildContext context, String word) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Text(word,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).colorScheme.onPrimary)),
    );
  }
}
