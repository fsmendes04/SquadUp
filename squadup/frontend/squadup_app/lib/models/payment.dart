class Payment {
  final String id;
  final String groupId;
  final String fromUserId;
  final String toUserId;
  final double amount;
  final String paymentDate;
  final String? expenseId;
  final String createdAt;

  Payment({
    required this.id,
    required this.groupId,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.paymentDate,
    this.expenseId,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      fromUserId: json['from_user_id'] as String,
      toUserId: json['to_user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentDate: json['payment_date'] as String,
      expenseId: json['expense_id'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'amount': amount,
      'payment_date': paymentDate,
      'expense_id': expenseId,
      'created_at': createdAt,
    };
  }
}
