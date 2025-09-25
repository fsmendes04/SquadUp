import 'package:flutter/material.dart';
import '../services/expenses_service.dart';
import '../services/groups_service.dart';
import '../services/auth_service.dart';
import '../models/expense.dart';
import '../models/expense_filter.dart';
import 'add_expense_screen.dart';

class ExpensesScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const ExpensesScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final ExpensesService _expensesService = ExpensesService();
  List<Expense> _expenses = [];
  bool _loading = true;
  String? _error;
  ExpenseFilter? _currentFilter;
  double _totalExpenses = 0.0;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final expenses = await _expensesService.getExpensesByGroup(
        widget.groupId,
        filter: _currentFilter,
      );

      final total = await _expensesService.getTotalExpensesForGroup(
        widget.groupId,
      );

      setState(() {
        _expenses = expenses;
        _totalExpenses = total;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _navigateToCreateExpense() async {
    try {
      // Carrega dados do grupo e usuário atual
      final groupsService = GroupsService();
      final authService = AuthService();

      final groupWithMembers = await groupsService.getGroup(widget.groupId);
      final currentUser = await authService.getStoredUser();

      if (currentUser == null) {
        if (mounted) {
          _showSnackBar('Erro: usuário não autenticado', isError: true);
        }
        return;
      }

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder:
              (context) => AddExpenseScreen(
                group: groupWithMembers,
                currentUserId: currentUser['id']!,
              ),
        ),
      );

      // Se a despesa foi criada com sucesso, recarrega a lista
      if (result == true) {
        _loadExpenses();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erro ao carregar dados do grupo: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Despesas'),
            Text(
              widget.groupName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _currentFilter != null ? Icons.filter_alt : Icons.filter_list,
              color: _currentFilter != null ? Colors.blue : null,
            ),
            onPressed: () {
              // TODO: Implementar filtros
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadExpenses),
        ],
      ),
      body: Column(
        children: [
          // Card com estatísticas
          _buildStatsCard(),
          // Lista de despesas
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateExpense,
        tooltip: 'Adicionar Despesa',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  _expenses.length.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Text('Despesas'),
              ],
            ),
            Column(
              children: [
                Text(
                  'R\$ ${_totalExpenses.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Text('Total Gasto'),
              ],
            ),
            if (_expenses.isNotEmpty)
              Column(
                children: [
                  Text(
                    'R\$ ${(_totalExpenses / _expenses.length).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const Text('Média'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando despesas...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar despesas',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadExpenses,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhuma despesa encontrada',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Adicione a primeira despesa do grupo',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _navigateToCreateExpense,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Despesa'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExpenses,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _expenses.length,
        itemBuilder: (context, index) {
          final expense = _expenses[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: _getCategoryColor(expense.category),
                child: Icon(
                  _getCategoryIcon(expense.category),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: Text(
                expense.description,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.category, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        expense.category.toUpperCase(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(expense.expenseDate),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${expense.participants.length} participantes',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                      if (expense.payer != null) ...[
                        const SizedBox(width: 16),
                        Icon(Icons.person, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Pago por ${expense.payer!.email?.split('@')[0] ?? 'Usuário'}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R\$ ${expense.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    'R\$ ${(expense.amount / expense.participants.length).toStringAsFixed(2)}/pessoa',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              onTap: () {
                // TODO: Navegar para detalhes da despesa
              },
            ),
          );
        },
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'alimentacao':
      case 'alimentação':
        return Colors.orange;
      case 'transporte':
        return Colors.blue;
      case 'entretenimento':
        return Colors.purple;
      case 'compras':
        return Colors.green;
      case 'saude':
      case 'saúde':
        return Colors.red;
      case 'hospedagem':
        return Colors.brown;
      case 'educacao':
      case 'educação':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'alimentacao':
      case 'alimentação':
        return Icons.restaurant;
      case 'transporte':
        return Icons.directions_car;
      case 'entretenimento':
        return Icons.movie;
      case 'compras':
        return Icons.shopping_bag;
      case 'saude':
      case 'saúde':
        return Icons.local_hospital;
      case 'hospedagem':
        return Icons.home;
      case 'educacao':
      case 'educação':
        return Icons.school;
      default:
        return Icons.receipt;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
