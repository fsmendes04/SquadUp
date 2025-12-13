import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../widgets/header.dart';
import '../../services/payments_service.dart';
import '../../services/storage_service.dart';
import '../../services/groups_service.dart';
import '../../models/payment.dart';
import '../../models/groups.dart';
import '../../widgets/loading_overlay.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final String? groupId;
  final String? groupName;

  const PaymentHistoryScreen({super.key, this.groupId, this.groupName});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final PaymentsService _paymentsService = PaymentsService();
  final StorageService _storageService = StorageService();
  final GroupsService _groupsService = GroupsService();

  late String groupId;
  late String groupName;

  List<Payment> _payments = [];
  bool _loading = true;
  String? _currentUserId;
  bool _initialized = false;
  GroupWithMembers? _groupDetails;

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });
    await Future.wait([_loadGroupDetails(), _loadPayments()]);
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      groupId = widget.groupId ?? args?['groupId'] ?? '';
      groupName = widget.groupName ?? args?['groupName'] ?? '';
      _loadCurrentUser();
      _loadData();
      _initialized = true;
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userProfile = await _storageService.getUserProfile();
      if (userProfile != null && mounted) {
        setState(() {
          _currentUserId = userProfile['id'];
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  Future<void> _loadGroupDetails() async {
    try {
      final response = await _groupsService.getGroupById(groupId);
      final groupDetails = GroupWithMembers.fromJson(response['data']);
      if (mounted) {
        setState(() {
          _groupDetails = groupDetails;
        });
      }
    } catch (e) {
      debugPrint('Error loading group details: $e');
    }
  }

  String _getUserNameById(String userId) {
    if (_groupDetails == null) return userId;

    final member = _groupDetails!.members.firstWhere(
      (m) => m.userId == userId,
      orElse:
          () => GroupMember(
            id: '',
            groupId: '',
            userId: userId,
            joinedAt: DateTime.now(),
            role: 'member',
          ),
    );

    return member.name ?? userId;
  }

  Future<void> _loadPayments() async {
    try {
      final payments = await _paymentsService.getGroupPayments(groupId);
      if (mounted) {
        setState(() {
          _payments = payments;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error loading payments: $e', isError: true);
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

    return LoadingOverlay(
      isLoading: _loading,
      message: 'Loading payment history...',
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              CustomHeader(
                darkBlue: darkBlue,
                title: 'Payment History',
              ),
              Container(
                child: _payments.isEmpty
                    ? _buildEmptyState(darkBlue)
                    : _buildPaymentsList(primaryBlue, darkBlue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color darkBlue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 130.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 350,
            height: 350,
            child: Center(
              child: Opacity(
                opacity: 0.12,
                child: Image.asset(
                  'lib/images/logo_v3.png',
                  width: 350,
                  height: 350,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            "No payments yet",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList(Color primaryBlue, Color darkBlue) {
    // Group payments by date
    Map<String, List<Payment>> groupedPayments = {};
    for (var payment in _payments) {
      final date = DateTime.parse(payment.paymentDate);
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      if (!groupedPayments.containsKey(dateKey)) {
        groupedPayments[dateKey] = [];
      }
      groupedPayments[dateKey]!.add(payment);
    }

    // Sort dates in descending order
    final sortedDates =
        groupedPayments.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final payments = groupedPayments[dateKey]!;
        final date = DateTime.parse(dateKey);
        final isToday =
            DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateKey;
        final isYesterday =
            DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime.now().subtract(const Duration(days: 1))) ==
            dateKey;

        String dateLabel;
        if (isToday) {
          dateLabel = 'Today';
        } else if (isYesterday) {
          dateLabel = 'Yesterday';
        } else {
          dateLabel = DateFormat('MMMM d, yyyy').format(date);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Text(
                dateLabel,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: darkBlue,
                ),
              ),
            ),
            ...payments.map(
              (payment) => _buildPaymentCard(payment, primaryBlue, darkBlue),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildPaymentCard(Payment payment, Color primaryBlue, Color darkBlue) {
    final isCurrentUserSender = payment.fromUserId == _currentUserId;
    final isCurrentUserReceiver = payment.toUserId == _currentUserId;
    final fromUserName = _getUserNameById(payment.fromUserId);
    final toUserName = _getUserNameById(payment.toUserId);

    Color iconColor;
    if (isCurrentUserSender) {
      iconColor = Colors.red[700]!;
    } else if (isCurrentUserReceiver) {
      iconColor = Colors.green[700]!;
    } else {
      iconColor = darkBlue;
    }

    return Container(
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
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCurrentUserSender
                        ? Icons.arrow_upward_rounded
                        : isCurrentUserReceiver
                        ? Icons.arrow_downward_rounded
                        : Icons.remove,
                    color: Colors.white,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 16),

                // Payment info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: darkBlue,
                          ),
                          children: [
                            const TextSpan(text: 'From '),
                            TextSpan(
                              text: fromUserName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ...existing code...
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: darkBlue,
                          ),
                          children: [
                            const TextSpan(text: 'To '),
                            TextSpan(
                              text: toUserName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount
                Text(
                  '€${payment.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isCurrentUserSender
                        ? Colors.red
                        : isCurrentUserReceiver
                            ? Colors.green
                            : darkBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
