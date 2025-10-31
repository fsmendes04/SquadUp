import 'package:dio/dio.dart';
import 'api_service.dart';

class GroupsService {
  final ApiService _apiService;

  GroupsService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  Future<Map<String, dynamic>> createGroup({
    required String name,
    List<String>? memberIds,
  }) async {
    try {
      final data = <String, dynamic>{'name': name};

      if (memberIds != null && memberIds.isNotEmpty) {
        data['memberIds'] = memberIds;
      }

      final response = await _apiService.post(
        ApiService.userGroups,
        data: data,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getAllGroups() async {
    try {
      final response = await _apiService.get(ApiService.groupsEndpoint);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getUserGroups() async {
    try {
      final response = await _apiService.get(ApiService.userGroups);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getGroupById(String groupId) async {
    try {
      final response = await _apiService.get(ApiService.groupById(groupId));
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateGroup({
    required String groupId,
    String? name,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (name != null) {
        data['name'] = name;
      }

      if (data.isEmpty) {
        throw Exception('At least one field must be provided for update');
      }

      final response = await _apiService.patch(
        ApiService.groupById(groupId),
        data: data,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteGroup(String groupId) async {
    try {
      final response = await _apiService.delete(ApiService.groupById(groupId));
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> addMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      final response = await _apiService.post(
        ApiService.groupMembers(groupId),
        data: {'userId': userId},
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> removeMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      final response = await _apiService.delete(
        ApiService.groupMembers(groupId),
        data: {'userId': userId},
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> uploadGroupAvatar({
    required String groupId,
    required String avatarFilePath,
  }) async {
    try {
      final formData = FormData();

      formData.files.add(
        MapEntry(
          'avatar',
          await MultipartFile.fromFile(
            avatarFilePath,
            filename: avatarFilePath.split('/').last,
          ),
        ),
      );

      final response = await _apiService.postMultipart(
        ApiService.groupAvatar(groupId),
        data: formData,
      );

      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Map<String, dynamic> _handleResponse(Response response) {
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      // Handle 204 No Content
      if (response.statusCode == 204) {
        return {'success': true, 'message': 'Operation successful'};
      }
      return response.data as Map<String, dynamic>;
    } else {
      throw Exception('Unexpected status code: ${response.statusCode}');
    }
  }

  Exception _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response?.data;

      if (data is Map<String, dynamic>) {
        final message = data['message'] ?? 'An error occurred';
        return Exception(message);
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
