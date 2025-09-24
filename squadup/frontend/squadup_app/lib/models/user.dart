class User {
  final String id;
  final String email;
  final String? name;
  final String? metadata;
  final String? role;
  final String? emailConfirmedAt;
  final String createdAt;
  final String updatedAt;

  User({
    required this.id,
    required this.email,
    this.name,
    this.metadata,
    this.role,
    this.emailConfirmedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Extract name from user_metadata if it exists
    String? name;
    if (json['user_metadata'] is Map) {
      name = json['user_metadata']['name'];
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
    };
  }
}
