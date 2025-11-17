class User {
  final String id;
  final String email;
  final UserMetadata? userMetadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.email,
    this.userMetadata,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      userMetadata:
          json['user_metadata'] != null
              ? UserMetadata.fromJson(
                json['user_metadata'] as Map<String, dynamic>,
              )
              : null,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'user_metadata': userMetadata?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    UserMetadata? userMetadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      userMetadata: userMetadata ?? this.userMetadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class UserMetadata {
  final String? name;
  final String? avatarUrl;

  UserMetadata({this.name, this.avatarUrl});

  factory UserMetadata.fromJson(Map<String, dynamic> json) {
    return UserMetadata(
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'avatar_url': avatarUrl};
  }

  UserMetadata copyWith({String? name, String? avatarUrl}) {
    return UserMetadata(
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class AuthSession {
  final User user;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final DateTime? expiresAt;

  AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.expiresAt,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] as Map<String, dynamic>;

    return AuthSession(
      user: User.fromJson(userData),
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: json['expires_in'] as int,
      expiresAt:
          json['expires_at'] != null
              ? DateTime.parse(json['expires_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': expiresIn,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get needsRefresh {
    if (expiresAt == null) return false;
    final threshold = DateTime.now().add(const Duration(minutes: 5));
    return threshold.isAfter(expiresAt!);
  }
}
