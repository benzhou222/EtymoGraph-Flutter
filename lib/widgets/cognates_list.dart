import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../models.dart';

class CognatesList extends StatelessWidget {
  final List<Cognate> cognates;

  const CognatesList({super.key, required this.cognates});

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
            leading: const Icon(Icons.hub, color: Colors.green),
            title: const Text('同源词',
                style: TextStyle(fontWeight: FontWeight.bold)),
            tileColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.3),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          ),
          SizedBox(
            height: 350, // Fixed height with scroll
            child: ListView.separated(
              padding: const EdgeInsets.all(0),
              itemCount: cognates.length,
              separatorBuilder: (c, i) => Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Theme.of(context).dividerColor.withOpacity(0.1)),
              itemBuilder: (context, index) {
                final item = cognates[index];
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.word,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("[${item.pronunciation}]",
                                        style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 13,
                                            color: Colors.grey)),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.volume_up,
                                          size: 18, color: Colors.blueAccent),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => TTSService()
                                          .speak(item.word, waitForStop: false),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            fit: FlexFit.loose,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 420),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                item.relation,
                                style: const TextStyle(fontSize: 12),
                                textAlign: TextAlign.left,
                                softWrap: true,
                                maxLines: 6,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(item.definition,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
