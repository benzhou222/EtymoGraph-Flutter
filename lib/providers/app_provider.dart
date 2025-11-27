import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../services/ai_service.dart';

class AppProvider with ChangeNotifier {
  final AIService _aiService = AIService();

  WordAnalysis? _data;
  bool _loading = false;
  String? _error;
  List<String> _history = [];
  AppSettings _settings = AppSettings();
  ThemeMode _themeMode = ThemeMode.system;

  WordAnalysis? get data => _data;
  bool get loading => _loading;
  String? get error => _error;
  List<String> get history => _history;
  AppSettings get settings => _settings;
  ThemeMode get themeMode => _themeMode;

  AppProvider() {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Settings
    final settingsJson = prefs.getString('appSettings');
    if (settingsJson != null) {
      _settings = AppSettings.fromJson(jsonDecode(settingsJson));
    }

    // Load History
    _history = prefs.getStringList('searchHistory') ?? [];

    // Load Theme
    final themeStr = prefs.getString('theme');
    if (themeStr == 'dark')
      _themeMode = ThemeMode.dark;
    else if (themeStr == 'light') _themeMode = ThemeMode.light;

    notifyListeners();
  }

  Future<void> saveSettings(AppSettings newSettings) async {
    // 1. Create a MUTABLE copy of the savedModels list using List.from
    // This prevents "Concurrent modification" or "Immutable list" errors
    final List<String> mutableSavedModels =
        List<String>.from(newSettings.savedModels);

    // 2. Logic to add new model name if unique
    if (newSettings.provider == 'local' &&
        newSettings.localModelName.isNotEmpty) {
      if (!mutableSavedModels.contains(newSettings.localModelName)) {
        mutableSavedModels.insert(0, newSettings.localModelName);
      }
    }

    // 3. Create updated AppSettings object with the mutable list
    _settings = AppSettings(
      provider: newSettings.provider,
      localApiUrl: newSettings.localApiUrl,
      localModelName: newSettings.localModelName,
      geminiApiKey: newSettings.geminiApiKey,
      savedModels: mutableSavedModels,
      proxyUrl: newSettings.proxyUrl,
    );

    // 4. Persist to storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appSettings', jsonEncode(_settings.toJson()));
    notifyListeners();
  }

  Future<void> deleteSavedModel(String modelName) async {
    // Create mutable copy
    final List<String> mutableSavedModels =
        List<String>.from(_settings.savedModels);
    mutableSavedModels.remove(modelName);

    // Update settings
    _settings = AppSettings(
      provider: _settings.provider,
      localApiUrl: _settings.localApiUrl,
      localModelName: _settings.localModelName,
      geminiApiKey: _settings.geminiApiKey,
      savedModels: mutableSavedModels,
      proxyUrl: _settings.proxyUrl,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appSettings', jsonEncode(_settings.toJson()));
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'theme', _themeMode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> search(String word) async {
    if (word.trim().isEmpty) return;

    _loading = true;
    _error = null;
    _data = null;
    notifyListeners();

    try {
      final result = await _aiService.analyzeWord(word, _history, _settings);
      _data = result;
      _addToHistory(result.word);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _addToHistory(String word) async {
    final prefs = await SharedPreferences.getInstance();
    final lowerWord = word.toLowerCase();
    _history.removeWhere((w) => w.toLowerCase() == lowerWord);
    _history.insert(0, word);
    if (_history.length > 12) _history = _history.sublist(0, 12);

    await prefs.setStringList('searchHistory', _history);
  }

  Future<void> clearHistory() async {
    _history.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('searchHistory');
    notifyListeners();
  }
}
