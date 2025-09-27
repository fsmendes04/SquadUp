import 'package:dio/dio.dart';
import '../models/group.dart';
import '../models/group_member.dart';
import '../models/group_with_members.dart';
import '../models/create_group_request.dart';
import '../models/update_group_request.dart';
import '../models/add_member_request.dart';
import '../models/remove_member_request.dart';
import 'api_service.dart';

class GroupsService {
  static final GroupsService _instance = GroupsService._internal();
  factory GroupsService() => _instance;
  GroupsService._internal();

  final ApiService _apiService = ApiService();

  // Endpoints
  static const String _groupsEndpoint = '/groups';

  /// Cria um novo grupo
  /// [request] - Dados do grupo a ser criado
  /// [userId] - ID do usuário criador
  Future<Group> createGroup(CreateGroupRequest request, String userId) async {
    try {
      final response = await _apiService.post(
        '$_groupsEndpoint?userId=$userId',
        data: request.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Group.fromJson(response.data);
      } else {
        throw Exception('Erro ao criar grupo: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'Erro ao criar grupo');
    } catch (e) {
      throw Exception('Erro inesperado ao criar grupo: $e');
    }
  }

  /// Retorna todos os grupos
  Future<List<Group>> getAllGroups() async {
    try {
      final response = await _apiService.get(_groupsEndpoint);

      if (response.statusCode == 200) {
        final List<dynamic> groupsJson = response.data;
        return groupsJson.map((json) => Group.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao buscar grupos: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'Erro ao buscar grupos');
    } catch (e) {
      throw Exception('Erro inesperado ao buscar grupos: $e');
    }
  }

  /// Retorna os grupos de um usuário específico
  /// [userId] - ID do usuário
  Future<List<GroupWithMembers>> getUserGroups(String userId) async {
    try {
      final response = await _apiService.get('$_groupsEndpoint/user/$userId');

      if (response.statusCode == 200) {
        final List<dynamic> groupsJson = response.data;
        return groupsJson
            .map((json) => GroupWithMembers.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Erro ao buscar grupos do usuário: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'Erro ao buscar grupos do usuário');
    } catch (e) {
      throw Exception('Erro inesperado ao buscar grupos do usuário: $e');
    }
  }

  /// Retorna os detalhes de um grupo específico
  /// [groupId] - ID do grupo
  Future<GroupWithMembers> getGroup(String groupId) async {
    try {
      final response = await _apiService.get('$_groupsEndpoint/$groupId');

      if (response.statusCode == 200) {
        return GroupWithMembers.fromJson(response.data);
      } else {
        throw Exception('Erro ao buscar grupo: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'Erro ao buscar grupo');
    } catch (e) {
      throw Exception('Erro inesperado ao buscar grupo: $e');
    }
  }

  /// Atualiza um grupo
  /// [groupId] - ID do grupo
  /// [request] - Dados a serem atualizados
  /// [userId] - ID do usuário que está atualizando
  Future<Group> updateGroup(
    String groupId,
    UpdateGroupRequest request,
    String userId,
  ) async {
    try {
      final response = await _apiService.dio.patch(
        '$_groupsEndpoint/$groupId?userId=$userId',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return Group.fromJson(response.data);
      } else {
        throw Exception('Erro ao atualizar grupo: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'Erro ao atualizar grupo');
    } catch (e) {
      throw Exception('Erro inesperado ao atualizar grupo: $e');
    }
  }

  /// Deleta um grupo
  /// [groupId] - ID do grupo
  /// [userId] - ID do usuário que está deletando
  Future<void> deleteGroup(String groupId, String userId) async {
    try {
      final response = await _apiService.delete(
        '$_groupsEndpoint/$groupId?userId=$userId',
      );

      if (response.statusCode != 204) {
        throw Exception('Erro ao deletar grupo: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'Erro ao deletar grupo');
    } catch (e) {
      throw Exception('Erro inesperado ao deletar grupo: $e');
    }
  }

  /// Adiciona um membro ao grupo
  /// [groupId] - ID do grupo
  /// [request] - Dados do membro a ser adicionado
  /// [requesterId] - ID do usuário que está fazendo a requisição
  Future<GroupMember> addMember(
    String groupId,
    AddMemberRequest request,
    String requesterId,
  ) async {
    try {
      final response = await _apiService.post(
        '$_groupsEndpoint/$groupId/members?requesterId=$requesterId',
        data: request.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return GroupMember.fromJson(response.data);
      } else {
        throw Exception('Erro ao adicionar membro: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'Erro ao adicionar membro');
    } catch (e) {
      throw Exception('Erro inesperado ao adicionar membro: $e');
    }
  }

  /// Remove um membro do grupo
  /// [groupId] - ID do grupo
  /// [request] - Dados do membro a ser removido
  /// [requesterId] - ID do usuário que está fazendo a requisição
  Future<void> removeMember(
    String groupId,
    RemoveMemberRequest request,
    String requesterId,
  ) async {
    try {
      final response = await _apiService.dio.delete(
        '$_groupsEndpoint/$groupId/members?requesterId=$requesterId',
        data: request.toJson(),
      );

      if (response.statusCode != 204) {
        throw Exception('Erro ao remover membro: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'Erro ao remover membro');
    } catch (e) {
      throw Exception('Erro inesperado ao remover membro: $e');
    }
  }

  /// Faz upload do avatar do grupo
  /// [groupId] - ID do grupo
  /// [filePath] - Caminho do arquivo de imagem
  Future<Map<String, dynamic>> uploadGroupAvatar(
    String groupId,
    String filePath,
  ) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(filePath),
      });

      final response = await _apiService.dio.post(
        '$_groupsEndpoint/$groupId/avatar',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception(
          'Erro ao fazer upload do avatar: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw GroupsService._handleDioException(
        e,
        'Erro ao fazer upload do avatar do grupo',
      );
    } catch (e) {
      throw Exception('Erro inesperado ao fazer upload do avatar: $e');
    }
  }

  /// Trata exceções do Dio e retorna mensagens de erro apropriadas
  static Exception _handleDioException(DioException e, String defaultMessage) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return Exception('Timeout de conexão. Verifique sua internet.');
      case DioExceptionType.sendTimeout:
        return Exception('Timeout ao enviar dados. Tente novamente.');
      case DioExceptionType.receiveTimeout:
        return Exception('Timeout ao receber dados. Tente novamente.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message =
            e.response?.data?['message'] ?? e.response?.statusMessage;

        switch (statusCode) {
          case 400:
            return Exception(
              'Dados inválidos: ${message ?? "Verifique os dados enviados"}',
            );
          case 401:
            return Exception('Não autorizado. Faça login novamente.');
          case 403:
            return Exception(
              'Acesso negado: ${message ?? "Você não tem permissão"}',
            );
          case 404:
            return Exception(
              'Recurso não encontrado: ${message ?? "Grupo não existe"}',
            );
          case 409:
            return Exception(
              'Conflito: ${message ?? "Operação não permitida"}',
            );
          case 500:
            return Exception(
              'Erro interno do servidor. Tente novamente mais tarde.',
            );
          default:
            return Exception(
              '$defaultMessage: ${message ?? "Erro desconhecido"}',
            );
        }
      case DioExceptionType.cancel:
        return Exception('Operação cancelada.');
      case DioExceptionType.unknown:
        return Exception('Erro de conexão. Verifique sua internet.');
      default:
        return Exception('$defaultMessage: ${e.message}');
    }
  }
}
