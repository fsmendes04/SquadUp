class AvatarUploadResponse {
  final bool success;
  final String message;
  final AvatarUploadData? data;

  AvatarUploadResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory AvatarUploadResponse.fromJson(Map<String, dynamic> json) {
    return AvatarUploadResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data:
          json['data'] != null ? AvatarUploadData.fromJson(json['data']) : null,
    );
  }
}

class AvatarUploadData {
  final String avatarUrl;
  final Map<String, dynamic> user;

  AvatarUploadData({required this.avatarUrl, required this.user});

  factory AvatarUploadData.fromJson(Map<String, dynamic> json) {
    return AvatarUploadData(
      avatarUrl: json['avatar_url'] ?? '',
      user: json['user'] ?? {},
    );
  }
}

class ProfileUpdateResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  ProfileUpdateResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ProfileUpdateResponse.fromJson(Map<String, dynamic> json) {
    return ProfileUpdateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}

class UpdateProfileRequest {
  final String? name;
  final String? avatarUrl;

  UpdateProfileRequest({this.name, this.avatarUrl});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    return data;
  }
}
