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
                      padding: const EdgeInsets.symmetric(horizontal: 14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTopBar(),
                          const SizedBox(height: 25),
                          _buildAvatarsSection(),
                          const SizedBox(height: 24),
                          _buildActivitySection(),
                          const SizedBox(height: 24),
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

  // 1️⃣ Top Bar com título do grupo
  Widget _buildTopBar() {
    return SizedBox(
      height: kToolbarHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: darkBlue, size: 32),
                  onPressed: () => Navigator.pop(context, _groupDetails?.name),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 2),
                // Avatar do grupo
                GroupAvatarDisplay(
                  avatarUrl: _groupDetails?.avatarUrl,
                  radius: 25,
                ),
                const SizedBox(width: 12),
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
            icon: Icon(Icons.more_vert, color: darkBlue, size: 34),
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
        ],
      ),
    );
  }

  Widget _buildAvatarsSection() {
    if (_groupDetails == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Membros (${_groupDetails!.memberCount})',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: darkBlue,
              ),
            ),
            GestureDetector(
              onTap: _addMember,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: darkBlue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_add, color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      'Adicionar',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
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
        const SizedBox(height: 16),
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
                    // Avatar usando UserAvatarDisplay
                    UserAvatarDisplay(avatarUrl: member.avatarUrl, radius: 29),
                    const SizedBox(height: 4),
                    // Nome do usuário
                    SizedBox(
                      width: 60,
                      child: Text(
                        member.name ?? 'Usuário',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: darkBlue,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
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
  Widget _buildActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Atividades Recentes',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: darkBlue,
          ),
        ),
      ],
    );
  }

  // 5️⃣ Seção de Funcionalidades (Cards de Navegação)
  Widget _buildNavigationCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Funcionalidades',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: darkBlue,
          ),
        ),
        const SizedBox(height: 16),
        // Primeira linha - dois cards lado a lado
        Row(
          children: [
            Expanded(
              child: _buildNavigationCard(
                height: 120,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        color: primaryBlue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chat',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: darkBlue,
                      ),
                    ),
                  ],
                ),
                onTap: () => _showFeatureSnackBar('Chat'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNavigationCard(
                height: 120,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.calendar_month_outlined,
                        color: const Color(0xFF6C63FF),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Calendário',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: darkBlue,
                      ),
                    ),
                  ],
                ),
                onTap: () => _showFeatureSnackBar('Calendário'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Segunda linha - card da carteira compartilhada (destaque)
        _buildNavigationCard(
          height: 120,
          child: Row(
            children: [
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        color: const Color(0xFF2ECC71),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Expenses',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: darkBlue,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
            ],
          ),
          onTap: () => _showFeatureSnackBar('Expenses'),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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


  void _addMember() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Adicionar membro em breve!'),
        backgroundColor: primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}