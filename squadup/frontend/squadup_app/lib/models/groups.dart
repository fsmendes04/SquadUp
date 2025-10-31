class Group {
  final String id;
  final String name;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;

  Group({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
      createdBy: json['created_by'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
    };
  }

  Group copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final DateTime joinedAt;
  final String role;
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

  bool get isAdmin => role == 'admin';
  bool get isMember => role == 'member';

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      role: json['role'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'joined_at': joinedAt.toIso8601String(),
      'role': role,
      'name': name,
      'avatar_url': avatarUrl,
    };
  }

  GroupMember copyWith({
    String? id,
    String? groupId,
    String? userId,
    DateTime? joinedAt,
    String? role,
    String? name,
    String? avatarUrl,
  }) {
    return GroupMember(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      joinedAt: joinedAt ?? this.joinedAt,
      role: role ?? this.role,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class GroupWithMembers {
  final String id;
  final String name;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final List<GroupMember> members;

  GroupWithMembers({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
    required this.members,
  });

  int get memberCount => members.length;

  List<GroupMember> get admins => members.where((m) => m.isAdmin).toList();

  List<GroupMember> get regularMembers =>
      members.where((m) => m.isMember).toList();

  bool isUserAdmin(String userId) {
    return members.any((m) => m.userId == userId && m.isAdmin);
  }

  bool isUserMember(String userId) {
    return members.any((m) => m.userId == userId);
  }

  GroupMember? getMember(String userId) {
    try {
      return members.firstWhere((m) => m.userId == userId);
    } catch (e) {
      return null;
    }
  }

  factory GroupWithMembers.fromJson(Map<String, dynamic> json) {
    return GroupWithMembers(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
      createdBy: json['created_by'] as String,
      members:
          (json['members'] as List<dynamic>?)
              ?.map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
      'members': members.map((m) => m.toJson()).toList(),
    };
  }

  GroupWithMembers copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    List<GroupMember>? members,
  }) {
    return GroupWithMembers(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      members: members ?? this.members,
    );
  }
}

class CreateGroupRequest {
  final String name;
  final List<String>? memberIds;

  CreateGroupRequest({required this.name, this.memberIds});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (memberIds != null && memberIds!.isNotEmpty) 'memberIds': memberIds,
    };
  }
}

class UpdateGroupRequest {
  final String? name;
  final String? avatarUrl;

  UpdateGroupRequest({this.name, this.avatarUrl});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    return data;
  }

  bool get isEmpty => name == null && avatarUrl == null;
}

class AddMemberRequest {
  final String userId;

  AddMemberRequest({required this.userId});

  Map<String, dynamic> toJson() {
    return {'userId': userId};
  }
}

class RemoveMemberRequest {
  final String userId;

  RemoveMemberRequest({required this.userId});

  Map<String, dynamic> toJson() {
    return {'userId': userId};
  }
}
