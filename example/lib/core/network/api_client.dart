import 'package:dio/dio.dart';

class ApiClient {
  ApiClient({required String baseUrl})
    : dio = Dio(BaseOptions(baseUrl: baseUrl));

  final Dio dio;
}
