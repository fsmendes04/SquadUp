class Expense {
  final String id;
  final String groupId;
  final String payerId;
  final double amount;
  final String description;
  final String category;
  final DateTime expenseDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final List<ExpenseParticipant> participants;
  final ExpensePayer? payer;

  Expense({
    required this.id,
    required this.groupId,
    required this.payerId,
    required this.amount,
    required this.description,
    required this.category,
    required this.expenseDate,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.participants,
    this.payer,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      payerId: json['payer_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      category: json['category'] as String,
      expenseDate: DateTime.parse(json['expense_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt:
          json['deleted_at'] != null
              ? DateTime.parse(json['deleted_at'] as String)
              : null,
      participants:
          (json['participants'] as List<dynamic>?)
              ?.map(
                (p) => ExpenseParticipant.fromJson(p as Map<String, dynamic>),
              )
              .toList() ??
          [],
      payer:
          json['payer'] != null
              ? ExpensePayer.fromJson(json['payer'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'payer_id': payerId,
      'amount': amount,
      'description': description,
      'category': category,
      'expense_date': expenseDate.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'participants': participants.map((p) => p.toJson()).toList(),
      'payer': payer?.toJson(),
    };
  }
}

class ExpenseParticipant {
  final String id;
  final String expenseId;
  final String userId;
  final double amountOwed;
  final DateTime createdAt;

  ExpenseParticipant({
    required this.id,
    required this.expenseId,
    required this.userId,
    required this.amountOwed,
    required this.createdAt,
  });

  factory ExpenseParticipant.fromJson(Map<String, dynamic> json) {
    return ExpenseParticipant(
      id: json['id'] as String,
      expenseId: json['expense_id'] as String,
      userId: json['user_id'] as String,
      amountOwed: (json['amount_owed'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expense_id': expenseId,
      'user_id': userId,
      'amount_owed': amountOwed,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ExpensePayer {
  final String id;
  final String? email;

  ExpensePayer({required this.id, this.email});

  factory ExpensePayer.fromJson(Map<String, dynamic> json) {
    return ExpensePayer(
      id: json['id'] as String,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email};
  }
}
