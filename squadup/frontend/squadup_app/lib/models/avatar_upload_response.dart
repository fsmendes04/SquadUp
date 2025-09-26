class AvatarUploadResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final String? error;

  AvatarUploadResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory AvatarUploadResponse.fromJson(Map<String, dynamic> json) {
    return AvatarUploadResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'error': error,
    };
  }
}
