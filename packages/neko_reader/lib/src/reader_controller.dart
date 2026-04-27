import 'package:flutter/material.dart';

/// Controller for managing reader state
class NekoReaderController extends ChangeNotifier {
  int _currentIndex = 0;
  
  NekoReaderController({int initialIndex = 0}) : _currentIndex = initialIndex;

  int get currentIndex => _currentIndex;

  void setPage(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void nextPage() {
    setPage(_currentIndex + 1);
  }

  void previousPage() {
    setPage(_currentIndex - 1);
  }

  void jumpToPage(int index) {
    setPage(index);
  }

  @override
  int get hashCode => _currentIndex.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NekoReaderController && other._currentIndex == _currentIndex;
  }
}
