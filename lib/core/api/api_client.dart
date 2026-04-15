import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const _activeReaderProfileIdKey = 'active_reader_profile_id';
  static ApiClient? _instance;
  late final Dio _dio;

  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Accept': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final method = options.method.toUpperCase();
          final hasRequestBody =
              method == 'POST' ||
              method == 'PUT' ||
              method == 'PATCH' ||
              method == 'DELETE';

          if (options.data is FormData) {
            // Let Dio/browser generate the multipart boundary automatically.
            options.headers.remove(Headers.contentTypeHeader);
          } else if (hasRequestBody) {
            options.headers.putIfAbsent(
              Headers.contentTypeHeader,
              () => Headers.jsonContentType,
            );
          } else {
            // Avoid forcing Content-Type on bodyless requests to reduce CORS preflight noise on web.
            options.headers.remove(Headers.contentTypeHeader);
          }

          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          final activeReaderProfileId = prefs.getInt(_activeReaderProfileIdKey);
          if (activeReaderProfileId != null) {
            options.headers['X-Reader-Profile-Id'] = '$activeReaderProfileId';
          }
          assert(() {
            // Debug: log API requests
            debugPrint('[API] ${options.method} ${options.uri}');
            return true;
          }());
          handler.next(options);
        },
        onError: (error, handler) {
          assert(() {
            debugPrint('[API ERROR] ${error.requestOptions.uri}');
            debugPrint(
              '[API ERROR] ${error.response?.statusCode} ${error.response?.data}',
            );
            debugPrint('[API ERROR] ${error.message}');
            return true;
          }());
          handler.next(error);
        },
      ),
    );
  }

  static ApiClient get instance => _instance ??= ApiClient._();

  Dio get dio => _dio;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? params}) =>
      _dio.get<T>(path, queryParameters: params);

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> put<T>(String path, {dynamic data}) =>
      _dio.put<T>(path, data: data);

  Future<Response<T>> patch<T>(String path, {dynamic data}) =>
      _dio.patch<T>(path, data: data);

  Future<Response<T>> delete<T>(String path, {dynamic data}) =>
      _dio.delete<T>(path, data: data);

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove(_activeReaderProfileIdKey);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> saveActiveReaderProfileId(int? profileId) async {
    final prefs = await SharedPreferences.getInstance();
    if (profileId == null) {
      await prefs.remove(_activeReaderProfileIdKey);
      return;
    }
    await prefs.setInt(_activeReaderProfileIdKey, profileId);
  }

  static Future<int?> getActiveReaderProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_activeReaderProfileIdKey);
  }
}
