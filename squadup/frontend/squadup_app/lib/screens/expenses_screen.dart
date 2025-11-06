import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/expenses_service.dart';
import '../models/expense.dart';

class ExpensesScreen extends StatefulWidget {
  final String? groupId;
  final String? groupName;

  const ExpensesScreen({Key? key, this.groupId, this.groupName})
    : super(key: key);

  @override
  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen>
    with SingleTickerProviderStateMixin {
  final ExpensesService _expensesService = ExpensesService();

  late String groupId;
  late String groupName;

  List<Expense> _expenses = [];
  bool _loading = true;
  String? _error;

  // Tab controller for balance tabs
  late TabController _tabController;

  // Mock data for balances - you'll replace this with real API calls
  final List<Map<String, dynamic>> _toReceive = [
    {'name': 'Ana', 'amount': 20.0},
    {'name': 'Maria', 'amount': 10.0},
  ];

  final List<Map<String, dynamic>> _toSend = [
    {'name': 'João', 'amount': 30.0},
  ];

  // Mock data for debt simplification
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    groupId = widget.groupId ?? args?['groupId'] ?? '';
    groupName = widget.groupName ?? args?['groupName'] ?? '';
  }

  final List<Map<String, dynamic>> _simplifications = [
    {'from': 'You', 'to': 'João', 'amount': 30.0},
    {'from': 'Ana', 'to': 'You', 'amount': 20.0},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadExpenses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final expenses = await _expensesService.getExpensesByGroup(groupId);

      setState(() {
        _expenses = expenses;
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
    // TODO: Implementar tela de criar despesa
    _showSnackBar('Funcionalidade em desenvolvimento', isError: false);

    /* Exemplo de implementação futura:
    try {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => AddExpenseScreen(
            groupId: groupId,
          ),
        ),
      );

      if (mounted && result == true) {
        _loadExpenses();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erro ao abrir tela de despesa: $e', isError: true);
      }
    }
    */
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    final primaryBlue = const Color.fromARGB(255, 81, 163, 230);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? Colors.red[600] : primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryBlue = const Color.fromARGB(255, 81, 163, 230);
    final darkBlue = const Color.fromARGB(255, 29, 56, 95);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          child: Column(
            children: [
              // Header
              _buildHeader(darkBlue),

              const SizedBox(height: 25),

              // Balance tabs section
              _buildBalanceTabs(primaryBlue, darkBlue),

              const SizedBox(height: 30),

              // Add Expense button
              _buildAddExpenseButton(primaryBlue),

              const SizedBox(height: 30),

              // Debt simplification section
              _buildDebtSimplification(darkBlue),

              const SizedBox(height: 30),

              // Expenses history
              Expanded(child: _buildExpensesHistory(darkBlue)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color darkBlue) {
    return SizedBox(
      height: kToolbarHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_ios, color: darkBlue, size: 32),
              ),
              const SizedBox(width: 8),
              Text(
                groupName,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: darkBlue,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              // TODO: Open group settings
            },
            icon: Icon(Icons.settings, color: darkBlue, size: 28),
            tooltip: 'Configurações',
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceTabs(Color primaryBlue, Color darkBlue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab bar
        Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: darkBlue,
            labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            tabs: const [Tab(text: '💸 A Receber'), Tab(text: '📤 A Enviar')],
          ),
        ),

        const SizedBox(height: 20),

        // Tab content
        SizedBox(
          height: 120,
          child: TabBarView(
            controller: _tabController,
            children: [_buildToReceiveTab(darkBlue), _buildToSendTab(darkBlue)],
          ),
        ),
      ],
    );
  }

  Widget _buildToReceiveTab(Color darkBlue) {
    if (_toReceive.isEmpty) {
      return Center(
        child: Text(
          'Ninguém te deve dinheiro 🎉',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _toReceive.length,
      itemBuilder: (context, index) {
        final debt = _toReceive[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${debt['name']} deve-te',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: darkBlue,
                ),
              ),
              Text(
                '€${debt['amount'].toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToSendTab(Color darkBlue) {
    if (_toSend.isEmpty) {
      return Center(
        child: Text(
          'Não deves dinheiro a ninguém 👍',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _toSend.length,
      itemBuilder: (context, index) {
        final debt = _toSend[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Deves a ${debt['name']}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: darkBlue,
                ),
              ),
              Text(
                '€${debt['amount'].toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddExpenseButton(Color primaryBlue) {
    return Center(
      child: GestureDetector(
        onTap: _navigateToCreateExpense,
        child: Container(
          width: 200,
          height: 60,
          decoration: BoxDecoration(
            color: primaryBlue,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, color: Colors.white, size: 28),
              const SizedBox(width: 8),
              Text(
                'Add Expense',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebtSimplification(Color darkBlue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Liquidar Dívidas com Menos Passos',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: darkBlue,
          ),
        ),

        const SizedBox(height: 16),

        if (_simplifications.isEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Todas as contas estão em dia! 🎯',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
        else
          Column(
            children:
                _simplifications.map((simplification) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        // From avatar
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.blue[100],
                          child: Text(
                            simplification['from']![0],
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: darkBlue,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Arrow
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.blue[600],
                          size: 24,
                        ),

                        const SizedBox(width: 12),

                        // To avatar
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.green[100],
                          child: Text(
                            simplification['to']![0],
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: darkBlue,
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Amount
                        Text(
                          '€${simplification['amount'].toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
      ],
    );
  }

  Widget _buildExpensesHistory(Color darkBlue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Histórico de Despesas por Pagar',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: darkBlue,
          ),
        ),

        const SizedBox(height: 16),

        Expanded(child: _buildExpensesList(darkBlue)),
      ],
    );
  }

  Widget _buildExpensesList(Color darkBlue) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color.fromARGB(255, 81, 163, 230)),
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
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadExpenses,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 81, 163, 230),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Tentar Novamente',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
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
            Opacity(
              opacity: 0.3,
              child: Icon(
                Icons.receipt_long_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhuma despesa ainda',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Comece adicionando a primeira despesa do grupo',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExpenses,
      color: const Color.fromARGB(255, 81, 163, 230),
      child: ListView.builder(
        itemCount: _expenses.length,
        itemBuilder: (context, index) {
          final expense = _expenses[index];
          // TODO: Get expense status from API

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Category icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(expense.category),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getCategoryIcon(expense.category),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Expense info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expense.description,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: darkBlue,
                              ),
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
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.people,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${expense.participants.length} pessoas',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Amount and status
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '€${expense.amount.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: darkBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Pendente',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Payer info
                  if (expense.payer != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_circle,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pago por ${expense.payer!.email?.split('@')[0] ?? 'Usuário'}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '€${(expense.amount / expense.participants.length).toStringAsFixed(2)}/pessoa',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
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
