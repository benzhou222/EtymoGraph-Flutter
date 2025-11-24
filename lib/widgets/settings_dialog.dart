import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late String _provider;
  late TextEditingController _geminiKeyCtrl;
  late TextEditingController _localUrlCtrl;
  late TextEditingController _localModelCtrl;
  bool _showModelDropdown = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppProvider>().settings;
    _provider = settings.provider;
    _geminiKeyCtrl = TextEditingController(text: settings.geminiApiKey);
    _localUrlCtrl = TextEditingController(text: settings.localApiUrl);
    _localModelCtrl = TextEditingController(text: settings.localModelName);
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final currentSettings = context.read<AppProvider>().settings;

      // CRITICAL: Create a deep copy of the savedModels list using List.from
      // This ensures we are not passing an immutable list back to the provider
      final List<String> safeSavedModels =
          List<String>.from(currentSettings.savedModels);

      final newSettings = AppSettings(
        provider: _provider,
        localApiUrl: _localUrlCtrl.text.trim(),
        localModelName: _localModelCtrl.text.trim(),
        geminiApiKey: _geminiKeyCtrl.text.trim(),
        savedModels: safeSavedModels,
      );

      // Await the save operation
      await context.read<AppProvider>().saveSettings(newSettings);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("保存失败: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access settings via watch to rebuild if list changes
    final savedModels = context.watch<AppProvider>().settings.savedModels;

    return AlertDialog(
      title: const Text('模型设置'),
      // CRITICAL FIX: SizedBox with maxFinite width prevents RenderIntrinsicWidth error
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('AI 服务提供商',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Gemini'),
                      value: 'gemini',
                      groupValue: _provider,
                      onChanged: (v) => setState(() => _provider = v!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Local'),
                      value: 'local',
                      groupValue: _provider,
                      onChanged: (v) => setState(() => _provider = v!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const Divider(),
              if (_provider == 'gemini') ...[
                TextField(
                  controller: _geminiKeyCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Gemini API Key',
                      hintText: 'Optional if using default env'),
                  obscureText: true,
                ),
              ] else ...[
                TextField(
                  controller: _localUrlCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Local API URL',
                      hintText: 'http://192.168.1.x:11434/v1'),
                ),
                const SizedBox(height: 16),

                // Local Model Name with Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _localModelCtrl,
                      decoration: InputDecoration(
                          labelText: 'Model Name',
                          hintText: 'llama3',
                          suffixIcon: IconButton(
                            icon: Icon(_showModelDropdown
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down),
                            onPressed: () => setState(
                                () => _showModelDropdown = !_showModelDropdown),
                          )),
                      onTap: () => setState(() => _showModelDropdown = true),
                    ),
                    if (_showModelDropdown && savedModels.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                          color: Theme.of(context).cardColor,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: savedModels.length,
                          itemBuilder: (context, index) {
                            final model = savedModels[index];
                            return ListTile(
                              title: Text(model,
                                  style: const TextStyle(fontSize: 14)),
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 0),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () {
                                  context
                                      .read<AppProvider>()
                                      .deleteSavedModel(model);
                                },
                              ),
                              onTap: () {
                                _localModelCtrl.text = model;
                                setState(() => _showModelDropdown = false);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.only(top: 12.0),
                  child: Text('注意：连接手机时，请使用电脑局域网IP，并设置 OLLAMA_HOST=0.0.0.0',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              ]
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: Text(_isSaving ? '保存中...' : '保存'),
        ),
      ],
    );
  }
}
