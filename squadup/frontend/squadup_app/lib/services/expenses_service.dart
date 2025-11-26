import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/expense.dart';

class ExpensesService {
  final ApiService _apiService;

  ExpensesService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  Future<Expense> createExpense(CreateExpenseDto createExpenseDto) async {
    if (!_apiService.hasAuthToken) {
      throw Exception('Usuário não autenticado. Faça login novamente.');
    }

    try {
      final response = await _apiService.post(
        ApiService.expensesEndpoint,
        data: createExpenseDto.toJson(),
      );

      final result = _handleResponse(response);
      return Expense.fromJson(result['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get expense by ID
  Future<Expense> getExpenseById(String expenseId) async {
    if (!_apiService.hasAuthToken) {
      throw Exception('Usuário não autenticado. Faça login novamente.');
    }

    try {
      final response = await _apiService.get(ApiService.expenseById(expenseId));

      final result = _handleResponse(response);
      return Expense.fromJson(result['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get all expenses for a group with optional filters
  Future<List<Expense>> getExpensesByGroup(
    String groupId, {
    FilterExpensesDto? filters,
  }) async {
    if (!_apiService.hasAuthToken) {
      throw Exception('Usuário não autenticado. Faça login novamente.');
    }

    try {
      final response = await _apiService.get(
        ApiService.expensesByGroup(groupId),
        queryParameters: filters?.toQueryParameters(),
      );

      final result = _handleResponse(response);
      final List<dynamic> expensesData = result['data'] as List<dynamic>;

      return expensesData
          .map((expense) => Expense.fromJson(expense as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get expenses by category for a group
  Future<List<Expense>> getExpensesByCategory(
    String groupId,
    String category,
  ) async {
    if (!_apiService.hasAuthToken) {
      throw Exception('Usuário não autenticado. Faça login novamente.');
    }

    try {
      final response = await _apiService.get(
        ApiService.expensesByCategory(groupId, category),
      );

      final result = _handleResponse(response);
      final List<dynamic> expensesData = result['data'] as List<dynamic>;

      return expensesData
          .map((expense) => Expense.fromJson(expense as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update an expense
  Future<Expense> updateExpense(
    String expenseId,
    UpdateExpenseDto updateExpenseDto,
  ) async {
    if (!_apiService.hasAuthToken) {
      throw Exception('Usuário não autenticado. Faça login novamente.');
    }

    final data = updateExpenseDto.toJson();
    if (data.isEmpty) {
      throw Exception('At least one field must be provided for update');
    }

    try {
      final response = await _apiService.put(
        ApiService.expenseById(expenseId),
        data: data,
      );

      final result = _handleResponse(response);
      return Expense.fromJson(result['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete an expense (soft delete)
  Future<void> deleteExpense(String expenseId) async {
    if (!_apiService.hasAuthToken) {
      throw Exception('Usuário não autenticado. Faça login novamente.');
    }

    try {
      final response = await _apiService.delete(
        ApiService.expenseById(expenseId),
      );

      _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get group balance - who owes and who is owed
  Future<List<Map<String, dynamic>>> getUserBalances(String groupId) async {
    if (!_apiService.hasAuthToken) {
      throw Exception('Usuário não autenticado. Faça login novamente.');
    }

    try {
      final response = await _apiService.get(ApiService.groupBalance(groupId));

      final result = _handleResponse(response);
      final List<dynamic> balancesData = result['data'] as List<dynamic>;

      return balancesData
          .map((balance) => balance as Map<String, dynamic>)
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Map<String, dynamic> _handleResponse(Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.data as Map<String, dynamic>;
    } else {
      final data = response.data;
      if (data is Map<String, dynamic> && data['message'] != null) {
        final message = data['message'];
        if (message is List && message.isNotEmpty) {
          throw Exception(message.first.toString().split('\n').first);
        } else if (message is String && message.isNotEmpty) {
          throw Exception(message.split('\n').first);
        }
      }
      throw Exception('Unexpected status code: ${response.statusCode}');
    }
  }

  Exception _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response?.data;

      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is List && message.isNotEmpty) {
          final first = message.first.toString();
          return Exception(first.split('\n').first);
        } else if (message is String && message.isNotEmpty) {
          return Exception(message.split('\n').first);
        }
        return Exception('Error: ${error.response?.statusCode}');
      }

      return Exception('Error: ${error.response?.statusCode}');
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return Exception(
        'Connection timeout. Please check your internet connection.',
      );
    } else if (error.type == DioExceptionType.connectionError) {
      return Exception(
        'Connection failed. Please check your internet connection.',
      );
    } else {
      return Exception('An unexpected error occurred: ${error.message}');
    }
  }
}
