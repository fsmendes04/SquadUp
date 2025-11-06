import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/groups_service.dart';
import '../models/groups.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/avatar_group.dart';
import 'edit_group_screen.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature em breve!'),
        backgroundColor: primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _buildErrorState()
                : RefreshIndicator(
                  onRefresh: _refreshGroup,
                  color: primaryBlue,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14.0,
                        vertical: 20.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTopBar(),
                          const SizedBox(height: 25),
                          _buildAvatarsSection(),
                          _buildActivitySection(),
                          _buildCalendarSection(),
                          _buildNavigationCards(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SizedBox(
      height: kToolbarHeight + 16, // espaço extra para avatar maior
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: darkBlue, size: 32),
                  onPressed: () => Navigator.pop(context, _groupDetails?.name),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Center(
                  child: AvatarGroupWidget(
                    groupId: widget.groupId,
                    avatarUrl: _groupDetails?.avatarUrl,
                    radius: 33,
                  ),
                ),
                const SizedBox(width: 14),
                // Nome do grupo
                Expanded(
                  child: Text(
                    _groupDetails?.name ?? '',
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
          IconButton(
            icon: Icon(Icons.edit, color: darkBlue, size: 32),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => EditGroupScreen(groupId: widget.groupId),
                ),
              );
              if (result == true) {
                await _loadGroupDetails();
              }
            },
            tooltip: 'Opções do grupo',
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarsSection() {
    if (_groupDetails == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _groupDetails!.members.length,
            itemBuilder: (context, index) {
              final member = _groupDetails!.members[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar usando AvatarWidget (sem edição, radius menor)
                    AvatarWidget(
                      radius: 30,
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
    final activities = [
      {
        'icon': Icons.payment,
        'title': 'Despesa',
        'description': 'João pagou €45.00',
        'time': '2h atrás',
      },
      {
        'icon': Icons.credit_card,
        'title': 'Foto',
        'description': 'Ana adicionou uma nova foto',
        'time': 'Há 2 dias',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, color: darkBlue, size: 28),
            const SizedBox(width: 8),
            Text(
              'Activity',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: darkBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              final isSelected = _selectedActivityIndex == index;

              return Padding(
                padding: EdgeInsets.only(
                  right: index == activities.length - 1 ? 0 : 12,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 220 : 100,
                  decoration: BoxDecoration(
                    color: darkBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedActivityIndex = isSelected ? null : index;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child:
                            isSelected
                                ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Icon(
                                          activity['icon'] as IconData,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                        // Só mostra o time se expandido
                                        Text(
                                          activity['time'] as String,
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      activity['title'] as String,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    // Só mostra a description se expandido
                                    Text(
                                      activity['description'] as String,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                )
                                : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      activity['icon'] as IconData,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      activity['title'] as String,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    // Não mostra time nem description aqui
                                  ],
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
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: primaryBlue.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dia e data grande no canto superior esquerdo
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
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          color: darkBlue,
                          height: 1,
                        ),
                      ),
                      Text(
                        _getWeekdayName(now.weekday).toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: darkBlue,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        '${_getMonthName(currentMonth).toUpperCase()} $currentYear',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: darkBlue,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  // Mini calendário no canto superior direito
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
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
                                  width: 20,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: Center(
                                    child: Text(
                                      day,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: darkBlue,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 6),
                        // Grid de dias
                        SizedBox(
                          width: 168, // 7 dias * 24 width
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  mainAxisSpacing: 4,
                                  crossAxisSpacing: 4,
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
                                            ? Colors.white.withOpacity(0.2)
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$day',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Ações Rápidas',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: darkBlue,
          ),
        ),
        const SizedBox(height: 16),
        // Grid 2x2 de botões
        Row(
          children: [
            Expanded(
              child: _buildNavigationCard(
                height: 140,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Chat',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                onTap: () => _showFeatureSnackBar('Chat'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNavigationCard(
                height: 140,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Despesas',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                onTap: () => _showFeatureSnackBar('Despesas'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildNavigationCard(
                height: 140,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.poll_outlined, color: Colors.white, size: 32),
                    const SizedBox(height: 10),
                    Text(
                      'Enquetes',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                onTap: () => _showFeatureSnackBar('Enquetes'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNavigationCard(
                height: 140,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Galeria',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                onTap: () => _showFeatureSnackBar('Galeria'),
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
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: darkBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
