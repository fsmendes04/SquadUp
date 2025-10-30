import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: AppConfig.defaultHeaders,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    if (AppConfig.enableApiLogs) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          requestHeader: false,
          responseHeader: false,
          logPrint: (object) => _log(object),
        ),
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          _log('❌ Error: ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  void _log(Object? object) {
    if (kDebugMode) {
      debugPrint(object?.toString());
    }
  }

  Dio get dio => _dio;

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
    _log('✅ Auth token set');
  }

  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
    _log('🔓 Auth token removed');
  }

  bool get hasAuthToken => _dio.options.headers.containsKey('Authorization');

  Future<Response> _request(
    String method,
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.request(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: (options ?? Options()).copyWith(method: method),
      );
      return response;
    } on DioException catch (e) {
      _log('Request failed: ${e.message}');
      rethrow;
    }
  }

  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) => _request('GET', endpoint, queryParameters: queryParameters);

  Future<Response> post(String endpoint, {dynamic data}) =>
      _request('POST', endpoint, data: data);

  Future<Response> put(String endpoint, {dynamic data}) =>
      _request('PUT', endpoint, data: data);

  Future<Response> delete(String endpoint, {dynamic data}) =>
      _request('DELETE', endpoint, data: data);

  Future<Response> patch(String endpoint, {dynamic data}) =>
      _request('PATCH', endpoint, data: data);

  Future<Response> postMultipart(
    String endpoint, {
    required FormData data,
    ProgressCallback? onSendProgress,
  }) => _request(
    'POST',
    endpoint,
    data: data,
    options: Options(contentType: 'multipart/form-data'),
  );

  Future<Response> putMultipart(
    String endpoint, {
    required FormData data,
    ProgressCallback? onSendProgress,
  }) => _request(
    'PUT',
    endpoint,
    data: data,
    options: Options(contentType: 'multipart/form-data'),
  );

  static const String loginEndpoint = '/user/login';
  static const String registerEndpoint = '/user/register';
  static const String logoutEndpoint = '/user/logout';
  static const String refreshTokenEndpoint = '/user/refresh';
  static const String profileEndpoint = '/user/profile';
}
