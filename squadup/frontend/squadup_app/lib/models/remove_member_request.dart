class RemoveMemberRequest {
  final String userId;

  RemoveMemberRequest({required this.userId});

  Map<String, dynamic> toJson() {
    return {'userId': userId};
  }

  @override
  String toString() {
    return 'RemoveMemberRequest{userId: $userId}';
  }
}
