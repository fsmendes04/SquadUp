import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/avatar_widget.dart';
import 'create_poll_screen.dart';
import 'poll_details_screen.dart';
import '../../widgets/header_avatar.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/navigation_bar.dart';
import '../../services/polls_service.dart';
import '../../services/groups_service.dart';
import '../../models/groups.dart';

class PollsScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const PollsScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends State<PollsScreen> {
  final darkBlue = const Color.fromARGB(255, 29, 56, 95);
  final primaryBlue = const Color.fromARGB(255, 81, 163, 230);
  final PollsService _pollsService = PollsService();
  final _groupsService = GroupsService();
  GroupWithMembers? _groupDetails;
  List<dynamic> _activePolls = [];
  List<dynamic> _finishedPolls = [];
  bool _isLoading = true;
  Map<String, String?> _userVotes = {};
  final Map<String, bool> _expandedPolls = {};
  String _selectedStatus = 'all';
  String _selectedType = 'voting';
  @override
  void initState() {
    super.initState();
    _loadPolls();
  }

  Future<void> _loadPolls() async {
    setState(() => _isLoading = true);
    try {
      final groupResponse = await _groupsService.getGroupById(widget.groupId);
      final response = await _pollsService.getPollsByGroup(widget.groupId);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final polls = response.data['data'] as List;
        final now = DateTime.now();
        
        // Filter polls based on closed_at date and status
        final activePolls = polls.where((p) {
          if (p['status'] == 'closed') return false;
          if (p['closed_at'] != null) {
            try {
              final closedAt = DateTime.parse(p['closed_at']);
              // If closed_at is in the past, it's finished
              if (closedAt.isBefore(now)) return false;
            } catch (_) {}
          }
          return true;
        }).toList();
        
        final finishedPolls = polls.where((p) {
          if (p['status'] == 'closed') return true;
          if (p['closed_at'] != null) {
            try {
              final closedAt = DateTime.parse(p['closed_at']);
              // If closed_at is in the past, it's finished
              if (closedAt.isBefore(now)) return true;
            } catch (_) {}
          }
          return false;
        }).toList();

        Map<String, String?> userVotes = {};
        for (var poll in activePolls) {
          final pollId = poll['id'];
          try {
            final voteResp = await _pollsService.getUserVoteInPoll(pollId);
            if (voteResp.statusCode == 200 && voteResp.data['success'] == true) {
              userVotes[pollId] = voteResp.data['data'];
            } else {
              userVotes[pollId] = null;
            }
          } catch (_) {
            userVotes[pollId] = null;
          }
        }

        for (var poll in finishedPolls) {
          final pollId = poll['id'];
          try {
            final voteResp = await _pollsService.getUserVoteInPoll(pollId);
            if (voteResp.statusCode == 200 && voteResp.data['success'] == true) {
              userVotes[pollId] = voteResp.data['data'];
            } else {
              userVotes[pollId] = null;
            }
          } catch (_) {
            userVotes[pollId] = null;
          }
        }

        setState(() {
          _groupDetails = GroupWithMembers.fromJson(groupResponse['data']);
          _activePolls = activePolls;
          _finishedPolls = finishedPolls;
          _userVotes = userVotes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading polls: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Loading polls...',
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(darkBlue),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_isLoading) ...[
                        const SizedBox(height: 4),
                        _buildTypeSelector(darkBlue),
                        const SizedBox(height: 16),
                        _buildStatsCard(),
                        const SizedBox(height: 20),
                        _buildStatusSelector(darkBlue),
                        if (_activePolls.where((p) => p['type'] == _selectedType).isNotEmpty ||
                            _finishedPolls.where((p) => p['type'] == _selectedType).isNotEmpty)
                          const SizedBox(height: 20),
                      ],
                      _buildPollsList(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      bottomNavigationBar: CustomCircularNavBar(
        currentIndex: 3,
        icons: [Icons.add_sharp, Icons.bar_chart_rounded],
        outlinedIcons: [Icons.add_outlined, Icons.bar_chart_outlined],
        backgroundColor: darkBlue,
        iconColor: Colors.white,
        onTap: (index) {
          if (index == 0) {
            _navigateToCreatePoll();
          }
        },
      ),
      ),
    );
  }

  Future<void> _navigateToCreatePoll() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePollScreen(
          groupId: widget.groupId,
          groupName: widget.groupName,
        ),
      ),
    );
    if (result == true) {
      _loadPolls();
    }
  }

  Widget _buildHeader(Color darkBlue) {
    return HeaderAvatar(
      darkBlue: darkBlue,
      title: _groupDetails?.name ?? widget.groupName,
      groupId: widget.groupId,
      avatarUrl: _groupDetails?.avatarUrl,
    );
  }

  Widget _buildPollsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filtrar as enquetes pelo tipo selecionado
    List<dynamic> filteredActivePolls = _activePolls.where((p) => p['type'] == _selectedType).toList();
    List<dynamic> filteredFinishedPolls = _finishedPolls.where((p) => p['type'] == _selectedType).toList();

    List<dynamic> displayPolls = [];

    if (_selectedStatus == 'all') {
      displayPolls = [...filteredActivePolls, ...filteredFinishedPolls];
    } else if (_selectedStatus == 'active') {
      displayPolls = filteredActivePolls;
    } else {
      displayPolls = filteredFinishedPolls;
    }

    if (displayPolls.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 0.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 400,
              height: 400,
              child: Center(
                child: Opacity(
                  opacity: 0.12,
                  child: Image.asset(
                    'lib/images/logo_v3.png',
                    width: 300,
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Text(
              _selectedType == 'voting'
                  ? 'No polls found.'
                  : 'No bets found.',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    }

    return Column(
      children: displayPolls.asMap().entries.map((entry) {
        final poll = entry.value;
        final pollId = poll['id'] ?? '';
        final isExpanded = _expandedPolls[pollId] ?? false;
        
        // Determinar ícone e cor baseado no status da poll individual (sempre verde se fechada)
        final pollIsClosed = poll['status'] == 'closed' || 
          (poll['closed_at'] != null && DateTime.parse(poll['closed_at']).isBefore(DateTime.now()));
        final pollIcon = pollIsClosed ? Icons.check_circle : Icons.dehaze_rounded;
        final pollIconColor = pollIsClosed ? Colors.green : darkBlue;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildPollCard(
            poll: poll,
            icon: pollIcon,
            iconColor: pollIconColor,
            participants: (poll['votes'] as List?)?.length ?? 0,
            endDate: poll['closed_at'] != null ? poll['closed_at'].toString().substring(0, 10) : (pollIsClosed ? 'Closed' : 'No end date'),
            isActive: !pollIsClosed,
            isExpanded: isExpanded,
            onExpandToggle: () {
              setState(() {
                _expandedPolls[pollId] = !isExpanded;
              });
            },
          ),
        );
      }).toList(),
    );
  }


  Widget _buildStatsCard() {
    final totalPolls = _activePolls.length + _finishedPolls.length;
    final activeCount = _activePolls.length;
    final closedCount = _finishedPolls.length;

    return Container(
      height: 110,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
       gradient: LinearGradient(
          colors: [primaryBlue, darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('$activeCount', 'Open'),
              _buildStatItem('$closedCount', 'Finished'),
              _buildStatItem('$totalPolls', 'Total'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.9),
          ), 
        ),
      ],
    );
  }

    Widget _buildTypeSelector(Color darkBlue) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Botão Polls
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = 'voting';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: _selectedType == 'voting' ? darkBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Polls',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _selectedType == 'voting' ? Colors.white : darkBlue,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Botão Bets
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = 'betting';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: _selectedType == 'betting' ? darkBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Bets',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _selectedType == 'betting' ? Colors.white : darkBlue,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelector(Color darkBlue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Botão All
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedStatus = 'all';
            });
          },
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: darkBlue, width: 2),
                ),
                child: Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _selectedStatus == 'all'
                              ? darkBlue
                              : Colors.transparent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'All',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: darkBlue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Botão Active
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedStatus = 'active';
            });
          },
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: darkBlue, width: 2),
                ),
                child: Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _selectedStatus == 'active'
                              ? darkBlue
                              : Colors.transparent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Open',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: darkBlue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Botão Closed
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedStatus = 'closed';
            });
          },
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: darkBlue, width: 2),
                ),
                child: Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _selectedStatus == 'closed'
                              ? darkBlue
                              : Colors.transparent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Finished',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: darkBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPollCard({
    required Map<String, dynamic> poll,
    required IconData icon,
    required Color iconColor,
    required int participants,
    required String endDate,
    required bool isActive,
    required bool isExpanded,
    required VoidCallback onExpandToggle,
  }) {
    final pollId = poll['id'] ?? '';
    final title = poll['title'] ?? '';
    final createdByData = poll['created_by'];
    Map<String, dynamic>? createdBy;
    // Lookup creator name from group members
    if (createdByData is String && _groupDetails != null) {
      final member = _groupDetails!.getMember(createdByData);
      if (member != null) {
        createdBy = {
          'name': member.name ?? 'Unknown',
          'avatar_url': member.avatarUrl,
        };
      }
    } else if (createdByData is Map<String, dynamic>) {
      createdBy = createdByData;
    }
    final pollType = poll['type'] ?? 'voting';
    final isBet = pollType == 'betting';
    final options = (poll['options'] as List?)?.map((opt) {
      return {
        'id': opt['id'],
        'text': opt['text'],
        'vote_count': opt['vote_count'] ?? 0,
      };
    }).toList() ?? [];

    // Encontrar opções com mais votos (incluindo empates)
    int maxVotes = 0;
    for (var option in options) {
      final voteCount = option['vote_count'] as int;
      if (voteCount > maxVotes) {
        maxVotes = voteCount;
      }
    }

    // Obter todas as opções com o máximo de votos e que tenham votos > 0
    List<Map<String, dynamic>> winningOptions = [];
    if (maxVotes > 0) {
      winningOptions = options
          .where((option) => (option['vote_count'] as int) == maxVotes)
          .toList()
          .cast<Map<String, dynamic>>();
    }

    return GestureDetector(
      onTap: onExpandToggle,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Fundo decorativo no topo
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: iconColor,
                ),
              ),
            ),
            // Conteúdo principal
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header com ícone e título
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, color: iconColor, size: 32),
                      ),
                      const SizedBox(width: 16),
                      // Título e ícone de expandir juntos
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.poppins(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: darkBlue,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 50,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: iconColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(
                                isExpanded ? Icons.expand_less : Icons.expand_more,
                                size: 22,
                                color: darkBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Conteúdo condicional (colapsado ou expandido)
                // For bets, don't show options
                if (!isBet && isExpanded)
                  // Versão expandida: mostrar todas as opções
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...options.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final option = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: idx < options.length - 1 ? 16 : 0,
                            ),
                            child: _buildPollOption(
                              pollId: pollId,
                              option: option,
                              votes: poll['votes'] as List?,
                              isActive: isActive,
                              maxVotes: maxVotes,
                            ),
                          );
                        }),
                      ],
                    ),
                  )
                else if (!isBet && winningOptions.isNotEmpty)
                  // Versão colapsada: mostrar opções vencedoras (podendo haver empate)
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...winningOptions.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final winningOption = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: idx < winningOptions.length - 1 ? 12 : 0,
                            ),
                            child: _buildWinningOptionCompact(
                              pollId: pollId,
                              option: winningOption,
                              iconColor: iconColor,
                              votes: poll['votes'] as List?,
                              isActive: isActive,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                // Show creator name for bets when expanded
                if (isBet && isExpanded && createdBy != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 4, bottom: 10),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.only(left: 12, right: 12),
                      child: Row(
                        children: [
                          UserAvatarDisplay(
                            avatarUrl: createdBy['avatar_url'] as String?,
                            radius: 24,
                            onTap: null,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              createdBy['name'] ?? 'Unknown',
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
                  ),
                // Divider
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 6, bottom: 20, right: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(isBet ? Icons.monetization_on : Icons.people_outline, 
                                  size: 18, 
                                  color: darkBlue,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isBet 
                                    ? '${options.length} ${options.length == 1 ? "Challenger" : "Challengers"}'
                                    : '$participants votes',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: darkBlue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.access_time, 
                                  size: 18, 
                                  color: darkBlue,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    endDate,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: darkBlue,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PollDetailsScreen(
                                          poll: poll,
                                          groupName: _groupDetails?.name ?? widget.groupName,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Details',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: darkBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
    );
  }

  Widget _buildWinningOptionCompact({
    required String pollId,
    required Map<String, dynamic> option,
    required Color iconColor,
    required List? votes,
    required bool isActive,
  }) {
    final optionId = option['id'] as String;
    final optionText = option['text'] as String;
    final voteCount = option['vote_count'] as int;
    final totalVotes = votes?.length ?? 0;

    // Verificar se o usuário votou nesta opção
    final userVotedOptionId = _userVotes[pollId];
    final isUserVoted = userVotedOptionId != null && userVotedOptionId == optionId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isUserVoted ? darkBlue : Colors.grey[300]!,
                  width: isUserVoted ? 2.5 : 2,
                ),
                color: isUserVoted ? darkBlue.withValues(alpha: 0.08) : Colors.transparent,
              ),
              child: isUserVoted
                  ? Center(
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: darkBlue,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          optionText,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: isUserVoted ? FontWeight.w700 : FontWeight.w500,
                            color: darkBlue,
                          ),
                        ),
                      ),
                      Text(
                        '$voteCount',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: darkBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: totalVotes > 0 ? voteCount / totalVotes : 0,
                      minHeight: 12,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(!isActive ? Colors.green : primaryBlue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPollOption({
    required String pollId,
    required Map<String, dynamic> option,
    required List? votes,
    required bool isActive,
    required int maxVotes,
  }) {
    final optionId = option['id'] as String;
    final optionText = option['text'] as String;
    final voteCount = option['vote_count'] as int;

    // Usar _userVotes para saber se o user votou nesta opção
    final userVotedOptionId = _userVotes[pollId];
    final isSelected = userVotedOptionId != null && userVotedOptionId == optionId;

    // Verificar se é uma opção vencedora (só em poll fechada)
    final isWinner = !isActive && voteCount == maxVotes && maxVotes > 0;

    return Padding(
      padding: EdgeInsets.zero,
      child: GestureDetector(
        onTap: isActive ? () => _castVote(pollId, optionId) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: isActive ? () => _castVote(pollId, optionId) : null,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? darkBlue : Colors.grey[300]!,
                        width: isSelected ? 2.5 : 2,
                      ),
                      color: isSelected ? darkBlue.withValues(alpha: 0.08) : Colors.transparent,
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: darkBlue,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              optionText,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: darkBlue,
                              ),
                            ),
                          ),
                          Text(
                            '$voteCount',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: darkBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildVoteProgressBar(option, votes, isWinner)
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _castVote(String pollId, String optionId) async {
    try {
      final response = await _pollsService.voteInPoll(
        pollId,
        {'optionId': optionId},
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        _loadPolls();
      }
    // ignore: empty_catches
    } catch (e) {
    }
  }

  Widget _buildVoteProgressBar(Map<String, dynamic> option, List? votes, bool isWinner) {
    final voteCount = option['vote_count'] as int;
    final totalVotes = votes?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: totalVotes > 0 ? voteCount / totalVotes : 0,
            minHeight: 12,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(isWinner ? Colors.green : primaryBlue),
          ),
        ),
      ],
    );
  }
}
