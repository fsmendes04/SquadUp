class CreateExpenseRequest {
  final String groupId;
  final String payerId;
  final double amount;
  final String description;
  final String category;
  final DateTime expenseDate;
  final List<String> participantIds;

  CreateExpenseRequest({
    required this.groupId,
    required this.payerId,
    required this.amount,
    required this.description,
    required this.category,
    required this.expenseDate,
    required this.participantIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'payer_id': payerId,
      'amount': amount,
      'description': description,
      'category': category,
      'expense_date':
          expenseDate.toIso8601String().split(
            'T',
          )[0], // Apenas a data, sem hora
      'participant_ids': participantIds,
    };
  }

  factory CreateExpenseRequest.fromJson(Map<String, dynamic> json) {
    return CreateExpenseRequest(
      groupId: json['group_id'] as String,
      payerId: json['payer_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      category: json['category'] as String,
      expenseDate: DateTime.parse(json['expense_date'] as String),
      participantIds:
          (json['participant_ids'] as List<dynamic>)
              .map((id) => id as String)
              .toList(),
    );
  }
}
