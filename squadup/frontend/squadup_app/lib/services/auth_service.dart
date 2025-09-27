import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/user.dart';
import '../models/avatar_upload_response.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal() {
    // Configurar interceptor para adicionar token automaticamente
    _apiService.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getStoredToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  // Login user
  Future<AuthResponse> login(LoginRequest loginRequest) async {
    try {
      final response = await _apiService.post(
        ApiService.loginEndpoint,
        data: loginRequest.toJson(),
      );

      final authResponse = AuthResponse.fromJson(response.data);

      if (authResponse.success && authResponse.data != null) {
        if (authResponse.data!.session != null) {
          await _storeToken(authResponse.data!.session!.accessToken);
          await _storeUser(authResponse.data!.user);
          // Configurar token no ApiService para próximas requisições
          _apiService.setAuthToken(authResponse.data!.session!.accessToken);
        } else {
          // Apenas armazena os dados do usuário se não houver sessão
          await _storeUser(authResponse.data!.user);
        }
      }

      return authResponse;
    } on DioException catch (e) {
      if (e.response != null) {
        return AuthResponse.fromJson(e.response!.data);
      } else {
        return AuthResponse(
          success: false,
          message: 'Network error: ${e.message}',
        );
      }
    } catch (e) {
      return AuthResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  // Register user
  Future<AuthResponse> register(RegisterRequest registerRequest) async {
    try {
      final response = await _apiService.post(
        ApiService.registerEndpoint,
        data: registerRequest.toJson(),
      );

      final authResponse = AuthResponse.fromJson(response.data);

      if (authResponse.success && authResponse.data != null) {
        // Para registro, a sessão pode ser null se email confirmation for necessária
        if (authResponse.data!.session != null) {
          await _storeToken(authResponse.data!.session!.accessToken);
          await _storeUser(authResponse.data!.user);
          // Configurar token no ApiService para próximas requisições
          _apiService.setAuthToken(authResponse.data!.session!.accessToken);
        } else {
          // Apenas armazena os dados do usuário se não houver sessão
          await _storeUser(authResponse.data!.user);
        }
      }

      return authResponse;
    } on DioException catch (e) {
      if (e.response != null) {
        return AuthResponse.fromJson(e.response!.data);
      } else {
        return AuthResponse(
          success: false,
          message: 'Network error: ${e.message}',
        );
      }
    } catch (e) {
      return AuthResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  // Store token securely
  Future<void> _storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Store user data
  Future<void> _storeUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', user.id);
    await prefs.setString('user_email', user.email);
    if (user.name != null) {
      await prefs.setString('user_name', user.name!);
    } else {
      await prefs.remove('user_name'); // Remove if null
    }
    if (user.avatarUrl != null) {
      await prefs.setString('user_avatar_url', user.avatarUrl!);
    } else {
      await prefs.remove('user_avatar_url'); // Remove if null
    }
  }

  // Get stored token
  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Get stored user data
  Future<Map<String, String?>?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final userEmail = prefs.getString('user_email');
    final userName = prefs.getString('user_name');
    final userAvatarUrl = prefs.getString('user_avatar_url');

    if (userId != null && userEmail != null) {
      return {
        'id': userId,
        'email': userEmail,
        'name': userName, // Can be null
        'avatar_url': userAvatarUrl, // Can be null
      };
    }

    return null;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getStoredToken();
    return token != null;
  }

  // Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    await prefs.remove('user_avatar_url');
    // Remover token do ApiService
    _apiService.removeAuthToken();
  }

  // Inicializar token no ApiService se já estiver logado
  Future<void> initializeToken() async {
    final token = await getStoredToken();
    if (token != null) {
      _apiService.setAuthToken(token);
    }
  }

  // Update user name
  Future<bool> updateUserName(String name) async {
    try {
      // Update user metadata with the new name
      final response = await _apiService.put(
        '/auth/update-profile',
        data: {'name': name},
      );

      if (response.statusCode == 200) {
        // Update local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', name);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProfile({String? name, String? avatarUrl}) async {
    try {
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;

      final response = await _apiService.put(
        '/auth/update-profile',
        data: data,
      );

      if (response.statusCode == 200) {
        // Update local storage
        final prefs = await SharedPreferences.getInstance();
        if (name != null) {
          await prefs.setString('user_name', name);
        }
        if (avatarUrl != null) {
          await prefs.setString('user_avatar_url', avatarUrl);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logoutEnhanced() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    await prefs.remove('user_avatar_url');
    _apiService.removeAuthToken();
  }

  // Update avatar URL only
  Future<bool> updateAvatarUrl(String avatarUrl) async {
    try {
      final response = await _apiService.put(
        '/auth/update-avatar-url',
        data: {'avatar_url': avatarUrl},
      );

      if (response.statusCode == 200) {
        // Update local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_avatar_url', avatarUrl);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Get user by ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final response = await _apiService.get('/auth/user/$userId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final userData = response.data['data'];
        return {
          'id': userData['id'],
          'email': userData['email'],
          'name': userData['user_metadata']?['name'],
          'avatar_url': userData['user_metadata']?['avatar_url'],
          'created_at': userData['created_at'],
          'updated_at': userData['updated_at'],
        };
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // Upload avatar file
  Future<AvatarUploadResponse> uploadAvatar(String filePath) async {
    try {
      FormData formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(filePath),
      });

      final response = await _apiService.post(
        '/auth/upload-avatar',
        data: formData,
      );

      final avatarResponse = AvatarUploadResponse.fromJson(response.data);

      if (avatarResponse.success && avatarResponse.data != null) {
        // Extract avatar URL from user metadata
        final userData = avatarResponse.data!;
        final avatarUrl = userData['user_metadata']?['avatar_url'];

        if (avatarUrl != null) {
          // Update local storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_avatar_url', avatarUrl);
        }
      }

      return avatarResponse;
    } on DioException catch (e) {
      if (e.response != null) {
        return AvatarUploadResponse.fromJson(e.response!.data);
      } else {
        return AvatarUploadResponse(
          success: false,
          message: 'Network error: ${e.message}',
        );
      }
    } catch (e) {
      return AvatarUploadResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  // Get current user's avatar URL
  Future<String?> getUserAvatarUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_avatar_url');
  }
}
