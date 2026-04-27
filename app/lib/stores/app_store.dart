import 'package:flutter/material.dart';
import 'package:neko_core/neko_core.dart';
import 'package:neko_reader/neko_reader.dart';
import 'package:neko_source_js/neko_source_js.dart';

/// Application state management
class AppStore extends ChangeNotifier {
  // Theme
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  // Reader settings
  ReaderLayout _readerLayout = ReaderLayout.rightToLeft;
  ReaderLayout get readerLayout => _readerLayout;
  ReaderLayout get defaultLayout => _readerLayout;

  void setReaderLayout(ReaderLayout layout) {
    _readerLayout = layout;
    notifyListeners();
  }

  // Initialization state
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String? _initError;
  String? get initError => _initError;

  // Sources
  List<NekoComicSource> _sources = [];
  List<NekoComicSource> get sources => _sources;

  Future<void> refreshSources() async {
    _sources = NekoComicSourceManager().all();
    notifyListeners();
  }

  // Initialize
  Future<void> init() async {
    try {
      // Initialize database
      await NekoDatabase.init();
      // Initialize favorites manager
      await NekoFavoritesManager.init();
      // Initialize history manager
      await NekoHistoryManager.init();
      // Initialize JS engine
      await NekoJsEngine.init();
      // Initialize comic sources
      await NekoComicSourceManager.init();
      _sources = NekoComicSourceManager().all();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _initError = e.toString();
      notifyListeners();
    }
  }

  // Settings
  Map<String, dynamic> _settings = {};
  Map<String, dynamic> get settings => _settings;

  void updateSetting(String key, dynamic value) {
    _settings[key] = value;
    notifyListeners();
  }
}
