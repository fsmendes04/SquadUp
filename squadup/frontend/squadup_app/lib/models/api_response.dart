class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({required this.success, required this.message, this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool,
      message: json['message'] as String,
      data:
          json['data'] != null && fromJsonT != null
              ? fromJsonT(json['data'] as Map<String, dynamic>)
              : null,
    );
  }
}
