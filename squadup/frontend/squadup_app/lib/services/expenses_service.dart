import 'package:dio/dio.dart';
import '../models/expense.dart';
import '../models/create_expense_request.dart';
import '../models/update_expense_request.dart';
import '../models/expense_filter.dart';
import 'api_service.dart';

class ExpensesService {
  static final ExpensesService _instance = ExpensesService._internal();
  factory ExpensesService() => _instance;
  ExpensesService._internal();

  final ApiService _apiService = ApiService();

  static const String _expensesEndpoint = '/expenses';

  Future<Expense> createExpense(CreateExpenseRequest request) async {
    try {
      final response = await _apiService.post(
        _expensesEndpoint,
        data: request.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Expense.fromJson(response.data);
      } else {
        throw Exception('Erro ao criar despesa: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'Erro ao criar despesa');
    } catch (e) {
      throw Exception('Erro inesperado ao criar despesa: $e');
    }
  }

  Future<List<Expense>> getExpensesByGroup(
    String groupId, {
    ExpenseFilter? filter,
  }) async {
    try {
      String endpoint = '$_expensesEndpoint/group/$groupId';

      Map<String, dynamic>? queryParameters;
      if (filter != null && filter.hasFilters) {
        queryParameters = filter.toQueryParameters();
      }

      final response = await _apiService.get(
        endpoint,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data
            .map((json) => Expense.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Erro ao buscar despesas: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'Erro ao buscar despesas');
    } catch (e) {
      throw Exception('Erro inesperado ao buscar despesas: $e');
    }
  }

  Future<Expense> getExpenseById(String expenseId) async {
    try {
      final response = await _apiService.get('$_expensesEndpoint/$expenseId');

      if (response.statusCode == 200) {
        return Expense.fromJson(response.data);
      } else {
        throw Exception('Erro ao buscar despesa: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'Erro ao buscar despesa');
    } catch (e) {
      throw Exception('Erro inesperado ao buscar despesa: $e');
    }
  }

  /// Atualiza uma despesa existente
  /// [expenseId] - ID da despesa a ser atualizada
  /// [request] - Dados a serem atualizados
  Future<Expense> updateExpense(
    String expenseId,
    UpdateExpenseRequest request,
  ) async {
    try {
      if (!request.hasChanges) {
        throw Exception('Nenhuma alteração foi fornecida');
      }

      final response = await _apiService.put(
        '$_expensesEndpoint/$expenseId',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return Expense.fromJson(response.data);
      } else {
        throw Exception('Erro ao atualizar despesa: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'Erro ao atualizar despesa');
    } catch (e) {
      throw Exception('Erro inesperado ao atualizar despesa: $e');
    }
  }

  /// Deleta uma despesa (soft delete)
  /// [expenseId] - ID da despesa a ser deletada
  Future<void> deleteExpense(String expenseId) async {
    try {
      final response = await _apiService.delete(
        '$_expensesEndpoint/$expenseId',
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao deletar despesa: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'Erro ao deletar despesa');
    } catch (e) {
      throw Exception('Erro inesperado ao deletar despesa: $e');
    }
  }

  Future<List<Expense>> getExpensesByCategory(
    String groupId,
    String category,
  ) async {
    final filter = ExpenseFilter.byCategory(category);
    return getExpensesByGroup(groupId, filter: filter);
  }

  Future<List<Expense>> getExpensesByPayer(
    String groupId,
    String payerId,
  ) async {
    final filter = ExpenseFilter.byPayer(payerId);
    return getExpensesByGroup(groupId, filter: filter);
  }

  Future<List<Expense>> getExpensesByParticipant(
    String groupId,
    String participantId,
  ) async {
    final filter = ExpenseFilter.byParticipant(participantId);
    return getExpensesByGroup(groupId, filter: filter);
  }

  Future<List<Expense>> getExpensesByDateRange(
    String groupId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final filter = ExpenseFilter.byDateRange(startDate, endDate);
    return getExpensesByGroup(groupId, filter: filter);
  }

  Future<double> getTotalExpensesForGroup(String groupId) async {
    try {
      final expenses = await getExpensesByGroup(groupId);
      return expenses.fold<double>(
        0.0,
        (total, expense) => total + expense.amount,
      );
    } catch (e) {
      throw Exception('Erro ao calcular total de despesas: $e');
    }
  }

  /// Calcula quanto um usuário deve em um grupo
  /// [groupId] - ID do grupo
  /// [userId] - ID do usuário
  Future<double> getUserDebtInGroup(String groupId, String userId) async {
    try {
      final expenses = await getExpensesByGroup(groupId);
      double totalDebt = 0.0;

      for (final expense in expenses) {
        for (final participant in expense.participants) {
          if (participant.userId == userId) {
            totalDebt += participant.amountOwed;
          }
        }
      }

      return totalDebt;
    } catch (e) {
      throw Exception('Erro ao calcular dívida do usuário: $e');
    }
  }

  /// Calcula quanto um usuário pagou em um grupo
  /// [groupId] - ID do grupo
  /// [userId] - ID do usuário
  Future<double> getUserPaymentsInGroup(String groupId, String userId) async {
    try {
      final expenses = await getExpensesByPayer(groupId, userId);
      return expenses.fold<double>(
        0.0,
        (total, expense) => total + expense.amount,
      );
    } catch (e) {
      throw Exception('Erro ao calcular pagamentos do usuário: $e');
    }
  }

  /// Calcula o balanço de um usuário em um grupo (pagamentos - dívidas)
  /// [groupId] - ID do grupo
  /// [userId] - ID do usuário
  Future<double> getUserBalanceInGroup(String groupId, String userId) async {
    try {
      final payments = await getUserPaymentsInGroup(groupId, userId);
      final debts = await getUserDebtInGroup(groupId, userId);
      return payments - debts;
    } catch (e) {
      throw Exception('Erro ao calcular balanço do usuário: $e');
    }
  }

  /// Trata erros do Dio e retorna mensagens mais amigáveis
  Exception _handleDioException(
    DioException dioException,
    String defaultMessage,
  ) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
        return Exception(
          'Timeout de conexão. Verifique sua conexão com a internet.',
        );
      case DioExceptionType.sendTimeout:
        return Exception('Timeout ao enviar dados. Tente novamente.');
      case DioExceptionType.receiveTimeout:
        return Exception('Timeout ao receber dados. Tente novamente.');
      case DioExceptionType.badResponse:
        final statusCode = dioException.response?.statusCode;
        final message =
            dioException.response?.data?['message'] ?? defaultMessage;

        switch (statusCode) {
          case 400:
            return Exception('Dados inválidos: $message');
          case 401:
            return Exception('Não autorizado. Faça login novamente.');
          case 403:
            return Exception(
              'Acesso negado. Você não tem permissão para esta ação.',
            );
          case 404:
            return Exception('Recurso não encontrado.');
          case 409:
            return Exception('Conflito: $message');
          case 500:
            return Exception(
              'Erro interno do servidor. Tente novamente mais tarde.',
            );
          default:
            return Exception('$defaultMessage: $message');
        }
      case DioExceptionType.cancel:
        return Exception('Operação cancelada.');
      case DioExceptionType.connectionError:
        return Exception(
          'Erro de conexão. Verifique sua conexão com a internet.',
        );
      default:
        return Exception('$defaultMessage: ${dioException.message}');
    }
  }
}
