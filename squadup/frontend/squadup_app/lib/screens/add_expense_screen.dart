import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/expenses_service.dart';
import '../services/groups_service.dart';
import '../services/user_service.dart';
import '../models/expense.dart';
import '../models/groups.dart';

class AddExpenseScreen extends StatefulWidget {
  final String? groupId;
  final String? groupName;

  const AddExpenseScreen({super.key, this.groupId, this.groupName});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final ExpensesService _expensesService = ExpensesService();
  final GroupsService _groupsService = GroupsService();
  final UserService _userService = UserService();

  bool _isLoading = false;
  bool _isLoadingMembers = true;
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Alimentação';
  String? _selectedPayerId;
  List<String> _selectedParticipantIds = [];
  List<GroupMember> _groupMembers = [];

  late String groupId;
  late String? groupName;

  final Color darkBlue = const Color(0xFF1D385F);
  final Color primaryBlue = const Color(0xFF51A3E6);

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Alimentação', 'icon': Icons.restaurant, 'color': Colors.orange},
    {'name': 'Transporte', 'icon': Icons.directions_car, 'color': Colors.blue},
    {'name': 'Entretenimento', 'icon': Icons.movie, 'color': Colors.purple},
    {'name': 'Compras', 'icon': Icons.shopping_bag, 'color': Colors.green},
    {'name': 'Saúde', 'icon': Icons.local_hospital, 'color': Colors.red},
    {'name': 'Hospedagem', 'icon': Icons.home, 'color': Colors.brown},
    {'name': 'Educação', 'icon': Icons.school, 'color': Colors.indigo},
    {'name': 'Outros', 'icon': Icons.receipt, 'color': Colors.grey},
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    groupId = widget.groupId ?? args?['groupId'] ?? '';
    groupName = widget.groupName ?? args?['groupName'];
    _loadGroupMembers();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupMembers() async {
    setState(() {
      _isLoadingMembers = true;
    });

    try {
      // Get current user profile to get their actual ID
      final userProfile = await _userService.getProfile();
      final currentUserId = userProfile['data']?['id'] as String?;

      final response = await _groupsService.getGroupById(groupId);
      if (response['success'] == true && response['data'] != null) {
        final groupData = GroupWithMembers.fromJson(
          response['data'] as Map<String, dynamic>,
        );

        setState(() {
          _groupMembers = groupData.members;
          _isLoadingMembers = false;

          // Set current user as default payer if they're in the group
          if (currentUserId != null) {
            _selectedPayerId = currentUserId;
          } else if (_groupMembers.isNotEmpty) {
            _selectedPayerId = _groupMembers.first.userId;
          }

          // Select all members by default
          _selectedParticipantIds = _groupMembers.map((m) => m.userId).toList();
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMembers = false;
      });
      _showSnackBar('Erro ao carregar membros: $e', isError: true);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              onSurface: darkBlue,
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

  Future<void> _createExpense() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPayerId == null) {
      _showSnackBar('Por favor selecione quem pagou', isError: true);
      return;
    }

    if (_selectedParticipantIds.isEmpty) {
      _showSnackBar(
        'Por favor selecione pelo menos um participante',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text.trim());

      final createExpenseDto = CreateExpenseDto(
        groupId: groupId,
        payerId: _selectedPayerId!,
        amount: amount,
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        expenseDate: _selectedDate.toIso8601String(),
        participantIds: _selectedParticipantIds,
      );

      await _expensesService.createExpense(createExpenseDto);

      if (mounted) {
        _showSnackBar('Despesa criada com sucesso!', isError: false);
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Erro ao criar despesa: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Content
            Expanded(
              child:
                  _isLoadingMembers
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: primaryBlue),
                            const SizedBox(height: 16),
                            Text(
                              'Carregando...',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                      : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Detalhes da Despesa'),
                              const SizedBox(height: 16),
                              _buildDescriptionField(),
                              const SizedBox(height: 20),
                              _buildAmountField(),
                              const SizedBox(height: 20),
                              _buildDateSelector(),
                              const SizedBox(height: 28),
                              _buildSectionTitle('Categoria'),
                              const SizedBox(height: 16),
                              _buildCategorySelector(),
                              const SizedBox(height: 28),
                              _buildSectionTitle('Quem Pagou?'),
                              const SizedBox(height: 16),
                              _buildPayerSelector(),
                              const SizedBox(height: 28),
                              _buildSectionTitle('Dividir Com'),
                              const SizedBox(height: 16),
                              _buildParticipantsSelector(),
                              const SizedBox(height: 32),
                              _buildCreateButton(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      height: kToolbarHeight,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios, color: darkBlue, size: 28),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Nova Despesa',
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: darkBlue,
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Por favor insira uma descrição';
        }
        if (value.trim().length < 3) {
          return 'A descrição deve ter pelo menos 3 caracteres';
        }
        return null;
      },
      maxLength: 100,
      decoration: InputDecoration(
        hintText: 'Ex: Jantar no restaurante',
        hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(Icons.description_outlined, color: darkBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        counterText: '',
      ),
      style: GoogleFonts.poppins(fontSize: 14, color: darkBlue),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Por favor insira um valor';
        }
        final amount = double.tryParse(value.trim());
        if (amount == null) {
          return 'Valor inválido';
        }
        if (amount <= 0) {
          return 'O valor deve ser maior que zero';
        }
        if (amount > 999999.99) {
          return 'O valor não pode exceder 999999.99';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: '0.00',
        hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(Icons.euro, color: darkBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: darkBlue,
      ),
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: darkBlue, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data da Despesa',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_selectedDate.day.toString().padLeft(2, '0')}/'
                    '${_selectedDate.month.toString().padLeft(2, '0')}/'
                    '${_selectedDate.year}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: darkBlue,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: darkBlue, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children:
          _categories.map((category) {
            final isSelected = _selectedCategory == category['name'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category['name'] as String;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? (category['color'] as Color).withValues(alpha: 0.15)
                          : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isSelected
                            ? category['color'] as Color
                            : Colors.grey.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      color:
                          isSelected
                              ? category['color'] as Color
                              : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category['name'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color:
                            isSelected
                                ? category['color'] as Color
                                : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildPayerSelector() {
    if (_groupMembers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Text(
          'Nenhum membro encontrado',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
        ),
      );
    }

    return Column(
      children:
          _groupMembers.map((member) {
            final isSelected = _selectedPayerId == member.userId;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPayerId = member.userId;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? primaryBlue.withValues(alpha: 0.1)
                          : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isSelected
                            ? primaryBlue
                            : Colors.grey.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          isSelected ? primaryBlue : Colors.grey[300],
                      backgroundImage:
                          member.avatarUrl != null
                              ? NetworkImage(member.avatarUrl!)
                              : null,
                      child:
                          member.avatarUrl == null
                              ? Text(
                                (member.name?.isNotEmpty ?? false)
                                    ? member.name![0].toUpperCase()
                                    : member.userId[0].toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              )
                              : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        member.name ?? member.userId,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? primaryBlue : darkBlue,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: primaryBlue, size: 24)
                    else
                      Icon(
                        Icons.radio_button_unchecked,
                        color: Colors.grey[400],
                        size: 24,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildParticipantsSelector() {
    if (_groupMembers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Text(
          'Nenhum membro encontrado',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
        ),
      );
    }

    return Column(
      children: [
        // Select All / Deselect All
        GestureDetector(
          onTap: () {
            setState(() {
              if (_selectedParticipantIds.length == _groupMembers.length) {
                _selectedParticipantIds.clear();
              } else {
                _selectedParticipantIds =
                    _groupMembers.map((m) => m.userId).toList();
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primaryBlue.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.group, color: primaryBlue, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedParticipantIds.length == _groupMembers.length
                        ? 'Desmarcar Todos'
                        : 'Selecionar Todos',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryBlue,
                    ),
                  ),
                ),
                Icon(
                  _selectedParticipantIds.length == _groupMembers.length
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  color: primaryBlue,
                  size: 24,
                ),
              ],
            ),
          ),
        ),

        // Individual members
        ..._groupMembers.map((member) {
          final isSelected = _selectedParticipantIds.contains(member.userId);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedParticipantIds.remove(member.userId);
                } else {
                  _selectedParticipantIds.add(member.userId);
                }
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? primaryBlue.withValues(alpha: 0.1)
                        : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isSelected
                          ? primaryBlue
                          : Colors.grey.withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        isSelected ? primaryBlue : Colors.grey[300],
                    backgroundImage:
                        member.avatarUrl != null
                            ? NetworkImage(member.avatarUrl!)
                            : null,
                    child:
                        member.avatarUrl == null
                            ? Text(
                              (member.name?.isNotEmpty ?? false)
                                  ? member.name![0].toUpperCase()
                                  : member.userId[0].toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            )
                            : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      member.name ?? member.userId,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? primaryBlue : darkBlue,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_box, color: primaryBlue, size: 24)
                  else
                    Icon(
                      Icons.check_box_outline_blank,
                      color: Colors.grey[400],
                      size: 24,
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createExpense,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          disabledBackgroundColor: primaryBlue.withValues(alpha: 0.5),
        ),
        child:
            _isLoading
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : Text(
                  'Add expense',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
      ),
    );
  }
}
