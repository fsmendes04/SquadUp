class SettleUpTransaction {
  final String from;
  final String fromName;
  final String to;
  final String toName;
  final double amount;

  SettleUpTransaction({
    required this.from,
    required this.fromName,
    required this.to,
    required this.toName,
    required this.amount,
  });

  factory SettleUpTransaction.fromJson(Map<String, dynamic> json) {
    return SettleUpTransaction(
      from: json['from'] as String,
      fromName: json['fromName'] as String,
      to: json['to'] as String,
      toName: json['toName'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'fromName': fromName,
      'to': to,
      'toName': toName,
      'amount': amount,
    };
  }
}
