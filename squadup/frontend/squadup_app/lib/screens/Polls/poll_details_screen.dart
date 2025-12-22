import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/header.dart';
import '../../widgets/loading_overlay.dart';
import '../../services/polls_service.dart';
import '../../services/groups_service.dart';
import '../../models/groups.dart';

class PollDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> poll;
  final String groupName;

  const PollDetailsScreen({
    super.key,
    required this.poll,
    required this.groupName,
  });

  @override
  State<PollDetailsScreen> createState() => _PollDetailsScreenState();
}

class _PollDetailsScreenState extends State<PollDetailsScreen> {
  final darkBlue = const Color.fromARGB(255, 29, 56, 95);
  final primaryBlue = const Color.fromARGB(255, 81, 163, 230);
  final PollsService _pollsService = PollsService();
  final GroupsService _groupsService = GroupsService();
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _detailedVotes = [];
  GroupWithMembers? _groupDetails;
  final Map<String, bool> _expandedOptions = {};

  @override
  void initState() {
    super.initState();
    _loadVoteDetails();
    _loadGroupDetails();
  }

  Future<void> _loadGroupDetails() async {
    try {
      final groupId = widget.poll['group_id'];
      if (groupId != null) {
        final groupResponse = await _groupsService.getGroupById(groupId);
        if (mounted) {
          setState(() {
            _groupDetails = GroupWithMembers.fromJson(groupResponse['data']);
          });
        }
      }
    } catch (e) {
      // Silently fail - group details are optional
    }
  }

  Future<void> _loadVoteDetails() async {
    setState(() => _isLoading = true);
    try {
      final pollId = widget.poll['id'];
      final response = await _pollsService.getPollVotes(pollId);
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _detailedVotes = (response.data['data'] as List)
              .map((vote) => vote as Map<String, dynamic>)
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading vote details: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pollIsClosed = widget.poll['status'] == 'closed' || 
      (widget.poll['closed_at'] != null && 
       DateTime.parse(widget.poll['closed_at']).isBefore(DateTime.now()));
    
    final options = (widget.poll['options'] as List?)?.map((opt) {
      return {
        'id': opt['id'],
        'text': opt['text'],
        'vote_count': opt['vote_count'] ?? 0,
        'challenger_user_id': opt['challenger_user_id'],
        'challenger_reward_amount': opt['challenger_reward_amount'],
        'challenger_reward_text': opt['challenger_reward_text'],
      };
    }).toList() ?? [];

    // Calculate max votes for winner display
    int maxVotes = 0;
    for (var option in options) {
      final voteCount = option['vote_count'] as int;
      if (voteCount > maxVotes) {
        maxVotes = voteCount;
      }
    }

    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Loading details...',
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              CustomHeader(
                darkBlue: darkBlue,
                title: 'Poll Details',
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPollHeader(pollIsClosed),
                      const SizedBox(height: 24),
                      _buildPollInfo(pollIsClosed),
                      const SizedBox(height: 24),
                      _buildOptionsSection(options, maxVotes, pollIsClosed),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPollHeader(bool isClosed) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (primaryBlue).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isClosed ? 'CLOSED' : 'ACTIVE',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.poll['title'] ?? 'Poll',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollInfo(bool isClosed) {
    final totalVotes = (widget.poll['votes'] as List?)?.length ?? 0;
    final options = (widget.poll['options'] as List?)?.length ?? 0;
    final closedAt = widget.poll['closed_at'] != null
      ? DateTime.parse(widget.poll['closed_at']).toLocal().toString().substring(0, 10)
      : 'No end date';

    String pollType = (widget.poll['type'] ?? 'voting').toString();
    if (pollType.isNotEmpty) {
      pollType = pollType[0].toUpperCase() + pollType.substring(1);
    }
    
    final isBet = widget.poll['type'] == 'betting';
    final votesLabel = isBet ? 'Total Challengers' : 'Total Votes';
    final votesCount = isBet ? options : totalVotes;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.people_outline, votesLabel, '$votesCount'),
          const SizedBox(height: 16),
          _buildInfoRow(
            isClosed ? Icons.event_busy : Icons.access_time,
            isClosed ? 'Closed' : 'Closes',
            closedAt,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: darkBlue),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: darkBlue,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsSection(List<Map<String, dynamic>> options, int maxVotes, bool isClosed) {
    final isBet = widget.poll['type'] == 'betting';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isBet ? 'Bets' : 'Votes',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: darkBlue,
          ),
        ),
        const SizedBox(height: 16),
        ...options.map((option) {
          final isWinner = isClosed && option['vote_count'] == maxVotes && maxVotes > 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildOptionCard(option, isWinner, isClosed, isBet),
          );
        }),
      ],
    );
  }

  Widget _buildOptionCard(Map<String, dynamic> option, bool isWinner, bool isClosed, bool isBet) {
    final optionId = option['id'] as String;
    final optionText = option['text'] as String;
    final voteCount = option['vote_count'] as int;
    final totalVotes = (widget.poll['votes'] as List?)?.length ?? 0;
    
    // Get voters for this option
    final voters = _detailedVotes
        .where((vote) => vote['option_id'] == optionId)
        .toList();

    final isExpanded = _expandedOptions[optionId] ?? false;
    
    final challengerId = isBet ? option['challenger_user_id'] : null;
    String? challenger;
    String? challengerAvatar;
    
    if (isBet && challengerId != null && _groupDetails != null) {
      // challengerId is actually the group member id, not the user_id
      final member = _groupDetails!.members.firstWhere(
        (m) => m.id == challengerId,
        orElse: () => null as dynamic,
      ) as GroupMember?;
      if (member != null) {
        challenger = member.name ?? 'Unknown';
        challengerAvatar = member.avatarUrl;
      }
    }
    
    final reward = isBet ? option['challenger_reward_amount'] : null;
    final rewardText = isBet ? option['challenger_reward_text'] : null;

    return GestureDetector(
      onTap: (isBet || voters.isNotEmpty) ? () {
        setState(() {
          _expandedOptions[optionId] = !isExpanded;
        });
      } : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isWinner)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.emoji_events,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      if (isWinner) const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          optionText,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: darkBlue,
                          ),
                        ),
                      ),
                      if (isBet || voters.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: darkBlue,
                            size: 24,
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isWinner 
                            ? Colors.green.withValues(alpha: 0.15)
                            : darkBlue.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$voteCount',
                          style: GoogleFonts.poppins( 
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isWinner ? Colors.green : darkBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Show progress bar only for voting polls, not for bets
                  if (!isBet) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final double percent = totalVotes > 0 ? voteCount / totalVotes : 0;
                              return Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  Container(
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  if (percent > 0)
                                    Container(
                                      height: 12,
                                      width: constraints.maxWidth * percent,
                                      decoration: BoxDecoration(
                                        color: isWinner ? Colors.green : primaryBlue,
                                        borderRadius: BorderRadius.horizontal(
                                          left: const Radius.circular(8),
                                          right: percent >= 0.999 ? const Radius.circular(8) : const Radius.circular(0),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${totalVotes > 0 ? ((voteCount / totalVotes * 100).toStringAsFixed(1)) : "0"}%',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // For bets: show challenger and reward
            if (isBet && isExpanded) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    if (challenger != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Challenger',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                UserAvatarDisplay(
                                  avatarUrl: challengerAvatar,
                                  radius: 16,
                                  onTap: null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    challenger,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
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
                    if (challenger != null && (reward != null || rewardText != null))
                      const SizedBox(width: 25),
                    if (reward != null || rewardText != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reward',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      rewardText ?? (reward?.toString() ?? 'No reward'),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: darkBlue,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ]
            // For voting polls: show voters
            else if (!isBet && voters.isNotEmpty && isExpanded) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voters',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...voters.map((voter) {
                      final userName = voter['user_name'] ?? 'User';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.only(left: 12, right: 12),
                        child: Row(
                          children: [
                            UserAvatarDisplay(
                              avatarUrl: voter['avatar_url'],
                              radius: 18,
                              onTap: null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                userName,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: darkBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
