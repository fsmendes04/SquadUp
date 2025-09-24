import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl =
      'http://10.0.2.2:3000'; // URL base da API - 10.0.2.2 para Android emulator
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Adicionar interceptor para logs (opcional)
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => print(object),
      ),
    );
  }

  // Getter para acessar a instância do Dio
  Dio get dio => _dio;

  // Método para adicionar token de autorização
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Método para remover token de autorização
  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  // Método genérico para requisições GET
  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(endpoint, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  // Método genérico para requisições POST
  Future<Response> post(String endpoint, {dynamic data}) async {
    try {
      return await _dio.post(endpoint, data: data);
    } catch (e) {
      rethrow;
    }
  }

  // Método genérico para requisições PUT
  Future<Response> put(String endpoint, {dynamic data}) async {
    try {
      return await _dio.put(endpoint, data: data);
    } catch (e) {
      rethrow;
    }
  }

  // Método genérico para requisições DELETE
  Future<Response> delete(String endpoint) async {
    try {
      return await _dio.delete(endpoint);
    } catch (e) {
      rethrow;
    }
  }

  // Endpoints específicos da API de autenticação
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshTokenEndpoint = '/auth/refresh';

  // URLs completas para facilitar o uso
  static String get loginUrl => baseUrl + loginEndpoint;
  static String get registerUrl => baseUrl + registerEndpoint;
  static String get logoutUrl => baseUrl + logoutEndpoint;
  static String get refreshTokenUrl => baseUrl + refreshTokenEndpoint;
}
