import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/etymology_visualizer.dart';
import '../widgets/timeline_widget.dart';
import '../widgets/cognates_list.dart';
import '../widgets/examples_widget.dart';
import '../widgets/settings_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchCtrl =
      TextEditingController(text: "adverse");

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().search("adverse");
    });
  }

  void _performSearch() {
    context.read<AppProvider>().search(_searchCtrl.text);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color),
            children: const [
              TextSpan(text: 'Etymo'),
              TextSpan(text: 'Graph', style: TextStyle(color: Colors.blue)),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(provider.themeMode == ThemeMode.dark
                ? Icons.light_mode
                : Icons.dark_mode),
            onPressed: () => provider.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => showDialog(
                context: context, builder: (_) => const SettingsDialog()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar & History
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: '输入单词...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: _performSearch,
                    ),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withOpacity(0.5),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
                if (provider.history.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          provider.history.length + 1, // +1 for clear button
                      separatorBuilder: (c, i) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return ActionChip(
                            avatar: const Icon(Icons.delete_outline, size: 16),
                            label: const Text("清除"),
                            onPressed: () => provider.clearHistory(),
                            visualDensity: VisualDensity.compact,
                          );
                        }
                        final word = provider.history[index - 1];
                        return ActionChip(
                          label: Text(word),
                          onPressed: () {
                            _searchCtrl.text = word;
                            _performSearch();
                          },
                          visualDensity: VisualDensity.compact,
                        );
                      },
                    ),
                  ),
                ]
              ],
            ),
          ),

          // Content
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : provider.error != null
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                            child: Text(provider.error!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center)),
                      )
                    : provider.data == null
                        ? const Center(child: Text("开始搜索吧"))
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                // Hero
                                Text(provider.data!.word,
                                    style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'serif')),
                                Text("[${provider.data!.pronunciation}]",
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontFamily: 'monospace',
                                        color: Colors.grey)),
                                const SizedBox(height: 16),
                                Text(provider.data!.basicDefinition,
                                    style: const TextStyle(fontSize: 20),
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 32),

                                EtymologyVisualizer(data: provider.data!),
                                const SizedBox(height: 24),
                                TimelineWidget(history: provider.data!.history),
                                const SizedBox(height: 24),
                                CognatesList(cognates: provider.data!.cognates),
                                const SizedBox(height: 24),
                                ExamplesWidget(
                                  examples: provider.data!.examples,
                                  currentWord: provider.data!.word,
                                  historyWords: provider.history,
                                ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
