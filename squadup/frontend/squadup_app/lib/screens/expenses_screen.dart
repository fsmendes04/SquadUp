import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/expenses_service.dart';
import '../services/storage_service.dart';
import '../models/expense.dart';

class ExpensesScreen extends StatefulWidget {
  final String? groupId;
  final String? groupName;

  const ExpensesScreen({super.key, this.groupId, this.groupName});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen>
    with SingleTickerProviderStateMixin {
  final ExpensesService _expensesService = ExpensesService();

  late String groupId;
  late String groupName;
  late TabController _tabController;

  List<Expense> _expenses = [];
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _userBalances = [];
  List<Map<String, dynamic>> _simplifications = [];
  bool _initialized = false;
  String? _currentUserName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      groupId = widget.groupId ?? args?['groupId'] ?? '';
      groupName = widget.groupName ?? args?['groupName'] ?? '';
      _loadCurrentUser();
      _loadExpenses();
      _initialized = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final storageService = StorageService();
      final userProfile = await storageService.getUserProfile();
      if (userProfile != null && mounted) {
        setState(() {
          _currentUserName = userProfile['name'];
        });
      }
    } catch (e) {
      // Silently fail if unable to load user profile
    }
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final expenses = await _expensesService.getExpensesByGroup(groupId);
      final balances = await _expensesService.getUserBalances(groupId);

      setState(() {
        _expenses = expenses;
        _userBalances = balances;
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
      final result = await Navigator.pushNamed(
        context,
        '/add-expense',
        arguments: {'groupId': groupId, 'groupName': groupName},
      );

      if (mounted && result == true) {
        _loadExpenses();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erro ao abrir tela de despesa: $e', isError: true);
      }
    }
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
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: _buildHeader(darkBlue),
            ),

            const SizedBox(height: 20),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance Chart
                    _buildBalanceChart(primaryBlue, darkBlue),

                    const SizedBox(height: 24),

                    // Balance tabs and content
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 45,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
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
                              tabs: const [
                                Tab(text: 'A Receber'),
                                Tab(text: 'A Enviar'),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 110,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // To Receive Tab
                                SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children:
                                        _userBalances
                                            .where(
                                              (u) =>
                                                  u['toPay'] > 0 &&
                                                  u['name'] != _currentUserName,
                                            )
                                            .map(
                                              (u) => Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                      horizontal: 12,
                                                    ),
                                                padding: const EdgeInsets.all(
                                                  14,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green[50],
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.green[200]!,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      '${u['name']} deve-te',
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: darkBlue,
                                                          ),
                                                    ),
                                                    Text(
                                                      '€${u['toPay'].toStringAsFixed(2)}',
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color:
                                                                Colors
                                                                    .green[700],
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  ),
                                ),
                                // To Send Tab
                                SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children:
                                        _userBalances
                                            .where(
                                              (u) =>
                                                  u['toReceive'] > 0 &&
                                                  u['name'] != _currentUserName,
                                            )
                                            .map(
                                              (u) => Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                      horizontal: 12,
                                                    ),
                                                padding: const EdgeInsets.all(
                                                  14,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red[50],
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.red[200]!,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      'Deves a ${u['name']}',
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: darkBlue,
                                                          ),
                                                    ),
                                                    Text(
                                                      '€${u['toReceive'].toStringAsFixed(2)}',
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color:
                                                                Colors.red[700],
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Add Expense button
                    _buildAddExpenseButton(primaryBlue),

                    const SizedBox(height: 24),

                    // Debt simplification section
                    _buildDebtSimplification(darkBlue, primaryBlue),

                    const SizedBox(height: 24),

                    // Expenses history
                    _buildExpensesHistory(darkBlue),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
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

  Widget _buildBalanceChart(Color primaryBlue, Color darkBlue) {
    // Calculate max value for chart scaling
    double maxValue = 0;
    for (var user in _userBalances) {
      final receive = (user['toReceive'] as num).toDouble();
      final pay = (user['toPay'] as num).toDouble();
      maxValue = [maxValue, receive, pay].reduce((a, b) => a > b ? a : b);
    }
    if (maxValue == 0) maxValue = 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: darkBlue, size: 24),
              const SizedBox(width: 8),
              Text(
                'Balanço do Grupo',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: darkBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Chart - centered at zero
          Column(
            children:
                _userBalances.map((user) {
                  final name = (user['name'] as String);
                  final displayName =
                      (_currentUserName != null && name == _currentUserName)
                          ? 'You'
                          : name;
                  final toReceive = (user['toReceive'] as num).toDouble();
                  final toPay = (user['toPay'] as num).toDouble();

                  final receivePercent =
                      maxValue > 0 ? (toReceive / maxValue * 100).round() : 0;
                  final payPercent =
                      maxValue > 0 ? (toPay / maxValue * 100).round() : 0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          displayName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: darkBlue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Left side - To Pay (red) - grows from center to left
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 100 - payPercent,
                                    child: const SizedBox(),
                                  ),
                                  // Bar
                                  if (toPay > 0)
                                    Expanded(
                                      flex: payPercent,
                                      child: Container(
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF8A80),
                                          borderRadius:
                                              const BorderRadius.horizontal(
                                                left: Radius.circular(8),
                                              ),
                                        ),
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Text(
                                          '€${toPay.toStringAsFixed(2)}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Center line (zero point)
                            Container(
                              width: 3,
                              height: 32,
                              color: darkBlue.withValues(alpha: 0.5),
                            ),

                            // Right side - To Receive (cyan) - grows from center to right
                            Expanded(
                              child: Row(
                                children: [
                                  // Bar
                                  if (toReceive > 0)
                                    Expanded(
                                      flex: receivePercent,
                                      child: Container(
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4DD0E1),
                                          borderRadius:
                                              const BorderRadius.horizontal(
                                                right: Radius.circular(8),
                                              ),
                                        ),
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: Text(
                                          '€${toReceive.toStringAsFixed(2)}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  // Empty space
                                  Expanded(
                                    flex: 100 - receivePercent,
                                    child: const SizedBox(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),

          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A80),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'A Enviar',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 20),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF4DD0E1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'A Receber',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
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

  Widget _buildDebtSimplification(Color darkBlue, Color primaryBlue) {
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
            child: Text(
              'Nenhuma simplificação disponível.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else
          Column(
            children:
                _simplifications.map((simplification) {
                  // ...existing code...
                  // (Mantenha o restante do widget igual, mas agora depende dos dados reais)
                  return Container();
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
          'Histórico de Despesas',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: darkBlue,
          ),
        ),

        const SizedBox(height: 16),

        _buildExpensesList(darkBlue),
      ],
    );
  }

  Widget _buildExpensesList(Color darkBlue) {
    if (_loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              const CircularProgressIndicator(
                color: Color.fromARGB(255, 81, 163, 230),
              ),
              const SizedBox(height: 16),
              Text(
                'Carregando despesas...',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Erro ao carregar despesas',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: darkBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Tentar Novamente',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_expenses.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: 0.3,
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Nenhuma despesa ainda',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: darkBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Comece adicionando a primeira despesa',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children:
          _expenses.map((expense) {
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
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.people,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${expense.participants.length}',
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

                        // Amount
                        Text(
                          '€${expense.amount.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: darkBlue,
                          ),
                        ),
                      ],
                    ),

                    if (expense.payer != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
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
                            Expanded(
                              child: Text(
                                'Pago por ${expense.payer!.email?.split('@')[0] ?? 'Usuário'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '€${(expense.amount / expense.participants.length).toStringAsFixed(2)}/pessoa',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
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
