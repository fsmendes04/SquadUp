import 'package:dio/dio.dart';
import 'api_service.dart';

class UserService {
  final ApiService _apiService;

  UserService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        ApiService.userRegister,
        data: {'email': email, 'password': password},
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        ApiService.userLogin,
        data: {'email': email, 'password': password},
      );

      final result = _handleResponse(response);

      // Automatically set auth token if login successful
      if (result['data']?['access_token'] != null) {
        _apiService.setAuthToken(result['data']['access_token']);
      }

      return result;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await _apiService.post(ApiService.userLogout);
      final result = _handleResponse(response);

      _apiService.removeAuthToken();

      return result;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> refreshSession({
    required String refreshToken,
  }) async {
    try {
      final response = await _apiService.post(
        ApiService.userRefreshToken,
        data: {'refresh_token': refreshToken},
      );

      final result = _handleResponse(response);

      if (result['data']?['access_token'] != null) {
        _apiService.setAuthToken(result['data']['access_token']);
      }

      return result;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiService.get(ApiService.userProfile);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? avatarUrl,
  }) async {
    if (!_apiService.hasAuthToken) {
      throw Exception('Usuário não autenticado. Faça login novamente.');
    }
    try {
      final data = <String, dynamic>{};
      if (name != null) {
        data['name'] = name;
      }
      if (avatarUrl != null) {
        data['avatar_url'] = avatarUrl;
      }
      if (data.isEmpty) {
        throw Exception(
          'At least one field (name or avatarUrl) must be provided',
        );
      }
      final response = await _apiService.put(
        ApiService.userProfile,
        data: data,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateProfileWithAvatar({
    String? name,
    required String avatarFilePath,
  }) async {
    if (!_apiService.hasAuthToken) {
      throw Exception('Usuário não autenticado. Faça login novamente.');
    }
    try {
      final formData = FormData();
      if (name != null) {
        formData.fields.add(MapEntry('name', name));
      }
      formData.files.add(
        MapEntry(
          'avatar',
          await MultipartFile.fromFile(
            avatarFilePath,
            filename: avatarFilePath.split('/').last,
          ),
        ),
      );
      final response = await _apiService.putMultipart(
        ApiService.userProfile,
        data: formData,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Map<String, dynamic> _handleResponse(Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.data as Map<String, dynamic>;
    } else {
      throw Exception('Unexpected status code: ${response.statusCode}');
    }
  }

  Exception _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response?.data;

      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is List) {
          return Exception(message.join('\n'));
        } else if (message is String) {
          return Exception(message);
        }
        return Exception('Error: [${error.response?.statusCode}');
      }

      return Exception('Error: ${error.response?.statusCode}');
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return Exception(
        'Connection timeout. Please check your internet connection.',
      );
    } else if (error.type == DioExceptionType.connectionError) {
      return Exception(
        'Connection failed. Please check your internet connection.',
      );
    } else {
      return Exception('An unexpected error occurred: ${error.message}');
    }
  }
}
