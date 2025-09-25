class ExpenseFilter {
  final String? payerId;
  final String? participantId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? category;

  ExpenseFilter({
    this.payerId,
    this.participantId,
    this.startDate,
    this.endDate,
    this.category,
  });

  Map<String, dynamic> toQueryParameters() {
    final Map<String, dynamic> params = {};

    if (payerId != null) params['payer_id'] = payerId;
    if (participantId != null) params['participant_id'] = participantId;
    if (startDate != null) {
      params['start_date'] = startDate!.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      params['end_date'] = endDate!.toIso8601String().split('T')[0];
    }
    if (category != null) params['category'] = category;

    return params;
  }

  factory ExpenseFilter.fromJson(Map<String, dynamic> json) {
    return ExpenseFilter(
      payerId: json['payer_id'] as String?,
      participantId: json['participant_id'] as String?,
      startDate:
          json['start_date'] != null
              ? DateTime.parse(json['start_date'] as String)
              : null,
      endDate:
          json['end_date'] != null
              ? DateTime.parse(json['end_date'] as String)
              : null,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payer_id': payerId,
      'participant_id': participantId,
      'start_date': startDate?.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'category': category,
    };
  }

  // Método helper para verificar se há filtros ativos
  bool get hasFilters {
    return payerId != null ||
        participantId != null ||
        startDate != null ||
        endDate != null ||
        category != null;
  }

  // Método helper para criar filtro apenas por período
  factory ExpenseFilter.byDateRange(DateTime startDate, DateTime endDate) {
    return ExpenseFilter(startDate: startDate, endDate: endDate);
  }

  // Método helper para criar filtro apenas por categoria
  factory ExpenseFilter.byCategory(String category) {
    return ExpenseFilter(category: category);
  }

  // Método helper para criar filtro apenas por pagador
  factory ExpenseFilter.byPayer(String payerId) {
    return ExpenseFilter(payerId: payerId);
  }

  // Método helper para criar filtro apenas por participante
  factory ExpenseFilter.byParticipant(String participantId) {
    return ExpenseFilter(participantId: participantId);
  }
}
