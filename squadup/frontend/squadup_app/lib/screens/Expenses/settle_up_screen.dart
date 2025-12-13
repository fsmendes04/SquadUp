import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/settle_up_transaction.dart';
import '../../services/payments_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/header.dart';

class SettleUpScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const SettleUpScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends State<SettleUpScreen> {
  final PaymentsService _paymentsService = PaymentsService();
  List<SettleUpTransaction>? _transactions;
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentUserId;

  static const Color darkBlue = Color.fromARGB(255, 29, 56, 95);
  static const Color primaryBlue = Color.fromARGB(255, 81, 163, 230);

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadSettleUpTransactions();
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
      // Silently fail if unable to load user profile
    }
  }

  Future<void> _loadSettleUpTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transactions = await _paymentsService.getSettleUpTransactions(
        widget.groupId,
      );
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final txCount = _transactions?.length ?? 0;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LoadingOverlay(
          isLoading: _isLoading,
          message: 'Settling up...',
          child: Column(
            children: [
                CustomHeader(
                darkBlue: darkBlue,
                title: 'Settle Up${_transactions != null ? ' ($txCount)' : ''}',
              ),
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadSettleUpTransactions,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_transactions == null || _transactions!.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 0.0),
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
            const SizedBox(height: 70),
            Text(
              "You're all settled up!",
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          ..._transactions!.asMap().entries.map((entry) {
            return _buildTransactionCard(entry.value, entry.key + 1, _currentUserId);
          }).toList(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // _buildHeader removido, pois agora usamos CustomHeader

  Widget _buildTransactionCard(SettleUpTransaction transaction, int step, String? currentUserId) {
    // Determine if current user is involved
    final isUserPayer = currentUserId == transaction.from;
    final isUserReceiver = currentUserId == transaction.to;
    
    // Determine amount color based on user involvement
    Color amountColor;
    if (isUserPayer) {
      amountColor = Colors.red[600]!;
    } else if (isUserReceiver) {
      amountColor = Colors.green[600]!;
    } else {
      amountColor = darkBlue;
    }

    // Determine box colors based on current user
    final fromBoxColor = isUserPayer ? primaryBlue.withValues(alpha: 0.15) : darkBlue.withValues(alpha: 0.1);
    final fromTextColor = isUserPayer ? primaryBlue : darkBlue;
    final toBoxColor = isUserReceiver ? primaryBlue.withValues(alpha: 0.15) : darkBlue.withValues(alpha: 0.1);
    final toTextColor = isUserReceiver ? primaryBlue : darkBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: darkBlue,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$step',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Step $step',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: darkBlue,
                  ),
                ),
              ),
              Text(
                '€${transaction.amount.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: amountColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildUserBox(
                  transaction.fromName,
                  fromBoxColor,
                  fromTextColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: darkBlue,
                  size: 24,
                ),
              ),
              Expanded(
                child: _buildUserBox(
                  transaction.toName,
                  toBoxColor,
                  toTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserBox(
    String name,
    Color backgroundColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

}
