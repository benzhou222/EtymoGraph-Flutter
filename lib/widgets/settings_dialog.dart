import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
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
  late TextEditingController _proxyUrlCtrl;
  List<String> _localModelCandidates = [];
  bool _isFetchingModels = false;
  bool _showModelDropdown = false;
  bool _isSaving = false;
  bool _isTestingProxy = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppProvider>().settings;
    _provider = settings.provider;
    _geminiKeyCtrl = TextEditingController(text: settings.geminiApiKey);
    _localUrlCtrl = TextEditingController(text: settings.localApiUrl);
    _localModelCtrl = TextEditingController(text: settings.localModelName);
    _localModelCandidates = List<String>.from(settings.savedModels);
    _proxyUrlCtrl = TextEditingController(text: settings.proxyUrl);
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
      // Merge any candidates discovered during the session, keeping uniqueness
      for (final m in _localModelCandidates) {
        if (!safeSavedModels.contains(m)) safeSavedModels.add(m);
      }

      final newSettings = AppSettings(
        provider: _provider,
        localApiUrl: _localUrlCtrl.text.trim(),
        localModelName: _localModelCtrl.text.trim(),
        geminiApiKey: _geminiKeyCtrl.text.trim(),
        savedModels: safeSavedModels,
        proxyUrl: _proxyUrlCtrl.text.trim(),
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

  Future<void> _fetchModels() async {
    if (_isFetchingModels) return;
    setState(() => _isFetchingModels = true);

    try {
      var urlStr = _localUrlCtrl.text.trim();
      if (urlStr.isEmpty) throw Exception('Local API URL is empty');

      // Extract origin so we can try common endpoints
      Uri baseUri;
      try {
        baseUri = Uri.parse(urlStr);
        if (baseUri.scheme.isEmpty || baseUri.host.isEmpty) {
          // If user omitted scheme, assume http
          baseUri = Uri.parse('http://$urlStr');
        }
      } catch (e) {
        baseUri = Uri.parse('http://$urlStr');
      }
      final origin = baseUri.origin;

      final triedEndpoints = [
        '$origin/v1/models',
        '$origin/models',
        '$origin/v1/engines',
      ];

      List<String> found = [];
      for (final endpoint in triedEndpoints) {
        try {
          final resp = await http
              .get(Uri.parse(endpoint))
              .timeout(const Duration(seconds: 5));
          if (resp.statusCode == 200) {
            final names = _parseModelsFromBody(resp.body);
            if (names.isNotEmpty) {
              found = names;
              break;
            }
          }
        } catch (_) {
          // ignore, try next
        }
      }

      if (found.isEmpty) {
        // Try the direct URL if the user input exactly the models endpoint
        try {
          final resp =
              await http.get(baseUri).timeout(const Duration(seconds: 5));
          if (resp.statusCode == 200) {
            final names = _parseModelsFromBody(resp.body);
            if (names.isNotEmpty) found = names;
          }
        } catch (_) {}
      }

      if (found.isEmpty) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('未能从指定地址检索到模型')));
      } else {
        // Merge and update local candidates
        setState(() {
          final uniq = <String>[];
          for (final m in List<String>.from(_localModelCandidates)
            ..addAll(found)) {
            if (!uniq.contains(m)) uniq.add(m);
          }
          _localModelCandidates = uniq;
          if (_localModelCandidates.isNotEmpty)
            _localModelCtrl.text = _localModelCandidates.first;
          _showModelDropdown = true;
        });
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('找到模型：${found.join(', ')}')));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('检索模型失败: $e')));
    } finally {
      setState(() => _isFetchingModels = false);
    }
  }

  List<String> _parseModelsFromBody(String body) {
    try {
      final jsonBody = jsonDecode(body);
      if (jsonBody is List) {
        if (jsonBody.isEmpty) return [];
        if (jsonBody.first is String) return List<String>.from(jsonBody);
        if (jsonBody.first is Map) {
          return jsonBody.map((e) {
            if (e is Map) {
              if (e.containsKey('name')) return e['name'].toString();
              if (e.containsKey('id')) return e['id'].toString();
            }
            return e.toString();
          }).toList();
        }
      } else if (jsonBody is Map) {
        if (jsonBody.containsKey('models')) {
          final models = jsonBody['models'];
          if (models is List) {
            return models.map((m) {
              if (m is String) return m;
              if (m is Map)
                return (m['name'] ?? m['id'] ?? m['model']).toString();
              return m.toString();
            }).toList();
          }
        }
        if (jsonBody.containsKey('data')) {
          final data = jsonBody['data'];
          if (data is List) {
            return data.map((m) {
              if (m is String) return m;
              if (m is Map)
                return (m['name'] ?? m['id'] ?? m['model']).toString();
              return m.toString();
            }).toList();
          }
        }
      }
    } catch (_) {}
    return [];
  }

  Future<void> _testProxy() async {
    if (_isTestingProxy) return;
    setState(() => _isTestingProxy = true);

    final proxyUrl = _proxyUrlCtrl.text.trim();
    if (proxyUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proxy URL is empty')),
      );
      setState(() => _isTestingProxy = false);
      return;
    }

    try {
      final proxyUri = Uri.parse(proxyUrl);
      final client = HttpClient()
        ..findProxy = (uri) {
          return 'PROXY ${proxyUri.host}:${proxyUri.port};';
        }
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final request = await client.getUrl(Uri.parse('https://www.google.com'));
      final response = await request.close();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proxy connection successful!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Proxy connection failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Proxy connection failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isTestingProxy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access settings via watch to rebuild if list changes
    final savedModels = context.watch<AppProvider>().settings.savedModels;
    final modelsToShow =
        _localModelCandidates.isNotEmpty ? _localModelCandidates : savedModels;

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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _proxyUrlCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Proxy URL',
                            hintText: 'http://127.0.0.1:7890'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 40,
                      child: FilledButton.icon(
                        onPressed: _isTestingProxy ? null : _testProxy,
                        icon: _isTestingProxy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.sync),
                        label: const Text('Test Proxy'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _localUrlCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Local API URL',
                            hintText: 'http://192.168.1.x:11434/v1'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 40,
                      child: FilledButton.icon(
                        onPressed: _isFetchingModels ? null : _fetchModels,
                        icon: _isFetchingModels
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.sync),
                        label: const Text('检测模型'),
                      ),
                    ),
                  ],
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
                          hintText: 'glm-4.6:cloud',
                          suffixIcon: IconButton(
                            icon: Icon(_showModelDropdown
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down),
                            onPressed: () => setState(
                                () => _showModelDropdown = !_showModelDropdown),
                          )),
                      onTap: () => setState(() => _showModelDropdown = true),
                    ),
                    // modelsToShow is calculated at top of build method
                    if (_showModelDropdown && modelsToShow.isNotEmpty)
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
                          itemCount: modelsToShow.length,
                          itemBuilder: (context, index) {
                            final model = modelsToShow[index];
                            return ListTile(
                              title: Text(model,
                                  style: const TextStyle(fontSize: 14)),
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 0),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () {
                                  // Remove from local candidates as well if present
                                  setState(() {
                                    _localModelCandidates.remove(model);
                                  });
                                  // If it exists in provider saved models, delete there too
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
