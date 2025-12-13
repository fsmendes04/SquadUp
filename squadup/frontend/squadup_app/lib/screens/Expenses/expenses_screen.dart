import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/expenses_service.dart';
import '../../services/storage_service.dart';
import '../../models/expense.dart';
import '../../widgets/navigation_bar.dart';
import '../../widgets/header_avatar.dart';
import '../../widgets/loading_overlay.dart';
import '../../services/groups_service.dart';
import '../../models/groups.dart';
import 'settle_up_screen.dart';
import '../../widgets/squadup_button.dart';

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
  final _groupsService = GroupsService();

  late String groupId;
  late String groupName;
  late TabController _tabController;

  List<Expense> _expenses = [];
  bool _loading = true;
  List<Map<String, dynamic>> _userBalances = [];
  bool _initialized = false;
  String? _currentUserName;
  String? _currentUserId;
  GroupWithMembers? _groupDetails;

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
      _loadGroupDetails();
      _initialized = true;
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
          _currentUserId = userProfile['id'];
        });
      }
    } catch (e) {
      // Silently fail if unable to load user profile
    }
  }

  List<Map<String, dynamic>> _getParticipantsToReceive() {
    if (_currentUserId == null) return [];

    Map<String, Map<String, dynamic>> groupedByUser = {};

    for (var expense in _expenses) {
      for (var participant in expense.participants) {
        if (participant.toReceiveId == _currentUserId) {
          final userId = participant.toPayId;
          final remainingAmount = participant.remainingAmount;

          if (groupedByUser.containsKey(userId)) {
            groupedByUser[userId]!['totalAmount'] += remainingAmount;
            groupedByUser[userId]!['expenseCount']++;
          } else {
            groupedByUser[userId] = {
              'userId': userId,
              'userName': _getUserNameById(userId),
              'totalAmount': remainingAmount,
              'expenseCount': 1,
            };
          }
        }
      }
    }

    return groupedByUser.values.toList();
  }

  List<Map<String, dynamic>> _getParticipantsToPay() {
    if (_currentUserId == null) return [];

    Map<String, Map<String, dynamic>> groupedByUser = {};

    for (var expense in _expenses) {
      for (var participant in expense.participants) {
        if (participant.toPayId == _currentUserId) {
          final userId = participant.toReceiveId;
          final remainingAmount = participant.remainingAmount;

          if (groupedByUser.containsKey(userId)) {
            groupedByUser[userId]!['totalAmount'] += remainingAmount;
            groupedByUser[userId]!['expenseCount']++;
          } else {
            groupedByUser[userId] = {
              'userId': userId,
              'userName': _getUserNameById(userId),
              'totalAmount': remainingAmount,
              'expenseCount': 1,
            };
          }
        }
      }
    }

    return groupedByUser.values.toList();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _loading = true;
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

    return LoadingOverlay(
      isLoading: _loading,
      message: 'Loading expenses...',
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              HeaderAvatar(
                darkBlue: darkBlue,
                title: _groupDetails?.name ?? groupName,
                groupId: groupId,
                avatarUrl: _groupDetails?.avatarUrl,
              ),
              const SizedBox(height: 6),
              // Make entire content scrollable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBalanceChart(primaryBlue, darkBlue),
                      const SizedBox(height: 18),
                      // Balance tabs with fixed height
                      Container(
                        height: 400, // Fixed height for transactions
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
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: StatefulBuilder(
                                builder: (context, setState) {
                                  return TabBar(
                                    controller: _tabController,
                                    dividerColor: Colors.transparent,
                                    indicator: BoxDecoration(
                                      color: Colors.transparent,
                                    ),
                                    indicatorSize: TabBarIndicatorSize.tab,
                                    labelColor: Colors.white,
                                    unselectedLabelColor: darkBlue,
                                    labelStyle: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    unselectedLabelStyle: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    tabs: [
                                      Tab(
                                        child: AnimatedBuilder(
                                          animation: _tabController,
                                          builder: (context, child) {
                                            final selected =
                                                _tabController.index == 0;
                                            return Container(
                                              decoration: BoxDecoration(
                                                color:
                                                    selected
                                                        ? primaryBlue
                                                        : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                'To Receive',
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color:
                                                      selected
                                                          ? Colors.white
                                                          : darkBlue,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      Tab(
                                        child: AnimatedBuilder(
                                          animation: _tabController,
                                          builder: (context, child) {
                                            final selected =
                                                _tabController.index == 1;
                                            return Container(
                                              decoration: BoxDecoration(
                                                color:
                                                    selected
                                                        ? darkBlue
                                                        : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                'To Send',
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color:
                                                      selected
                                                          ? Colors.white
                                                          : darkBlue,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  // To Receive Tab
                                  _buildParticipantsList(
                                    _getParticipantsToReceive(),
                                    darkBlue,
                                    isReceiving: true,
                                  ),
                                  // To Send Tab
                                  _buildParticipantsList(
                                    _getParticipantsToPay(),
                                    darkBlue,
                                    isReceiving: false,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 150,
                            child: SquadUpButton(
                              text: 'Settle Up',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SettleUpScreen(
                                      groupId: groupId,
                                      groupName: groupName,
                                    ),
                                  ),
                                );
                              },
                              width: 150,
                              height: 50,
                              backgroundColor: primaryBlue,
                              disabledColor: primaryBlue.withAlpha(128),
                              textColor: Colors.white,
                              borderRadius: 12,
                            ),
                          ),
                          SizedBox(width: 30),
                          SizedBox(
                            width: 150,
                            child: SquadUpButton(
                              text: 'Payment',
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/make-payment',
                                  arguments: {
                                    'groupId': groupId,
                                    'groupName': groupName,
                                    'groupDetails': _groupDetails,
                                  },
                                ).then((result) {
                                  if (result == true) {
                                    _loadExpenses();
                                  }
                                });
                              },
                              width: 150,
                              height: 50,
                              backgroundColor: darkBlue,
                              disabledColor: darkBlue.withAlpha(128),
                              textColor: Colors.white,
                              borderRadius: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: CustomCircularNavBar(
          currentIndex: 2,
          icons: [Icons.add_card, Icons.history],
          outlinedIcons: [Icons.add_card_outlined, Icons.history_outlined],
          backgroundColor: darkBlue,
          iconColor: Colors.white,
          onTap: (index) {
            if (index == 0) {
              _navigateToCreateExpense();
            } else if (index == 1) {
              Navigator.pushNamed(
                context,
                '/expense-history',
                arguments: {'groupId': groupId, 'groupName': groupName},
              );
            }
          },
        ),
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
            color: Colors.grey.withValues(alpha: 0.1),
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
                'Group Balance',
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

                  var receivePercent =
                      maxValue > 0 ? (toReceive / maxValue * 100).round() : 0;
                  var payPercent =
                      maxValue > 0 ? (toPay / maxValue * 100).round() : 0;

                  const minPercent = 35;
                  if (toPay > 0 && payPercent < minPercent) {
                    payPercent = minPercent;
                  }
                  if (toReceive > 0 && receivePercent < minPercent) {
                    receivePercent = minPercent;
                  }

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
                        if (toPay == 0 && toReceive == 0)
                          Center(
                            child: Text(
                              '€0',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: darkBlue,
                              ),
                            ),
                          )
                        else
                          Row(
                            children: [
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
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            return Container(
                                              height: 32,
                                              constraints: BoxConstraints(
                                                minWidth: _calculateMinBarWidth(
                                                  toPay,
                                                ),
                                              ),
                                              decoration: BoxDecoration(
                                                color: darkBlue,
                                                borderRadius:
                                                    const BorderRadius
                                                        .horizontal(
                                                      left:
                                                          Radius.circular(8),
                                                      right: Radius.circular(8),
                                                    ),
                                              ),
                                              alignment: Alignment.centerLeft,
                                              padding: const EdgeInsets.only(
                                                left: 8,
                                                right: 8,
                                              ),
                                              child: Text(
                                                '€${toPay.toStringAsFixed(2)}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.visible,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              Expanded(
                                child: Row(
                                  children: [
                                    // Bar
                                    if (toReceive > 0)
                                      Expanded(
                                        flex: receivePercent,
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            return Container(
                                              height: 32,
                                              constraints: BoxConstraints(
                                                minWidth: _calculateMinBarWidth(
                                                  toReceive,
                                                ),
                                              ),
                                              decoration: BoxDecoration(
                                                color: primaryBlue,
                                                borderRadius:
                                                    const BorderRadius
                                                        .horizontal(
                                                      right:
                                                          Radius.circular(8),
                                                      left: Radius.circular(8),
                                                    ),
                                              ),
                                              alignment: Alignment.centerRight,
                                              padding: const EdgeInsets.only(
                                                left: 8,
                                                right: 8,
                                              ),
                                              child: Text(
                                                '€${toReceive.toStringAsFixed(2)}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.visible,
                                              ),
                                            );
                                          },
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

          const SizedBox(height: 20),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'To Receive',
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
                  color: darkBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'To Send',
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

  Widget _buildParticipantsList(
    List<Map<String, dynamic>> participants,
    Color darkBlue, {
    required bool isReceiving,
  }) {
    final primaryBlue = const Color.fromARGB(255, 81, 163, 230);

    if (_loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: CircularProgressIndicator(color: primaryBlue),
        ),
      );
    }

    if (participants.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: 0.12,
                child: Image.asset(
                  'lib/images/logo_v3.png',
                  height: 120,
                  width: 120,
                ),
              ),
              const SizedBox(height: 30),
              Flexible(
                child: Text(
                  isReceiving ? "Nobody owes you anything" : "You don't owe anything",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: participants.length,
      itemBuilder: (context, index) {
        final item = participants[index];
        final userName = item['userName'] as String;
        final totalAmount = item['totalAmount'] as double;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // User icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isReceiving ? primaryBlue : darkBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isReceiving)
                      Text(
                        'You owe',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    Text(
                      userName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isReceiving ? primaryBlue : darkBlue,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (isReceiving)
                      Text(
                        'Owes you',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              // Amount
              Text(
                '€${totalAmount.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isReceiving ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getUserNameById(String userId) {
    try {
      final user = _userBalances.firstWhere(
        (balance) => balance['userId'] == userId,
        orElse: () => {'name': 'User'},
      );
      return user['name'] as String? ?? 'User';
    } catch (e) {
      return 'User';
    }
  }

  double _calculateMinBarWidth(double amount) {
    final text = '€${amount.toStringAsFixed(2)}';
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return textPainter.width;
  }
}
