import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/expenses_service.dart';
import '../models/expense.dart';
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

  @override
  Widget build(BuildContext context) {
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
                    _buildExpensesList(darkBlue),
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
                'No expenses yet',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: darkBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start by adding the first expense',
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
            return InkWell(
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
              borderRadius: BorderRadius.circular(16),
              child: Container(
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
