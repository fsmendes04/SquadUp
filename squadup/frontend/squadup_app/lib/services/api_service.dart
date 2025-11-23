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
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final data = options.data;
            String logData = '';
            if (data is Map) {
              final maskedData = Map<String, dynamic>.from(data);
              if (maskedData.containsKey('password')) {
                maskedData['password'] = '***';
              }
              if (maskedData.containsKey('currentPassword')) {
                maskedData['currentPassword'] = '***';
              }
              if (maskedData.containsKey('newPassword')) {
                maskedData['newPassword'] = '***';
              }
              if (maskedData.containsKey('confirmPassword')) {
                maskedData['confirmPassword'] = '***';
              }
              if (maskedData.containsKey('confirmNewPassword')) {
                maskedData['confirmNewPassword'] = '***';
              }
              logData = maskedData.toString();
            }
            _log('➡️ ${options.method} ${options.path}');
            if (logData.isNotEmpty) {
              _log('📦 Data: $logData');
            }
            return handler.next(options);
          },
          onResponse: (response, handler) {
            _log('✅ ${response.statusCode} ${response.requestOptions.path}');
            return handler.next(response);
          },
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

  static const String userEndpoint = '/user';
  static const String userLogin = '$userEndpoint/login';
  static const String userRegister = '$userEndpoint/register';
  static const String userLogout = '$userEndpoint/logout';
  static const String userRefreshToken = '$userEndpoint/refresh';
  static const String userProfile = '$userEndpoint/profile';
  static const String userChangePassword = '$userEndpoint/change-password';

  static const String groupsEndpoint = '/groups';
  static const String createGroup = '/groups/create';
  static String groupById(String id) => '$groupsEndpoint/$id';
  static String groupAvatar(String id) => '$groupsEndpoint/$id/avatar';
  static String groupMembers(String id) => '$groupsEndpoint/$id/members';
  static const String userGroups = '$groupsEndpoint/user';

  static const String expensesEndpoint = '/expenses';
  static String expenseById(String id) => '$expensesEndpoint/$id';
  static String expensesByGroup(String groupId) =>
      '$expensesEndpoint/group/$groupId';
  static String groupBalance(String groupId) =>
      '$expensesEndpoint/group/$groupId/balance';
}
