class CreateGroupRequest {
  final String name;
  final String? avatarUrl;
  final List<String>? memberIds;

  CreateGroupRequest({required this.name, this.avatarUrl, this.memberIds});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (memberIds != null) 'memberIds': memberIds,
    };
  }

  @override
  String toString() {
    return 'CreateGroupRequest{name: $name, avatarUrl: $avatarUrl, memberIds: $memberIds}';
  }
}
