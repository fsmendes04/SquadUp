import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/expenses_service.dart';
import '../../models/expense.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/header.dart';
import 'update_expense_screen.dart';
import '../../config/responsive_utils.dart';

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
    final r = context.responsive;
    final darkBlue = const Color.fromARGB(255, 29, 56, 95);

    return LoadingOverlay(
      isLoading: _loading,
      message: 'Loading expense history...',
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
                CustomHeader(
                  darkBlue: darkBlue,
                  title: 'Expense History',      
              ),
              SizedBox(height: r.height(10)),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: r.width(14.0)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_loading && _error == null) ...[
                        _buildPeriodSelector(darkBlue),
                        SizedBox(height: r.height(4)),
                        if (_getFilteredExpenses().isNotEmpty) ...[
                          _buildSpendingByCategory(darkBlue),
                          SizedBox(height: r.height(20)),
                        ],
                      ],
                      _buildExpensesList(darkBlue),
                      SizedBox(height: r.height(20)),
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


  Widget _buildPeriodSelector(Color darkBlue) {
    final r = context.responsive;
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
                    width: r.width(20),
                    height: r.width(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: darkBlue, width: r.borderWidth(2)),
                    ),
                    child: Center(
                      child: Container(
                        width: r.width(12),
                        height: r.width(12),
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
                  SizedBox(width: r.width(8)),
                  Text(
                    'Month',
                    style: GoogleFonts.poppins(
                      fontSize: r.fontSize(15),
                      fontWeight: FontWeight.w600,
                      color: darkBlue,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: r.width(32)),
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
                    width: r.width(20),
                    height: r.width(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: darkBlue, width: r.borderWidth(2)),
                    ),
                    child: Center(
                      child: Container(
                        width: r.width(10),
                        height: r.width(10),
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
                  SizedBox(width: r.width(8)),
                  Text(
                    'Year',
                    style: GoogleFonts.poppins(
                      fontSize: r.fontSize(15),
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
        SizedBox(height: r.height(16)),
        _buildTotalExpensesCard(darkBlue),
        if (_selectedPeriod == 'month') ...[
          SizedBox(height: r.height(10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, size: r.iconSize(28)),
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
                  fontSize: r.fontSize(16),
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
          SizedBox(height: r.height(10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, size: r.iconSize(28)),
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
                  fontSize: r.fontSize(16),
                  fontWeight: FontWeight.w600,
                  color: darkBlue,
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, size: r.iconSize(28)),
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
    final r = context.responsive;
    final filteredExpenses = _getFilteredExpenses();
    final totalExpenses = filteredExpenses.fold<double>(
      0.0,
      (sum, expense) => sum + expense.amount,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(r.width(24)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(r.borderRadius(20)),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(
              255,
              81,
              163,
              230,
            ).withValues(alpha: 0.3),
            blurRadius: r.height(15),
            offset: Offset(0, r.height(5)),
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
                  fontSize: r.fontSize(17),
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          SizedBox(height: r.height(14)),
          Text(
            '€ ${totalExpenses.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: r.fontSize(36),
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
    final r = context.responsive;
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
      padding: EdgeInsets.all(r.width(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.borderRadius(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: r.height(10),
            offset: Offset(0, r.height(2)),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!, width: r.borderWidth(1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending by Category',
            style: GoogleFonts.poppins(
              fontSize: r.fontSize(18),
              fontWeight: FontWeight.w600,
              color: darkBlue,
            ),
          ),
          SizedBox(height: r.height(20)),
          if (sortedCategories.isEmpty)
            Text(
              'No expenses to display',
              style: GoogleFonts.poppins(
                fontSize: r.fontSize(14),
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
                padding: EdgeInsets.only(bottom: r.height(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category,
                          style: GoogleFonts.poppins(
                            fontSize: r.fontSize(14),
                            fontWeight: FontWeight.w500,
                            color: darkBlue,
                          ),
                        ),
                        Text(
                          '€${amount.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: r.fontSize(14),
                            fontWeight: FontWeight.w600,
                            color: darkBlue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: r.height(8)),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(r.borderRadius(10)),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: r.height(14),
                        borderRadius: BorderRadius.circular(r.borderRadius(10)),
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
    final r = context.responsive;
    if (_loading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(r.width(40.0)),
          child: Column(
            children: [
              const CircularProgressIndicator(
                color: Color.fromARGB(255, 81, 163, 230),
              ),
              SizedBox(height: r.height(16)),
              Text(
                'Loading expenses...',
                style: GoogleFonts.poppins(
                  fontSize: r.fontSize(14),
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
          padding: EdgeInsets.all(r.width(24)),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(r.borderRadius(12)),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: r.iconSize(48), color: Colors.red[300]),
              SizedBox(height: r.height(16)),
              Text(
                'Error loading expenses',
                style: GoogleFonts.poppins(
                  fontSize: r.fontSize(16),
                  fontWeight: FontWeight.w600,
                  color: darkBlue,
                ),
              ),
              SizedBox(height: r.height(8)),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: r.fontSize(13),
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: r.height(16)),
              ElevatedButton(
                onPressed: _loadExpenses,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 81, 163, 230),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(r.borderRadius(12)),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: r.width(24),
                    vertical: r.height(12),
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
        padding: EdgeInsets.symmetric(horizontal: r.width(32.0), vertical: r.height(10.0)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: r.width(400),
              height: r.height(400),
              child: Center(
                child: Opacity(
                  opacity: 0.12,
                  child: Image.asset(
                    'lib/images/logo_v3.png',
                    width: r.width(300),
                    height: r.height(300),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Text(
              "No expenses found",
              style: GoogleFonts.poppins(
                fontSize: r.fontSize(22),
                fontWeight: FontWeight.w400,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: r.height(40)),

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
                margin: EdgeInsets.only(bottom: r.height(12)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(r.borderRadius(16)),
                  border: Border.all(color: Colors.grey[200]!, width: r.borderWidth(1)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(r.width(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Category icon
                          Container(
                            width: r.width(48),
                            height: r.width(48),
                            decoration: BoxDecoration(
                              color: darkBlue,
                              borderRadius: BorderRadius.circular(r.borderRadius(12)),
                            ),
                            child: Icon(
                              _getCategoryIcon(expense.category),
                              color: Colors.white,
                              size: r.iconSize(24),
                            ),
                          ),

                          SizedBox(width: r.width(16)),

                          // Expense info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expense.description,
                                  style: GoogleFonts.poppins(
                                    fontSize: r.fontSize(16),
                                    fontWeight: FontWeight.w600,
                                    color: darkBlue,
                                  ),
                                ),
                                SizedBox(height: r.height(4)),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: r.iconSize(14),
                                      color: Colors.grey[600],
                                    ),
                                    SizedBox(width: r.width(4)),
                                    Text(
                                      _formatDate(expense.expenseDate),
                                      style: GoogleFonts.poppins(
                                        fontSize: r.fontSize(12),
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(width: r.width(12)),
                                    Icon(
                                      Icons.people,
                                      size: r.iconSize(14),
                                      color: Colors.grey[600],
                                    ),
                                    SizedBox(width: r.width(4)),
                                    Text(
                                      '${expense.participants.length + 1}',
                                      style: GoogleFonts.poppins(
                                        fontSize: r.fontSize(12),
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
                              fontSize: r.fontSize(18),
                              fontWeight: FontWeight.w700,
                              color: darkBlue,
                            ),
                          ),
                        ],
                      ),

                      if (expense.payer != null) ...[
                        SizedBox(height: r.height(12)),
                        Container(
                          padding: EdgeInsets.all(r.width(10)),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(r.borderRadius(8)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.account_circle,
                                size: r.iconSize(16),
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: r.width(8)),
                              Expanded(
                                child: Text(
                                  'Paid by ${expense.payer!.email?.split('@')[0] ?? 'User'}',
                                  style: GoogleFonts.poppins(
                                    fontSize: r.fontSize(12),
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '€${(expense.amount / expense.participants.length).toStringAsFixed(2)}/person',
                                style: GoogleFonts.poppins(
                                  fontSize: r.fontSize(11),
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
