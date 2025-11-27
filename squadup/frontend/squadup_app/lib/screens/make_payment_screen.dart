import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/payments_service.dart';
import '../services/storage_service.dart';
import '../widgets/loading_overlay.dart';
import '../models/groups.dart';

class MakePaymentScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final GroupWithMembers? groupDetails;

  const MakePaymentScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    this.groupDetails,
  });

  @override
  State<MakePaymentScreen> createState() => _MakePaymentScreenState();
}

class _MakePaymentScreenState extends State<MakePaymentScreen> {
  final PaymentsService _paymentsService = PaymentsService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String? _selectedUserId;
  String? _currentUserId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final storageService = StorageService();
      final userProfile = await storageService.getUserProfile();
      if (userProfile != null && mounted) {
        setState(() {
          _currentUserId = userProfile['id'];
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  List<GroupMember> _getAvailableMembers() {
    if (widget.groupDetails == null || _currentUserId == null) return [];
    return widget.groupDetails!.members
        .where((member) => member.userId != _currentUserId)
        .toList();
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUserId == null) {
      _showSnackBar('Please select a member to pay', isError: true);
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      await _paymentsService.registerPayment(
        groupId: widget.groupId,
        toUserId: _selectedUserId!,
        amount: amount,
      );

      if (mounted) {
        _showSnackBar('Payment registered successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to register payment: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
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
    final availableMembers = _getAvailableMembers();

    return LoadingOverlay(
      isLoading: _loading,
      message: 'Processing payment...',
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: darkBlue),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Make Payment',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: darkBlue,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryBlue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.group, color: primaryBlue, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.groupName,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: darkBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Select member
                  Text(
                    'Pay to',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: darkBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (availableMembers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        'No members found',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  else
                    Column(
                      children:
                          availableMembers.map((member) {
                            final isSelected = _selectedUserId == member.userId;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedUserId = member.userId;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? primaryBlue.withOpacity(0.1)
                                          : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? primaryBlue
                                            : Colors.grey.withOpacity(0.3),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor:
                                          isSelected
                                              ? primaryBlue
                                              : Colors.grey[300],
                                      backgroundImage:
                                          member.avatarUrl != null
                                              ? NetworkImage(member.avatarUrl!)
                                              : null,
                                      child:
                                          member.avatarUrl == null
                                              ? Text(
                                                (member.name?.isNotEmpty ??
                                                        false)
                                                    ? member.name![0]
                                                        .toUpperCase()
                                                    : member.userId[0]
                                                        .toUpperCase(),
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
                                              isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                          color:
                                              isSelected
                                                  ? primaryBlue
                                                  : darkBlue,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: primaryBlue,
                                        size: 24,
                                      )
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
                    ),

                  const SizedBox(height: 24),

                  // Amount
                  Text(
                    'Amount',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: darkBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      prefixIcon: Icon(Icons.euro, color: primaryBlue),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submitPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Register Payment',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
