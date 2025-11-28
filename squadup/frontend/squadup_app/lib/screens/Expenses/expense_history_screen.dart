import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/expenses_service.dart';
import '../../models/expense.dart';
import '../../widgets/loading_overlay.dart';
import 'update_expense_screen.dart';

class ExpenseHistoryScreen extends StatefulWidget {
  final String? groupId;
  final String? groupName;

  const ExpenseHistoryScreen({super.key, this.groupId, this.groupName});

  @override
  State<ExpenseHistoryScreen> createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends State<ExpenseHistoryScreen> {
  final ExpensesService _expensesService = ExpensesService();

  List<Expense> _expenses = [];
  bool _loading = true;
  String? _error;
  String? _groupId;
  String? _groupName;
  bool _initialized = false;
  String _selectedPeriod = 'month';
  DateTime _selectedMonth = DateTime.now();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _groupId = widget.groupId;
      _groupName = widget.groupName;
      if ((_groupId == null || _groupId!.isEmpty) ||
          (_groupName == null || _groupName!.isEmpty)) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        _groupId = args?['groupId'] ?? '';
        _groupName = args?['groupName'] ?? '';
      }
      _loadExpenses();
      _initialized = true;
    }
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final expenses = await _expensesService.getExpensesByGroup(
        _groupId ?? '',
      );
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

  final darkBlue = const Color.fromARGB(255, 29, 56, 95);
  final primaryBlue = const Color.fromARGB(255, 81, 163, 230);

  @override
  Widget build(BuildContext context) {
    final darkBlue = const Color.fromARGB(255, 29, 56, 95);

    return LoadingOverlay(
      isLoading: _loading,
      message: 'Loading expense history...',
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: _buildHeader(darkBlue),
              ),

              const SizedBox(height: 10),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_loading && _error == null) ...[
                          _buildPeriodSelector(darkBlue),
                          const SizedBox(height: 4),
                          if (_getFilteredExpenses().isNotEmpty) ...[
                            _buildSpendingByCategory(darkBlue),
                            const SizedBox(height: 20),
                          ],
                      ],
                      _buildExpensesList(darkBlue),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
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
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios, color: darkBlue, size: 32),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Expense History',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: darkBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(Color darkBlue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Linha dos botões Month e Year
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Botão Month
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = 'month';
                });
              },
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: darkBlue, width: 2),
                    ),
                    child: Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              _selectedPeriod == 'month'
                                  ? darkBlue
                                  : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Month',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: darkBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            // Botão Year
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = 'year';
                });
              },
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: darkBlue, width: 2),
                    ),
                    child: Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              _selectedPeriod == 'year'
                                  ? darkBlue
                                  : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Year',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: darkBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Card Total Expenses
        const SizedBox(height: 16),
        _buildTotalExpensesCard(darkBlue),
        if (_selectedPeriod == 'month') ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 28),
                color: darkBlue,
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month - 1,
                    );
                  });
                },
              ),
              Text(
                '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: darkBlue,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 28),
                color: darkBlue,
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month + 1,
                    );
                  });
                },
              ),
            ],
          ),
        ],
        if (_selectedPeriod == 'year') ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 28),
                color: darkBlue,
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year - 1,
                      _selectedMonth.month,
                    );
                  });
                },
              ),
              Text(
                '${_selectedMonth.year}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: darkBlue,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 28),
                color: darkBlue,
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year + 1,
                      _selectedMonth.month,
                    );
                  });
                },
              ),
            ],
          ),
        ],
      ],
    );
  }

  List<Expense> _getFilteredExpenses() {
    if (_selectedPeriod == 'month') {
      // Filter expenses for selected month
      return _expenses.where((expense) {
        return expense.expenseDate.year == _selectedMonth.year &&
            expense.expenseDate.month == _selectedMonth.month;
      }).toList();
    } else {
      // Filter expenses for selected year
      return _expenses.where((expense) {
        return expense.expenseDate.year == _selectedMonth.year;
      }).toList();
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Widget _buildTotalExpensesCard(Color darkBlue) {
    final filteredExpenses = _getFilteredExpenses();
    final totalExpenses = filteredExpenses.fold<double>(
      0.0,
      (sum, expense) => sum + expense.amount,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(
              255,
              81,
              163,
              230,
            ).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Total Expenses',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '€ ${totalExpenses.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingByCategory(Color darkBlue) {
    final filteredExpenses = _getFilteredExpenses();

    // Calculate spending by category
    final Map<String, double> categoryTotals = {};
    for (var expense in filteredExpenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    // Sort by amount descending
    final sortedCategories =
        categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final totalExpenses = filteredExpenses.fold<double>(
      0.0,
      (sum, expense) => sum + expense.amount,
    );

    // Define colors for categories
    final List<Color> categoryColors = [
      primaryBlue,
      darkBlue,
      primaryBlue,
      darkBlue,
      primaryBlue,
      darkBlue,
      primaryBlue,
      darkBlue,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending by Category',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: darkBlue,
            ),
          ),
          const SizedBox(height: 20),
          if (sortedCategories.isEmpty)
            Text(
              'No expenses to display',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            )
          else ...[
            ...sortedCategories.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value.key;
              final amount = entry.value.value;
              final percentage = (amount / totalExpenses) * 100;
              final color = categoryColors[index % categoryColors.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: darkBlue,
                          ),
                        ),
                        Text(
                          '€${amount.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: darkBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 14,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
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
                'Loading expenses...',
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
                'Error loading expenses',
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
                  'Try Again',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_getFilteredExpenses().isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 400,
              height: 400,
              child: Center(
                child: Opacity(
                  opacity: 0.12,
                  child: Image.asset(
                    'lib/images/logo_v3.png',
                    width: 300,
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Text(
              "No expenses found",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

          ],
        ),
      );
    }

    final displayExpenses = _getFilteredExpenses();

    return Column(
      children:
          displayExpenses.map((expense) {
            return GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpdateExpenseScreen(expense: expense),
                  ),
                );

                // Reload expenses if update or delete was successful
                if (result == true) {
                  _loadExpenses();
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                              color: darkBlue,
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
                                      '${expense.participants.length + 1}',
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
                                  'Paid by ${expense.payer!.email?.split('@')[0] ?? 'User'}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '€${(expense.amount / expense.participants.length).toStringAsFixed(2)}/person',
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
              ),
            );
          }).toList(),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
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
      case 'educação':
        return Icons.school;
      default:
        return Icons.receipt;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
