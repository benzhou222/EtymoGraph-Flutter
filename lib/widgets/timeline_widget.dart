import 'package:flutter/material.dart';
import '../models.dart';

class TimelineWidget extends StatelessWidget {
  final List<HistoryEvent> history;

  const TimelineWidget({super.key, required this.history});

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
            leading: const Icon(Icons.history, color: Colors.amber),
            title: const Text('历史演变',
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
            child: Column(children: [
              ...history.asMap().entries.map((entry) {
                final isLast = entry.key == history.length - 1;
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Row(
                          children: [
                            const Expanded(flex: 3, child: SizedBox()),
                            Transform.translate(
                              offset: const Offset(0, 25),
                              child: Column(
                                children: [
                                  Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          border: Border.all(
                                              color: Colors.amber, width: 3),
                                          shape: BoxShape.circle)),
                                  if (!isLast)
                                    Expanded(
                                        child: Container(
                                            width: 2,
                                            color: Colors.grey.shade200)),
                                ],
                              ),
                            ),
                            const Expanded(flex: 4, child: SizedBox()),
                          ],
                        ),
                      ),
                      const SizedBox(width: 30),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(entry.value.era,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Text("•  ${entry.value.meaning}",
                                      style: TextStyle(
                                          color: Colors.amber.shade800,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(entry.value.description,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.color)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ]),
          ),
        ],
      ),
    );
  }
}
