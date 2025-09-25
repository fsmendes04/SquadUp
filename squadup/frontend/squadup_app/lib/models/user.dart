class User {
  final String id;
  final String email;
  final String? name;
  final String? metadata;
  final String? role;
  final String? emailConfirmedAt;
  final String createdAt;
  final String updatedAt;
  final String? avatarUrl;
  final String? avatarPath;

  User({
    required this.id,
    required this.email,
    this.name,
    this.metadata,
    this.role,
    this.emailConfirmedAt,
    required this.createdAt,
    required this.updatedAt,
    this.avatarUrl,
    this.avatarPath,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    String? name;
    String? avatarUrl;
    String? avatarPath;

    if (json['user_metadata'] is Map) {
      final userMetadata = json['user_metadata'] as Map<String, dynamic>;
      name = userMetadata['name'];
      avatarUrl = userMetadata['avatar_url'];
      avatarPath = userMetadata['avatar_path'];
    }

    return User(
      id: json['id'],
      email: json['email'],
      name: name,
      metadata: json['user_metadata']?.toString(),
      role: json['role'],
      emailConfirmedAt: json['email_confirmed_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      avatarUrl: avatarUrl,
      avatarPath: avatarPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'user_metadata': metadata,
      'role': role,
      'email_confirmed_at': emailConfirmedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'avatar_url': avatarUrl,
      'avatar_path': avatarPath,
    };
  }

  // Método para obter a URL do avatar ou um placeholder
  String getAvatarUrl({String? placeholder}) {
    return avatarUrl ??
        placeholder ??
        'https://via.placeholder.com/150x150.png?text=Avatar';
  }

  // Método para verificar se o usuário tem avatar
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  // Método para criar uma cópia do usuário com novos dados
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? metadata,
    String? role,
    String? emailConfirmedAt,
    String? createdAt,
    String? updatedAt,
    String? avatarUrl,
    String? avatarPath,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      metadata: metadata ?? this.metadata,
      role: role ?? this.role,
      emailConfirmedAt: emailConfirmedAt ?? this.emailConfirmedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }
}
