class CreateGroupRequest {
  final String name;
  final List<String>? memberIds;

  CreateGroupRequest({required this.name, this.memberIds});

  Map<String, dynamic> toJson() {
    return {'name': name, if (memberIds != null) 'memberIds': memberIds};
  }

  @override
  String toString() {
    return 'CreateGroupRequest{name: $name, memberIds: $memberIds}';
  }
}
