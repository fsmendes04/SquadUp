import 'dart:io';
import 'package:dio/dio.dart';
import '../models/avatar_models.dart';
import 'api_service.dart';

class AvatarService {
  final ApiService _apiService = ApiService();

  static final AvatarService _instance = AvatarService._internal();
  factory AvatarService() => _instance;
  AvatarService._internal();

  /// Upload de avatar - envia arquivo de imagem para o servidor
  Future<AvatarUploadResponse> uploadAvatar(File imageFile) async {
    try {
      // Criar FormData para upload
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        "avatar": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _apiService.dio.post(
        '/auth/upload-avatar',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      return AvatarUploadResponse.fromJson(response.data);
    } catch (e) {
      print('Erro no upload de avatar: $e');
      return AvatarUploadResponse(
        success: false,
        message: 'Erro ao fazer upload do avatar: ${e.toString()}',
      );
    }
  }

  /// Atualizar perfil - pode incluir nome e/ou URL do avatar
  Future<ProfileUpdateResponse> updateProfile({
    String? name,
    String? avatarUrl,
  }) async {
    try {
      final updateRequest = UpdateProfileRequest(
        name: name,
        avatarUrl: avatarUrl,
      );

      final response = await _apiService.put(
        '/auth/update-profile',
        data: updateRequest.toJson(),
      );

      return ProfileUpdateResponse.fromJson(response.data);
    } catch (e) {
      print('Erro ao atualizar perfil: $e');
      return ProfileUpdateResponse(
        success: false,
        message: 'Erro ao atualizar perfil: ${e.toString()}',
      );
    }
  }

  /// Deletar avatar atual
  Future<ProfileUpdateResponse> deleteAvatar() async {
    try {
      final response = await _apiService.delete('/auth/delete-avatar');

      return ProfileUpdateResponse.fromJson(response.data);
    } catch (e) {
      print('Erro ao deletar avatar: $e');
      return ProfileUpdateResponse(
        success: false,
        message: 'Erro ao deletar avatar: ${e.toString()}',
      );
    }
  }

  /// Método auxiliar para validar se um arquivo é uma imagem válida
  bool isValidImageFile(File file) {
    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    final fileName = file.path.toLowerCase();

    return validExtensions.any((extension) => fileName.endsWith(extension));
  }

  /// Método auxiliar para verificar o tamanho do arquivo (máximo 5MB)
  bool isValidFileSize(File file) {
    const maxSizeInBytes = 5 * 1024 * 1024; // 5MB
    return file.lengthSync() <= maxSizeInBytes;
  }

  /// Validação completa do arquivo antes do upload
  String? validateImageFile(File file) {
    if (!file.existsSync()) {
      return 'Arquivo não encontrado';
    }

    if (!isValidImageFile(file)) {
      return 'Formato de arquivo inválido. Use: jpg, jpeg, png, gif ou webp';
    }

    if (!isValidFileSize(file)) {
      return 'Arquivo muito grande. Tamanho máximo: 5MB';
    }

    return null; // null significa que o arquivo é válido
  }
}
