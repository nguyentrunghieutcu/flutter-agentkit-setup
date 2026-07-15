import 'package:flutter/foundation.dart';

import 'package:example/features/home/domain/entities/app_info.dart';
import 'package:example/features/home/domain/usecases/get_app_info_use_case.dart';

class AppInfoProvider extends ChangeNotifier {
  AppInfoProvider(this._getAppInfo);

  final GetAppInfoUseCase _getAppInfo;

  AppInfo? _info;
  String? _error;
  bool _isLoading = false;

  AppInfo? get info => _info;
  String? get error => _error;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _getAppInfo();
    result.fold((failure) => _error = failure.message, (info) => _info = info);

    _isLoading = false;
    notifyListeners();
  }
}
