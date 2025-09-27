import 'group.dart';
import 'group_member.dart';

class GroupWithMembers extends Group {
  final List<GroupMember> members;

  GroupWithMembers({
    required super.id,
    required super.name,
    super.avatarUrl,
    required super.createdAt,
    required super.updatedAt,
    required super.createdBy,
    required this.members,
  });

  factory GroupWithMembers.fromJson(Map<String, dynamic> json) {
    return GroupWithMembers(
      id: json['id'],
      name: json['name'],
      avatarUrl: json['avatar_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      createdBy: json['created_by'],
      members:
          (json['members'] as List<dynamic>)
              .map((memberJson) => GroupMember.fromJson(memberJson))
              .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'members': members.map((member) => member.toJson()).toList(),
    };
  }

  // Métodos utilitários
  List<GroupMember> get admins => members.where((m) => m.isAdmin).toList();
  List<GroupMember> get regularMembers =>
      members.where((m) => !m.isAdmin).toList();
  int get memberCount => members.length;

  bool isUserMember(String userId) {
    return members.any((member) => member.userId == userId);
  }

  bool isUserAdmin(String userId) {
    return members.any((member) => member.userId == userId && member.isAdmin);
  }

  @override
  String toString() {
    return 'GroupWithMembers{id: $id, name: $name, memberCount: $memberCount}';
  }
}
