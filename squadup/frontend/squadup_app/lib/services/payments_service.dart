import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/payment.dart';

class PaymentsService {
  final ApiService _apiService = ApiService();

  /// Register a new payment
  Future<Payment> registerPayment({
    required String groupId,
    required String toUserId,
    required double amount,
    String? expenseId,
  }) async {
    if (!_apiService.hasAuthToken) {
      throw Exception('User not authenticated. Please login again.');
    }

    try {
      final response = await _apiService.post(
        ApiService.paymentsEndpoint,
        data: {
          'groupId': groupId,
          'toUserId': toUserId,
          'amount': amount,
          if (expenseId != null) 'expenseId': expenseId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Payment.fromJson(response.data);
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to register payment',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to register payment',
      );
    }
  }

  /// Get all payments for a group
  Future<List<Payment>> getGroupPayments(String groupId) async {
    if (!_apiService.hasAuthToken) {
      throw Exception('User not authenticated. Please login again.');
    }

    try {
      final response = await _apiService.get(
        ApiService.paymentsByGroup(groupId),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => Payment.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch payments');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to fetch payments',
      );
    }
  }
}
