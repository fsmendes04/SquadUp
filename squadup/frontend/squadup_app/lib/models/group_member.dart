class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final DateTime joinedAt;
  final String role; // 'admin' ou 'member'
  final String? name;
  final String? avatarUrl;

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.joinedAt,
    required this.role,
    this.name,
    this.avatarUrl,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'],
      groupId: json['group_id'],
      userId: json['user_id'],
      joinedAt: DateTime.parse(json['joined_at']),
      role: json['role'],
      name: json['name'],
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'joined_at': joinedAt.toIso8601String(),
      'role': role,
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
  }

  bool get isAdmin => role == 'admin';

  @override
  String toString() {
    return 'GroupMember{id: $id, groupId: $groupId, userId: $userId, joinedAt: $joinedAt, role: $role, name: $name, avatarUrl: $avatarUrl}';
  }
}
