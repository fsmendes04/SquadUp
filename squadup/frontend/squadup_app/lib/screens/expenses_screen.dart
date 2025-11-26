import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/expenses_service.dart';
import '../services/storage_service.dart';
import '../models/expense.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/avatar_group.dart';
import '../widgets/loading_overlay.dart';
import '../services/groups_service.dart';
import '../models/groups.dart';

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

          if (groupedByUser.containsKey(userId)) {
            groupedByUser[userId]!['totalAmount'] += participant.amount;
            groupedByUser[userId]!['expenseCount']++;
          } else {
            groupedByUser[userId] = {
              'userId': userId,
              'userName': _getUserNameById(userId),
              'totalAmount': participant.amount,
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

          if (groupedByUser.containsKey(userId)) {
            groupedByUser[userId]!['totalAmount'] += participant.amount;
            groupedByUser[userId]!['expenseCount']++;
          } else {
            groupedByUser[userId] = {
              'userId': userId,
              'userName': _getUserNameById(userId),
              'totalAmount': participant.amount,
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
                      // Balance Chart
                      _buildBalanceChart(primaryBlue, darkBlue),

                      const SizedBox(height: 24),

                      // Balance tabs and content
                      Container(
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
                                vertical: 8,
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
                            SizedBox(
                              height: _calculateTabViewHeight(),
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  // To Receive Tab - Lista expense_participants onde sou toReceiveId
                                  _buildParticipantsList(
                                    _getParticipantsToReceive(),
                                    darkBlue,
                                    isReceiving: true,
                                  ),
                                  // To Send Tab - Lista expense_participants onde sou toPayId
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

                      const SizedBox(height: 10),

                      // Button outside the tabs box
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 150,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                onPressed: () {
                                  _showSnackBar('Botão pressionado!');
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.settings, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Settle Up',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildHeader(Color darkBlue) {
    return SizedBox(
      height: kToolbarHeight + 10, // espaço extra para avatar maior
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: darkBlue, size: 32),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Center(
                  child: AvatarGroupWidget(
                    groupId: groupId,
                    avatarUrl: _groupDetails?.avatarUrl,
                    radius: 31,
                  ),
                ),
                const SizedBox(width: 14),
                // Nome do grupo
                Expanded(
                  child: Text(
                    _groupDetails?.name ?? groupName,
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
        ],
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

                  final receivePercent =
                      maxValue > 0 ? (toReceive / maxValue * 100).round() : 0;
                  final payPercent =
                      maxValue > 0 ? (toPay / maxValue * 100).round() : 0;

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
                                      child: Container(
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: darkBlue,
                                          borderRadius:
                                              const BorderRadius.horizontal(
                                                left: Radius.circular(8),
                                                right: Radius.circular(8),
                                              ),
                                        ),
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Text(
                                          '€${toPay.toStringAsFixed(2)}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
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
                                      child: Container(
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: primaryBlue,
                                          borderRadius:
                                              const BorderRadius.horizontal(
                                                right: Radius.circular(8),
                                                left: Radius.circular(8),
                                              ),
                                        ),
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: Text(
                                          '€${toReceive.toStringAsFixed(2)}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
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

          const SizedBox(height: 16),
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
          child: Text(
            isReceiving ? "Nobody owes you anything" : "You don't owe anything",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
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

  double _calculateTabViewHeight() {
    final receiveCount = _getParticipantsToReceive().length;
    final payCount = _getParticipantsToPay().length;
    final maxCount = receiveCount > payCount ? receiveCount : payCount;

    if (maxCount == 0) return 100;

    return (maxCount * 70.0) + 16.0;
  }
}
