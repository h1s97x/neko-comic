import 'package:flutter/material.dart';

import 'reader_mode.dart';

/// State mixin for reader location tracking
mixin NekoReaderLocationState {
  int _page = 1;

  int get page => _page;

  set page(int value) {
    _page = value;
    onPageChanged();
  }

  void onPageChanged();

  void setPage(int page, {required int totalPages}) {
    if (page < 1) page = 1;
    if (page > totalPages) page = totalPages;
    _page = page;
    onPageChanged();
  }

  bool canGoNext(int totalPages) => _page < totalPages;

  bool canGoPrevious() => _page > 1;
}

/// Reader UI state
class NekoReaderUiState extends ChangeNotifier {
  bool _isUiVisible = true;
  bool _isLoading = false;
  bool _isError = false;
  String? _errorMessage;

  bool get isUiVisible => _isUiVisible;
  bool get isLoading => _isLoading;
  bool get isError => _isError;
  String? get errorMessage => _errorMessage;

  void showUi() {
    if (!_isUiVisible) {
      _isUiVisible = true;
      notifyListeners();
    }
  }

  void hideUi() {
    if (_isUiVisible) {
      _isUiVisible = false;
      notifyListeners();
    }
  }

  void toggleUi() {
    _isUiVisible = !_isUiVisible;
    notifyListeners();
  }

  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void setError(String? message) {
    _isError = message != null;
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _isError = false;
    _errorMessage = null;
    notifyListeners();
  }
}
