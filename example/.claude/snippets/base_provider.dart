// snippets/base_provider.dart
// Copy to lib/shared/providers/ or use as base class for feature providers.
// Replace <State> with your actual state type.

import 'package:flutter/foundation.dart';

abstract class BaseProvider<T> extends ChangeNotifier {
  T? _data;
  bool _isLoading = false;
  String? _error;

  T? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _data != null;
  bool get hasError => _error != null;

  @protected
  void setLoading() {
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  @protected
  void setData(T data) {
    _data = data;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  @protected
  void setError(String message) {
    _error = message;
    _isLoading = false;
    notifyListeners();
  }

  void reset() {
    _data = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
