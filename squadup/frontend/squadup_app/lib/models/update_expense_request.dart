class UpdateExpenseRequest {
  final double? amount;
  final String? description;
  final String? category;
  final DateTime? expenseDate;
  final List<String>? participantIds;

  UpdateExpenseRequest({
    this.amount,
    this.description,
    this.category,
    this.expenseDate,
    this.participantIds,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (amount != null) data['amount'] = amount;
    if (description != null) data['description'] = description;
    if (category != null) data['category'] = category;
    if (expenseDate != null) {
      data['expense_date'] = expenseDate!.toIso8601String().split('T')[0];
    }
    if (participantIds != null) data['participant_ids'] = participantIds;

    return data;
  }

  factory UpdateExpenseRequest.fromJson(Map<String, dynamic> json) {
    return UpdateExpenseRequest(
      amount:
          json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      description: json['description'] as String?,
      category: json['category'] as String?,
      expenseDate:
          json['expense_date'] != null
              ? DateTime.parse(json['expense_date'] as String)
              : null,
      participantIds:
          json['participant_ids'] != null
              ? (json['participant_ids'] as List<dynamic>)
                  .map((id) => id as String)
                  .toList()
              : null,
    );
  }

  // Método helper para verificar se pelo menos um campo foi fornecido
  bool get hasChanges {
    return amount != null ||
        description != null ||
        category != null ||
        expenseDate != null ||
        participantIds != null;
  }
}
