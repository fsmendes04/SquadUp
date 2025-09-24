class AddMemberRequest {
  final String userId;

  AddMemberRequest({required this.userId});

  Map<String, dynamic> toJson() {
    return {'userId': userId};
  }

  @override
  String toString() {
    return 'AddMemberRequest{userId: $userId}';
  }
}
