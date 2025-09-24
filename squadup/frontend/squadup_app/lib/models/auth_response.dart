import 'user.dart';

class AuthSession {
  final String accessToken;
  final String? refreshToken;
  final int expiresIn;
  final String tokenType;
  final User user;

  AuthSession({
    required this.accessToken,
    this.refreshToken,
    required this.expiresIn,
    required this.tokenType,
    required this.user,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      expiresIn: json['expires_in'],
      tokenType: json['token_type'],
      user: User.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': expiresIn,
      'token_type': tokenType,
      'user': user.toJson(),
    };
  }
}

class AuthResponse {
  final bool success;
  final String message;
  final AuthData? data;
  final String? error;

  AuthResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null ? AuthData.fromJson(json['data']) : null,
      error: json['error'],
    );
  }
}

class AuthData {
  final User user;
  final AuthSession? session;

  AuthData({required this.user, this.session});

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      user: User.fromJson(json['user']),
      session:
          json['session'] != null
              ? AuthSession.fromJson(json['session'])
              : null,
    );
  }
}
