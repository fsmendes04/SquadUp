import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/groups_service.dart';
import '../models/group_with_members.dart';

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
      appBar: _buildAppBar(),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                onRefresh: _refreshGroup,
                color: primaryBlue,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
    );
  }

  // 1️⃣ Cabeçalho (AppBar)
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: darkBlue, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.groupName,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkBlue,
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert, color: darkBlue),
          onPressed: _showGroupOptions,
        ),
      ],
    );
  }

  // 2️⃣ Seção de Avatares dos Membros
  Widget _buildAvatarsSection() {
    if (_groupDetails == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Avatares dos membros
          Expanded(
            child: SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _groupDetails!.members.length,
                itemBuilder: (context, index) {
                  final member = _groupDetails!.members[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: primaryBlue.withOpacity(0.1),
                      child: Text(
                        member.userId[0].toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryBlue,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Botão adicionar membro
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey[300]!,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: IconButton(
              onPressed: _addMember,
              icon: Icon(Icons.add, color: Colors.grey[600], size: 24),
            ),
          ),
        ],
      ),
    );
  }

  // 3️⃣ Seção de Atividade Recente
  Widget _buildActivitySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActivityItem(
            'Dívidas em andamento',
            onTap: () => _showFeatureSnackBar('Dívidas'),
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            'Mensagens novas',
            onTap: () => _showFeatureSnackBar('Mensagens'),
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            'Eventos novos',
            onTap: () => _showFeatureSnackBar('Eventos'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: darkBlue,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  // 4️⃣ Botões de Navegação (Cards)
  Widget _buildNavigationCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
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
                          color: primaryBlue.withOpacity(0.1),
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
                          color: const Color(0xFF6C63FF).withOpacity(0.1),
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
          // Segunda linha - um card maior
          _buildNavigationCard(
            height: 80,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: const Color(0xFF2ECC71),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Carteira Compartilhada',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: darkBlue,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
              ],
            ),
            onTap: () => _showFeatureSnackBar('Carteira'),
          ),
        ],
      ),
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
            color: Colors.black.withOpacity(0.05),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshGroup,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
    );
  }

  void _showGroupOptions() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Opções do grupo em breve!'),
        backgroundColor: primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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
