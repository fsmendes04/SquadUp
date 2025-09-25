import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/expenses_service.dart';
import '../models/create_expense_request.dart';
import '../models/group_with_members.dart';

class AddExpenseScreen extends StatefulWidget {
  final GroupWithMembers group;
  final String currentUserId;

  const AddExpenseScreen({
    super.key,
    required this.group,
    required this.currentUserId,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final ExpensesService _expensesService = ExpensesService();

  String? _selectedPayerId;
  String _selectedCategory = 'Alimentação';
  DateTime _selectedDate = DateTime.now();
  List<String> _selectedParticipants = [];
  bool _isLoading = false;

  // Cores seguindo o padrão da GroupHomeScreen
  final darkBlue = const Color.fromARGB(255, 29, 56, 95);
  final primaryBlue = const Color.fromARGB(255, 81, 163, 230);

  // Categorias disponíveis
  final List<String> _categories = [
    'Alimentação',
    'Transporte',
    'Hospedagem',
    'Entretenimento',
    'Compras',
    'Saúde',
    'Educação',
    'Utilitários',
    'Outros',
  ];

  @override
  void initState() {
    super.initState();
    // Define o usuário atual como pagador padrão
    _selectedPayerId = widget.currentUserId;
    // Seleciona todos os membros como participantes por padrão
    _selectedParticipants = widget.group.members.map((m) => m.userId).toList();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _toggleParticipant(String userId) {
    setState(() {
      if (_selectedParticipants.contains(userId)) {
        _selectedParticipants.remove(userId);
      } else {
        _selectedParticipants.add(userId);
      }
    });
  }

  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    if (_selectedPayerId == null) {
      _showSnackBar('Selecione quem pagou a despesa', isError: true);
      return false;
    }

    if (_selectedParticipants.isEmpty) {
      _showSnackBar('Selecione pelo menos um participante', isError: true);
      return false;
    }

    return true;
  }

  Future<void> _createExpense() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final request = CreateExpenseRequest(
        groupId: widget.group.id,
        payerId: _selectedPayerId!,
        amount: double.parse(_amountController.text.replaceAll(',', '.')),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        expenseDate: _selectedDate,
        participantIds: _selectedParticipants,
      );

      await _expensesService.createExpense(request);

      if (mounted) {
        _showSnackBar('Despesa criada com sucesso!');
        Navigator.of(context).pop(true); // Retorna true para indicar sucesso
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erro ao criar despesa';

        // Personalizar mensagem para erro de RLS
        if (e.toString().contains('row-level security policy')) {
          errorMessage =
              'Erro de permissão: Você não tem autorização para criar despesas neste grupo.\n\nSolução: Execute o script SQL "DISABLE_EXPENSES_RLS_TEMP.sql" no Supabase.';
        } else if (e.toString().contains('Bad Request')) {
          errorMessage =
              'Dados inválidos. Verifique se todos os campos estão preenchidos corretamente.';
        } else {
          errorMessage = 'Erro ao criar despesa: ${e.toString()}';
        }

        _showSnackBar(errorMessage, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? Colors.red : primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 8 : 3),
        action:
            isError
                ? SnackBarAction(
                  label: 'Fechar',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                )
                : null,
      ),
    );
  }

  String _getMemberName(String userId) {
    // Usa o userId como nome de exibição (seguindo o padrão da aplicação)
    return userId.split('@')[0]; // Se for email, pega a parte antes do @
  }

  // Top Bar com estilo da GroupHomeScreen
  Widget _buildTopBar() {
    return SizedBox(
      height: kToolbarHeight + 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: darkBlue, size: 34),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 2),
                  // Ícone da despesa
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2ECC71).withOpacity(0.8),
                          const Color(0xFF2ECC71),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF2ECC71).withOpacity(0.7),
                              const Color(0xFF2ECC71),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.add_card,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Título
                  Expanded(
                    child: Text(
                      'Adicionar Despesa',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: darkBlue,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                width: 34,
                height: 34,
                padding: const EdgeInsets.all(8),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                ),
              ),
          ],
        ),
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
            _buildTopBar(),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  children: [
                    const SizedBox(height: 24),
                    // Descrição
                    _buildInputCard(
                      title: 'Descrição',
                      child: TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          hintText: 'Ex: Jantar no restaurante',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: primaryBlue,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe a descrição da despesa';
                          }
                          if (value.trim().length < 3) {
                            return 'Descrição deve ter pelo menos 3 caracteres';
                          }
                          return null;
                        },
                        maxLength: 100,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Valor
                    _buildInputCard(
                      title: 'Valor',
                      child: TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          hintText: '0,00',
                          prefixText: 'R\$ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: primaryBlue,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+[,.]?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o valor da despesa';
                          }
                          final doubleValue = double.tryParse(
                            value.replaceAll(',', '.'),
                          );
                          if (doubleValue == null || doubleValue <= 0) {
                            return 'Informe um valor válido maior que zero';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Categoria
                    _buildInputCard(
                      title: 'Categoria',
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: primaryBlue,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items:
                            _categories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Data
                    _buildInputCard(
                      title: 'Data da Despesa',
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: primaryBlue),
                              const SizedBox(width: 8),
                              Text(
                                '${_selectedDate.day.toString().padLeft(2, '0')}/'
                                '${_selectedDate.month.toString().padLeft(2, '0')}/'
                                '${_selectedDate.year}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: darkBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quem pagou
                    _buildInputCard(
                      title: 'Quem pagou?',
                      child: DropdownButtonFormField<String>(
                        value: _selectedPayerId,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: primaryBlue,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items:
                            widget.group.members.map((member) {
                              return DropdownMenuItem(
                                value: member.userId,
                                child: Text(_getMemberName(member.userId)),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPayerId = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Participantes
                    _buildInputCard(
                      title: 'Participantes',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_selectedParticipants.length} selecionados',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...widget.group.members.map((member) {
                            final isSelected = _selectedParticipants.contains(
                              member.userId,
                            );
                            return Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color:
                                    isSelected
                                        ? primaryBlue.withOpacity(0.1)
                                        : Colors.transparent,
                              ),
                              child: CheckboxListTile(
                                title: Text(
                                  _getMemberName(member.userId),
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    color: darkBlue,
                                  ),
                                ),
                                subtitle:
                                    member.userId == widget.currentUserId
                                        ? Text(
                                          'Você',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: primaryBlue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        )
                                        : null,
                                value: isSelected,
                                onChanged: (bool? value) {
                                  _toggleParticipant(member.userId);
                                },
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                activeColor: primaryBlue,
                                checkColor: Colors.white,
                              ),
                            );
                          }),
                          if (_selectedParticipants.isNotEmpty) ...[
                            const Divider(height: 24),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calculate,
                                    color: primaryBlue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Valor por pessoa: R\$ ${_amountController.text.isNotEmpty ? ((double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0) / _selectedParticipants.length).toStringAsFixed(2) : '0,00'}',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: primaryBlue,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botões
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: primaryBlue, width: 2),
                              foregroundColor: primaryBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              'Cancelar',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _createExpense,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 3,
                              shadowColor: primaryBlue.withOpacity(0.3),
                            ),
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                    : Text(
                                      'Criar Despesa',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para criar cards de input seguindo o padrão da GroupHomeScreen
  Widget _buildInputCard({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: darkBlue,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
