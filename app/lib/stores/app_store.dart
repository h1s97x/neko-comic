import 'package:flutter/material.dart';
import 'package:neko_core/neko_core.dart';
import 'package:neko_source_js/neko_source_js.dart';

/// Global application state store
class AppStore extends ChangeNotifier {
  // Comic sources
  final List<NekoComicSource> _sources = [];
  List<NekoComicSource> get sources => _sources;
  
  // Source manager
  late final NekoComicSourceManager sourceManager;
  
  // Settings
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
  
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
  
  // Reading mode
  ReaderLayout _defaultLayout = ReaderLayout.rightToLeft;
  ReaderLayout get defaultLayout => _defaultLayout;
  
  void setDefaultLayout(ReaderLayout layout) {
    _defaultLayout = layout;
    notifyListeners();
  }
  
  // Loading state
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  String? _initError;
  String? get initError => _initError;
  
  /// Initialize the application
  Future<void> init() async {
    try {
      // Initialize database
      await NekoDatabase.instance.init();
      
      // Initialize source manager
      sourceManager = NekoComicSourceManager();
      await sourceManager.init();
      _sources.addAll(sourceManager.sources);
      
      // Initialize cache manager
      await NekoCacheManager.instance.init();
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _initError = e.toString();
      notifyListeners();
    }
  }
  
  /// Refresh comic sources
  Future<void> refreshSources() async {
    await sourceManager.reload();
    _sources.clear();
    _sources.addAll(sourceManager.sources);
    notifyListeners();
  }
  
  @override
  void dispose() {
    NekoDatabase.instance.close();
    super.dispose();
  }
}
