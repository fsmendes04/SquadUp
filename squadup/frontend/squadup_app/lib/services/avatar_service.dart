import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'auth_service.dart';

class AvatarService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  static final AvatarService _instance = AvatarService._internal();
  factory AvatarService() => _instance;
  AvatarService._internal();

  // Endpoints específicos para avatar
  static const String avatarEndpoint = '/auth/avatar';
  static const String profileEndpoint = '/auth/profile';

  /// Upload de avatar do usuário atual
  /// [imageFile] - Arquivo de imagem selecionado
  /// Retorna o usuário atualizado com a nova URL do avatar
  Future<User> uploadAvatar(File imageFile) async {
    try {
      // Criar FormData para upload
      FormData formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'avatar.${_getFileExtension(imageFile.path)}',
        ),
      });

      final response = await _apiService.dio.post(
        avatarEndpoint,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.data['success'] == true) {
        final userData = response.data['data']['user'];
        final user = User.fromJson(userData);

        // Atualizar cache local com a nova URL do avatar
        await _authService.updateLocalAvatar(user.avatarUrl);

        return user;
      } else {
        throw Exception(
          response.data['message'] ?? 'Erro ao fazer upload do avatar',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final message = e.response!.data['message'] ?? 'Erro no servidor';
        throw Exception(message);
      } else {
        throw Exception('Erro de conexão: ${e.message}');
      }
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  /// Obter URL do avatar do usuário atual
  /// Retorna a URL do avatar ou null se não existir
  Future<String?> getAvatarUrl() async {
    try {
      final response = await _apiService.get(avatarEndpoint);

      if (response.data['success'] == true) {
        return response.data['data']['avatar_url'];
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // Avatar não encontrado
      }
      rethrow;
    }
  }

  /// Excluir avatar do usuário atual
  /// Retorna o usuário atualizado sem avatar
  Future<User> deleteAvatar() async {
    try {
      final response = await _apiService.delete(avatarEndpoint);

      if (response.data['success'] == true) {
        final userData = response.data['data']['user'];
        final user = User.fromJson(userData);

        // Remover avatar do cache local
        await _authService.updateLocalAvatar(null);

        return user;
      } else {
        throw Exception(response.data['message'] ?? 'Erro ao excluir avatar');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final message = e.response!.data['message'] ?? 'Erro no servidor';
        throw Exception(message);
      } else {
        throw Exception('Erro de conexão: ${e.message}');
      }
    }
  }

  /// Obter perfil completo do usuário (incluindo avatar)
  /// Retorna o usuário completo com todas as informações
  Future<User> getUserProfile() async {
    try {
      final response = await _apiService.get(profileEndpoint);

      if (response.data['success'] == true) {
        final userData = response.data['data']['user'];
        return User.fromJson(userData);
      } else {
        throw Exception(response.data['message'] ?? 'Erro ao obter perfil');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final message = e.response!.data['message'] ?? 'Erro no servidor';
        throw Exception(message);
      } else {
        throw Exception('Erro de conexão: ${e.message}');
      }
    }
  }

  /// Selecionar imagem da galeria ou câmera
  /// [source] - ImageSource.gallery ou ImageSource.camera
  /// Retorna o arquivo selecionado ou null se cancelado
  Future<File?> pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85, // Comprimir imagem para reduzir tamanho
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao selecionar imagem: $e');
    }
  }

  /// Validar se o arquivo é uma imagem válida
  /// [file] - Arquivo a ser validado
  /// Retorna true se válido, false caso contrário
  bool validateImageFile(File file) {
    const maxSizeInBytes = 5 * 1024 * 1024; // 5MB
    const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif'];

    // Verificar tamanho
    if (file.lengthSync() > maxSizeInBytes) {
      throw Exception('Arquivo muito grande. Tamanho máximo: 5MB');
    }

    // Verificar extensão
    final extension = _getFileExtension(file.path).toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      throw Exception(
        'Formato não suportado. Use: ${allowedExtensions.join(', ')}',
      );
    }

    return true;
  }

  /// Obter extensão do arquivo
  String _getFileExtension(String filePath) {
    return filePath.split('.').last;
  }

  /// Workflow completo: selecionar e fazer upload de avatar
  /// [source] - ImageSource.gallery ou ImageSource.camera
  /// Retorna o usuário atualizado com novo avatar
  Future<User> selectAndUploadAvatar(ImageSource source) async {
    try {
      // 1. Selecionar imagem
      final imageFile = await pickImage(source);
      if (imageFile == null) {
        throw Exception('Nenhuma imagem selecionada');
      }

      // 2. Validar arquivo
      validateImageFile(imageFile);

      // 3. Fazer upload
      final updatedUser = await uploadAvatar(imageFile);

      return updatedUser;
    } catch (e) {
      rethrow;
    }
  }
}
