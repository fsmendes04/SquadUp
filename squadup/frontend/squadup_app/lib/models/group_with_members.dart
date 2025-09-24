import 'group.dart';
import 'group_member.dart';

class GroupWithMembers extends Group {
  final List<GroupMember> members;

  GroupWithMembers({
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String createdBy,
    required this.members,
  }) : super(
         id: id,
         name: name,
         createdAt: createdAt,
         updatedAt: updatedAt,
         createdBy: createdBy,
       );

  factory GroupWithMembers.fromJson(Map<String, dynamic> json) {
    return GroupWithMembers(
      id: json['id'],
      name: json['name'],
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
