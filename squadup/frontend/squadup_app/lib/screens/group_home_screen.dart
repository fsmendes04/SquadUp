import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/groups_service.dart';
import '../models/groups.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/header_avatar.dart';
import '../widgets/loading_overlay.dart';
import '../config/responsive_utils.dart';
import 'edit_group_screen.dart';
import 'Polls/polls_screen.dart';
import 'Chat/chat_screen.dart';

class GroupHomeScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupHomeScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupHomeScreen> createState() => _GroupHomeScreenState();
}

class _GroupHomeScreenState extends State<GroupHomeScreen> {
  final _groupsService = GroupsService();
  GroupWithMembers? _groupDetails;
  bool _isLoading = true;
  String? _error;

  final darkBlue = const Color.fromARGB(255, 29, 56, 95);
  final primaryBlue = const Color.fromARGB(255, 81, 163, 230);

  @override
  void initState() {
    super.initState();
    _loadGroupDetails();
  }

  Future<void> _loadGroupDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _groupsService.getGroupById(widget.groupId);
      final groupDetails = GroupWithMembers.fromJson(response['data']);

      // Debug: Verificar avatares dos membros
      debugPrint('=== Group Members Debug ===');
      for (var member in groupDetails.members) {
        debugPrint('Member: ${member.name} - Avatar: ${member.avatarUrl}');
      }

      if (mounted) {
        setState(() {
          _groupDetails = groupDetails;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading group details: $e');
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar detalhes do grupo';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshGroup() async {
    await _loadGroupDetails();
  }

  void _showFeatureSnackBar(String feature) {
    final r = context.responsive;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature em breve!'),
        backgroundColor: primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.borderRadius(12))),
        margin: r.padding(left: 16, top: 16, right: 16, bottom: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Loading group details...',
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child:
              _error != null
                  ? _buildErrorState()
                  : RefreshIndicator(
                    onRefresh: _refreshGroup,
                    color: primaryBlue,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTopBar(),
                          SizedBox(height: r.height(10)),
                          Padding(
                            padding: r.symmetricPadding(horizontal: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildAvatarsSection(),
                                _buildCalendarSection(),
                                SizedBox(height: r.height(24)),
                                _buildActivitySection(),
                                _buildNavigationCards(),
                                SizedBox(height: r.height(32)),
                              ],
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

  Widget _buildTopBar() {
    final r = context.responsive;
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        HeaderAvatar(
          darkBlue: darkBlue,
          title: _groupDetails?.name ?? '',
          groupId: widget.groupId,
          avatarUrl: _groupDetails?.avatarUrl,
          onBack: () => Navigator.pop(context, _groupDetails?.name),
        ),
        Positioned(
          right: r.width(20),
          child: IconButton(
            icon: Icon(Icons.edit, color: darkBlue, size: r.iconSize(32)),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditGroupScreen(groupId: widget.groupId),
                ),
              );
              if (result == true) {
                await _loadGroupDetails();
              }
            },
            tooltip: 'Opções do grupo',
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarsSection() {
    if (_groupDetails == null) return const SizedBox.shrink();
    final r = context.responsive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: r.height(4)),
        SizedBox(
          height: r.height(90),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _groupDetails!.members.length,
            itemBuilder: (context, index) {
              final member = _groupDetails!.members[index];
              return Padding(
                padding: r.padding(right: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar usando AvatarWidget (sem edição, radius menor)
                    AvatarWidget(
                      radius: r.width(28),
                      allowEdit: false,
                      avatarUrl: member.avatarUrl, // Avatar vem do backend
                      key: ValueKey(
                        '${member.userId}_${member.avatarUrl ?? 'no-avatar'}',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 4️⃣ Seção de Atividade Recente
  int? _selectedActivityIndex;

  Widget _buildActivitySection() {
    final r = context.responsive;
    final activities = [
      {
        'icon': Icons.payment,
        'title': 'Despesa',
        'description': 'João pagou €45.00',
      },
      {
        'icon': Icons.credit_card,
        'title': 'Foto',
        'description': 'Ana adicionou uma nova foto',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, color: darkBlue, size: r.iconSize(28)),
            SizedBox(width: r.width(8)),
            Text(
              'Activity',
              style: GoogleFonts.poppins(
                fontSize: r.fontSize(20),
                fontWeight: FontWeight.w600,
                color: darkBlue,
              ),
            ),
          ],
        ),
        SizedBox(height: r.height(16)),
        SizedBox(
          height: r.height(90),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              final isSelected = _selectedActivityIndex == index;

              return Padding(
                padding: EdgeInsets.only(
                  right: index == activities.length - 1 ? 0 : r.width(12),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? r.width(220) : r.width(70),
                  height: r.height(70),
                  decoration: BoxDecoration(
                    color: darkBlue,
                    borderRadius: BorderRadius.circular(r.borderRadius(14)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedActivityIndex = isSelected ? null : index;
                        });
                      },
                      borderRadius: BorderRadius.circular(r.borderRadius(14)),
                      child: Padding(
                        padding: r.padding(left: 12, top: 12, right: 12, bottom: 12),
                        child:
                            isSelected
                                ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          activity['icon'] as IconData,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            activity['title'] as String,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Flexible(
                                      child: Text(
                                        activity['description'] as String,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )
                                : Center(
                                  child: Icon(
                                    activity['icon'] as IconData,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Seção do Calendário
  Widget _buildCalendarSection() {
    final r = context.responsive;
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    final daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;
    final firstDayOfMonth = DateTime(currentYear, currentMonth, 1);
    final startingWeekday = firstDayOfMonth.weekday % 7;

    final eventDays = [5, 6, 11, 28];
    final weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: primaryBlue.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(r.borderRadius(20)),
          ),
          padding: r.padding(left: 20, top: 20, right: 20, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${now.day}',
                        style: GoogleFonts.poppins(
                          fontSize: r.fontSize(56),
                          fontWeight: FontWeight.w700,
                          color: darkBlue,
                          height: 1,
                        ),
                      ),
                      Text(
                        _getWeekdayName(now.weekday).toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: r.fontSize(16),
                          fontWeight: FontWeight.w700,
                          color: darkBlue,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        '${_getMonthName(currentMonth).toUpperCase()} $currentYear',
                        style: GoogleFonts.poppins(
                          fontSize: r.fontSize(14),
                          fontWeight: FontWeight.w500,
                          color: darkBlue,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  // Mini calendário no canto superior direito
                  Container(
                    padding: r.padding(left: 12, top: 12, right: 12, bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(r.borderRadius(12)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Dias da semana
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children:
                              weekDays.map((day) {
                                return Container(
                                  width: r.width(20),
                                  margin: r.symmetricPadding(
                                    horizontal: 2,
                                  ),
                                  child: Center(
                                    child: Text(
                                      day,
                                      style: GoogleFonts.poppins(
                                        fontSize: r.fontSize(11),
                                        fontWeight: FontWeight.w700,
                                        color: darkBlue,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                        SizedBox(height: r.height(6)),
                        // Grid de dias
                        SizedBox(
                          width: r.width(168), // 7 dias * 24 width
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  mainAxisSpacing: r.height(4),
                                  crossAxisSpacing: r.width(4),
                                  childAspectRatio: 1,
                                ),
                            itemCount: daysInMonth + startingWeekday,
                            itemBuilder: (context, index) {
                              if (index < startingWeekday) {
                                return const SizedBox();
                              }

                              final day = index - startingWeekday + 1;
                              final hasEvent = eventDays.contains(day);
                              final isToday = day == now.day;

                              return GestureDetector(
                                onTap:
                                    () => _showFeatureSnackBar(
                                      'Detalhes do dia $day',
                                    ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        hasEvent
                                            ? darkBlue
                                            : isToday
                                            ? primaryBlue
                                            : const Color.fromARGB(
                                              0,
                                              238,
                                              29,
                                              29,
                                            ),
                                    borderRadius: BorderRadius.circular(r.borderRadius(6)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$day',
                                      style: GoogleFonts.poppins(
                                        fontSize: r.fontSize(10),
                                        fontWeight: FontWeight.w700,
                                        color:
                                            hasEvent || isToday
                                                ? Colors.white
                                                : darkBlue,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  String _getWeekdayName(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[weekday - 1];
  }

  Widget _buildNavigationCards() {
    final r = context.responsive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: r.height(24)),
        Text(
          'Ações Rápidas',
          style: GoogleFonts.poppins(
            fontSize: r.fontSize(20),
            fontWeight: FontWeight.w600,
            color: darkBlue,
          ),
        ),
        SizedBox(height: r.height(16)),
        // Grid 2x2 de botões
        Row(
          children: [
            Expanded(
              child: _buildNavigationCard(
                height: r.height(140),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: r.iconSize(32),
                    ),
                    SizedBox(height: r.height(10)),
                    Text(
                      'Chat',
                      style: GoogleFonts.poppins(
                        fontSize: r.fontSize(15),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatPage(),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: r.width(12)),
            Expanded(
              child: _buildNavigationCard(
                height: r.height(140),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: r.iconSize(32),
                    ),
                    SizedBox(height: r.height(10)),
                    Text(
                      'Expenses',
                      style: GoogleFonts.poppins(
                        fontSize: r.fontSize(15),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                onTap: () async {
                  await Navigator.pushNamed(
                    context,
                    '/expenses',
                    arguments: {
                      'groupId': widget.groupId,
                      'groupName': widget.groupName,
                    },
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: r.height(12)),
        Row(
          children: [
            Expanded(
              child: _buildNavigationCard(
                height: r.height(140),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.poll_outlined, color: Colors.white, size: r.iconSize(32)),
                    SizedBox(height: r.height(10)),
                    Text(
                      'Enquetes',
                      style: GoogleFonts.poppins(
                        fontSize: r.fontSize(15),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PollsScreen(
                        groupId: widget.groupId,
                        groupName: _groupDetails?.name ?? widget.groupName,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: r.width(12)),
            Expanded(
              child: _buildNavigationCard(
                height: r.height(140),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: r.iconSize(32),
                    ),
                    SizedBox(height: r.height(10)),
                    Text(
                      'Gallery',
                      style: GoogleFonts.poppins(
                        fontSize: r.fontSize(15),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                onTap: () async {
                  await Navigator.pushNamed(
                    context,
                    '/group-gallery',
                    arguments: {
                      'groupId': widget.groupId,
                      'groupName': _groupDetails?.name ?? widget.groupName,
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationCard({
    required double height,
    required Widget child,
    required VoidCallback onTap,
  }) {
    final r = context.responsive;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: darkBlue,
        borderRadius: BorderRadius.circular(r.borderRadius(16)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(r.borderRadius(16)),
          child: Padding(padding: r.padding(left: 16, top: 16, right: 16, bottom: 16), child: child),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final r = context.responsive;
    return Padding(
      padding: r.symmetricPadding(horizontal: 14),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: r.iconSize(48), color: Colors.grey[400]),
            SizedBox(height: r.height(16)),
            Text(
              _error!,
              style: GoogleFonts.poppins(fontSize: r.fontSize(16), color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: r.height(16)),
            ElevatedButton(
              onPressed: _refreshGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(r.borderRadius(12)),
                ),
              ),
              child: Text(
                'Tentar novamente',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
