// snippets/api_interceptor.dart
// Copy to lib/core/network/interceptors/.
// Handles: auth header injection, 401 token refresh, error mapping.

import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  final String? Function() getToken;
  final Future<String?> Function() refreshToken;
  final VoidCallback onAuthExpired;

  AuthInterceptor({
    required this.getToken,
    required this.refreshToken,
    required this.onAuthExpired,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        final newToken = await refreshToken();
        if (newToken != null) {
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final response = await Dio().fetch(opts);
          return handler.resolve(response);
        }
      } catch (_) {
        onAuthExpired();
      }
    }
    handler.next(err);
  }
}

class ApiErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    final message = switch (status) {
      400 => 'Bad request',
      403 => 'Access denied',
      404 => 'Not found',
      422 => _parse422(err.response?.data),
      500 => 'Server error, please try again',
      null => 'No internet connection',
      _ => 'Unexpected error ($status)',
    };
    err.requestOptions.extra['parsedError'] = message;
    handler.next(err);
  }

  String _parse422(dynamic data) {
    try {
      final errors = data['errors'] as Map<String, dynamic>;
      return errors.values.first is List
          ? (errors.values.first as List).first.toString()
          : errors.values.first.toString();
    } catch (_) {
      return 'Validation error';
    }
  }
}
