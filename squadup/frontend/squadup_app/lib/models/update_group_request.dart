class UpdateGroupRequest {
  final String? name;
  final List<String>? memberIds;

  UpdateGroupRequest({this.name, this.memberIds});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (name != null) json['name'] = name;
    if (memberIds != null) json['memberIds'] = memberIds;
    return json;
  }

  @override
  String toString() {
    return 'UpdateGroupRequest{name: $name, memberIds: $memberIds}';
  }
}
