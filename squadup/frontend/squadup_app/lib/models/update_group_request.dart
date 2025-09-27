class UpdateGroupRequest {
  final String? name;
  final String? avatarUrl;
  final List<String>? memberIds;

  UpdateGroupRequest({this.name, this.avatarUrl, this.memberIds});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (name != null) json['name'] = name;
    if (avatarUrl != null) json['avatar_url'] = avatarUrl;
    if (memberIds != null) json['memberIds'] = memberIds;
    return json;
  }

  @override
  String toString() {
    return 'UpdateGroupRequest{name: $name, avatarUrl: $avatarUrl, memberIds: $memberIds}';
  }
}
