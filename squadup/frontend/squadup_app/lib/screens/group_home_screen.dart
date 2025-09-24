import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/groups_service.dart';
import '../models/group_with_members.dart';
import '../widgets/group_navigation_bar.dart';

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

      final groupDetails = await _groupsService.getGroup(widget.groupId);

      if (mounted) {
        setState(() {
          _groupDetails = groupDetails;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading group details: $e');
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

  Widget _buildGroupHeader() {
    final colors = [
      const Color(0xFF51A3E6),
      const Color(0xFF6C63FF),
      const Color(0xFF2ECC71),
      const Color(0xFFE74C3C),
      const Color(0xFFF39C12),
      const Color(0xFF9B59B6),
    ];

    final groupColor = colors[widget.groupId.hashCode % colors.length];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [groupColor.withOpacity(0.1), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Group Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [groupColor.withOpacity(0.7), groupColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                widget.groupName[0].toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Group Name
          Text(
            widget.groupName,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: darkBlue,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Members Count
          if (_groupDetails != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: groupColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_groupDetails!.memberCount} membro(s)',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: groupColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    if (_groupDetails == null || _groupDetails!.members.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Nenhum membro encontrado',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Membros',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: darkBlue,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _groupDetails!.members.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final member = _groupDetails!.members[index];
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: primaryBlue.withOpacity(0.2),
                      child: Text(
                        member.userId[0].toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.userId,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: darkBlue,
                            ),
                          ),
                          Text(
                            'Membro desde ${_formatDate(member.joinedAt)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            member.role == 'admin'
                                ? Colors.orange.withOpacity(0.2)
                                : Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        member.role == 'admin' ? 'Admin' : 'Membro',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              member.role == 'admin'
                                  ? Colors.orange[700]
                                  : Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} dia(s) atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else {
      return 'Agora mesmo';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: darkBlue),
          onPressed: () => Navigator.pop(context),
        ),

        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: darkBlue),
            onPressed: () {
              // TODO: Implementar menu de opções do grupo
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Opções do grupo em breve!'),
                  backgroundColor: primaryBlue,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
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
              )
              : RefreshIndicator(
                onRefresh: _refreshGroup,
                color: primaryBlue,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildGroupHeader(),
                      _buildMembersList(),
                      const SizedBox(height: 100), // Espaço para navegação
                    ],
                  ),
                ),
              ),
      bottomNavigationBar: CustomCircularNavBar(
        currentIndex: 0, // Chat está ativo por padrão
        onTap: (index) {
          if (index == 0) {
            // Chat - manter na tela atual ou navegar para chat do grupo
            // TODO: Implementar navegação para chat do grupo
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Chat do grupo em breve!'),
                backgroundColor: primaryBlue,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          } else if (index == 1) {
            // Calendar - navegar para calendário do grupo
            // TODO: Implementar navegação para calendário do grupo
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Calendário do grupo em breve!'),
                backgroundColor: primaryBlue,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        },
      ),
    );
  }
}
