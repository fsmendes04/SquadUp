import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/expenses_service.dart';
import '../../widgets/loading_overlay.dart';
import '../../models/expense.dart';
import '../../widgets/squadup_input.dart';
import '../../widgets/squadup_date_picker.dart';
import '../../widgets/squadup_button.dart';

class UpdateExpenseScreen extends StatefulWidget {
  final Expense expense;

  const UpdateExpenseScreen({super.key, required this.expense});

  @override
  State<UpdateExpenseScreen> createState() => _UpdateExpenseScreenState();
}

class _UpdateExpenseScreenState extends State<UpdateExpenseScreen> {
  final ExpensesService _expensesService = ExpensesService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  late String _selectedCategory;

  bool _loading = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food', 'icon': Icons.restaurant},
    {'name': 'Transport', 'icon': Icons.directions_car},
    {'name': 'Entertainment', 'icon': Icons.movie},
    {'name': 'Shopping', 'icon': Icons.shopping_bag},
    {'name': 'Health', 'icon': Icons.local_hospital},
    {'name': 'Accommodation', 'icon': Icons.home},
    {'name': 'Education', 'icon': Icons.school},
    {'name': 'Other', 'icon': Icons.receipt},
  ];

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.expense.description,
    );
    _amountController = TextEditingController(
      text: widget.expense.amount.toStringAsFixed(2),
    );
    _selectedDate = widget.expense.expenseDate;
    _selectedCategory = widget.expense.category;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 81, 163, 230),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _updateExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final updateDto = UpdateExpenseDto(
        description: _descriptionController.text.trim(),
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        expenseDate: _selectedDate.toIso8601String(),
      );

      await _expensesService.updateExpense(widget.expense.id, updateDto);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Expense updated successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _deleteExpense() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Delete Expense',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            content: Text(
              'Are you sure you want to delete this expense? This action cannot be undone.',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Delete',
                  style: GoogleFonts.poppins(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setState(() {
        _loading = true;
      });

      try {
        await _expensesService.deleteExpense(widget.expense.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Expense deleted successfully!',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate deletion
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.toString().replaceAll('Exception: ', ''),
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      }
    }
  }

  final primaryBlue = const Color.fromARGB(255, 81, 163, 230);
  final darkBlue = const Color.fromARGB(255, 29, 56, 95);

  @override
  Widget build(BuildContext context) {

    return LoadingOverlay(
      isLoading: _loading,
      message: 'Updating expense...',
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

              const SizedBox(height: 20),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildDescriptionField(darkBlue),
                        const SizedBox(height: 20),
                        _buildAmountField(darkBlue),
                        const SizedBox(height: 20),
                        _buildCategorySelector(darkBlue),
                        const SizedBox(height: 30),
                        _buildDatePicker(darkBlue),
                        const SizedBox(height: 40),
                        _buildUpdateButton(primaryBlue),
                        const SizedBox(height: 12),
                        _buildDeleteButton(),
                      ],
                    ),
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
            icon: Icon(Icons.arrow_back_ios, color: darkBlue, size: 31),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Update Expense',
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

  Widget _buildDescriptionField(Color darkBlue) {
    return SquadUpInput(
      controller: _descriptionController,
      label: 'Description',
      icon: Icons.description_outlined,
      keyboardType: TextInputType.text,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a description';
        }
        return null;
      },
    );
  }

  Widget _buildAmountField(Color darkBlue) {
    return SquadUpInput(
      controller: _amountController,
      label: 'Amount',
      icon: Icons.attach_money,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter an amount';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'Please enter a valid amount';
        }
        return null;
      },
    );
  }

  Widget _buildCategorySelector(Color darkBlue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: darkBlue,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = _selectedCategory == category['name'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category['name'] as String;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? const Color(0xFF51A3E6).withValues(alpha: 0.15)
                          : Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isSelected
                            ? const Color(0xFF51A3E6)
                            : Colors.grey.withValues(alpha: 0.3),
                    width: isSelected ? 2.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      color: isSelected ? const Color(0xFF51A3E6) : Colors.grey[600],
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDatePicker(Color darkBlue) {
    return SquadUpDatePicker(
      label: 'Date',
      selectedDate: _selectedDate,
      icon: Icons.calendar_today,
      onDateSelected: _selectDate,
    );
  }

  Widget _buildUpdateButton(Color primaryBlue) {
    return SquadUpButton(
      text: 'Update Expense',
      onPressed: _updateExpense,
      isLoading: _loading,
      width: double.infinity,
      height: 56,
      backgroundColor: darkBlue,
      disabledColor: Colors.grey[300] ?? Colors.grey,
      textColor: Colors.white,
      borderRadius: 16,
    );
  }

  Widget _buildDeleteButton() {
    return SquadUpButton(
      text: 'Delete Expense',
      onPressed: _deleteExpense,
      isLoading: _loading,
      width: double.infinity,
      height: 56,
      backgroundColor: const Color.fromARGB(255, 221, 69, 59),
      disabledColor: Colors.grey[300] ?? Colors.grey,
      textColor: Colors.white,
      borderRadius: 16,
    );
  }

  }

