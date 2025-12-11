class Poll {
  final String id;
  final String groupId;
  final String title;
  final String type;
  final String status;
  final String? correctOptionId;
  final List<PollOption> options;
  final List<PollVote> votes;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? closedAt;
  final DateTime? deletedAt;

  Poll({
    required this.id,
    required this.groupId,
    required this.title,
    required this.type,
    required this.status,
    this.correctOptionId,
    required this.options,
    required this.votes,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
    this.deletedAt,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      correctOptionId: json['correct_option_id'] as String?,
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => PollOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      votes: (json['votes'] as List<dynamic>?)
              ?.map((e) => PollVote.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      closedAt: json['closed_at'] != null
          ? DateTime.parse(json['closed_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'title': title,
      'type': type,
      'status': status,
      'correct_option_id': correctOptionId,
      'options': options.map((e) => e.toJson()).toList(),
      'votes': votes.map((e) => e.toJson()).toList(),
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  int get totalVotes => options.fold(0, (sum, option) => sum + option.voteCount);

  bool get isActive => status == 'active';
  bool get isClosed => status == 'closed';

  PollOption? getOptionById(String optionId) {
    try {
      return options.firstWhere((option) => option.id == optionId);
    } catch (e) {
      return null;
    }
  }

  double getOptionPercentage(String optionId) {
    if (totalVotes == 0) return 0;
    final option = getOptionById(optionId);
    if (option == null) return 0;
    return (option.voteCount / totalVotes) * 100;
  }
}

class PollOption {
  final String id;
  final String pollId;
  final String text;
  final int voteCount;
  final DateTime createdAt;

  PollOption({
    required this.id,
    required this.pollId,
    required this.text,
    required this.voteCount,
    required this.createdAt,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'] as String,
      pollId: json['poll_id'] as String,
      text: json['text'] as String,
      voteCount: json['vote_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'poll_id': pollId,
      'text': text,
      'vote_count': voteCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class PollVote {
  final String id;
  final String pollId;
  final String optionId;
  final String userId;
  final DateTime createdAt;

  PollVote({
    required this.id,
    required this.pollId,
    required this.optionId,
    required this.userId,
    required this.createdAt,
  });

  factory PollVote.fromJson(Map<String, dynamic> json) {
    return PollVote(
      id: json['id'] as String,
      pollId: json['poll_id'] as String,
      optionId: json['option_id'] as String,
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'poll_id': pollId,
      'option_id': optionId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
