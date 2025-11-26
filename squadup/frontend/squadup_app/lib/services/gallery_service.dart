import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/gallery_model.dart';

class GalleryService {
  final ApiService _apiService = ApiService();

  Future<List<Gallery>> getGalleriesByGroup(String groupId) async {
    try {
      final endpoint = ApiService.galleriesByGroup(groupId);

      final response = await _apiService.get(endpoint);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final List<dynamic> galleriesJson = data['data'] as List<dynamic>;
          return galleriesJson
              .map((json) => Gallery.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch galleries');
        }
      } else {
        throw Exception('Failed to fetch galleries: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to fetch galleries',
      );
    }
  }

  Future<Gallery> getGalleryById(String galleryId) async {
    try {
      final response = await _apiService.get(ApiService.galleryById(galleryId));

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return Gallery.fromJson(data['data'] as Map<String, dynamic>);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch gallery');
        }
      } else {
        throw Exception('Failed to fetch gallery: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch gallery');
    }
  }

  Future<Gallery> createGallery({
    required String groupId,
    required String eventName,
    required String location,
    required String date,
    required List<String> imagePaths,
  }) async {
    try {
      final formData = FormData.fromMap({
        'group_id': groupId,
        'event_name': eventName,
        'location': location,
        'date': date,
      });

      for (var imagePath in imagePaths) {
        formData.files.add(
          MapEntry('images', await MultipartFile.fromFile(imagePath)),
        );
      }

      final response = await _apiService.postMultipart(
        ApiService.galleryEndpoint,
        data: formData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return Gallery.fromJson(data['data'] as Map<String, dynamic>);
        } else {
          throw Exception(data['message'] ?? 'Failed to create gallery');
        }
      } else {
        throw Exception('Failed to create gallery: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to create gallery',
      );
    }
  }
}
