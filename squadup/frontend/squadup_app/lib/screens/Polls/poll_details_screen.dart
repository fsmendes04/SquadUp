import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/header.dart';
import '../../widgets/loading_overlay.dart';
import '../../services/polls_service.dart';
import '../../services/groups_service.dart';
import '../../models/groups.dart';
import '../../config/responsive_utils.dart';

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
    final r = context.responsive;
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
                  padding: EdgeInsets.all(r.width(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPollHeader(pollIsClosed),
                      SizedBox(height: r.height(24)),
                      _buildPollInfo(pollIsClosed),
                      SizedBox(height: r.height(24)),
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
    final r = context.responsive;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(r.width(20)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(r.borderRadius(20)),
        boxShadow: [
          BoxShadow(
            color: (primaryBlue).withValues(alpha: 0.3),
            blurRadius: r.width(15),
            offset: Offset(0, r.height(5)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: r.width(12), vertical: r.height(6)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(r.borderRadius(8)),
            ),
            child: Text(
              isClosed ? 'CLOSED' : 'ACTIVE',
              style: GoogleFonts.poppins(
                fontSize: r.fontSize(12),
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: r.height(12)),
          Text(
            widget.poll['title'] ?? 'Poll',
            style: GoogleFonts.poppins(
              fontSize: r.fontSize(20),
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollInfo(bool isClosed) {
    final r = context.responsive;
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
      padding: EdgeInsets.all(r.width(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.borderRadius(16)),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: r.width(10),
            offset: Offset(0, r.height(2)),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.people_outline, votesLabel, '$votesCount'),
          SizedBox(height: r.height(16)),
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
    final r = context.responsive;
    return Row(
      children: [
        Icon(icon, size: r.iconSize(20), color: darkBlue),
        SizedBox(width: r.width(12)),
        Text(
          '$label:',
          style: GoogleFonts.poppins(
            fontSize: r.fontSize(14),
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(width: r.width(8)),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: r.fontSize(14),
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
    final r = context.responsive;
    final isBet = widget.poll['type'] == 'betting';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isBet ? 'Bets' : 'Votes',
          style: GoogleFonts.poppins(
            fontSize: r.fontSize(18),
            fontWeight: FontWeight.w700,
            color: darkBlue,
          ),
        ),
        SizedBox(height: r.height(16)),
        ...options.map((option) {
          final isWinner = isClosed && option['vote_count'] == maxVotes && maxVotes > 0;
          return Padding(
            padding: EdgeInsets.only(bottom: r.height(16)),
            child: _buildOptionCard(option, isWinner, isClosed, isBet),
          );
        }),
      ],
    );
  }

  Widget _buildOptionCard(Map<String, dynamic> option, bool isWinner, bool isClosed, bool isBet) {
    final r = context.responsive;
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
          borderRadius: BorderRadius.circular(r.borderRadius(16)),
          border: Border.all(
            color: Colors.grey[200]!,
            width: r.borderWidth(1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: r.width(10),
              offset: Offset(0, r.height(2)),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(r.width(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isWinner)
                        Container(
                          padding: EdgeInsets.all(r.width(6)),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(r.borderRadius(8)),
                          ),
                          child: Icon(
                            Icons.emoji_events,
                            color: Colors.white,
                            size: r.iconSize(16),
                          ),
                        ),
                      if (isWinner) SizedBox(width: r.width(12)),
                      Expanded(
                        child: Text(
                          optionText,
                          style: GoogleFonts.poppins(
                            fontSize: r.fontSize(16),
                            fontWeight: FontWeight.w700,
                            color: darkBlue,
                          ),
                        ),
                      ),
                      if (isBet || voters.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(right: r.width(8)),
                          child: Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: darkBlue,
                            size: r.iconSize(24),
                          ),
                        ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: r.width(12), vertical: r.height(6)),
                        decoration: BoxDecoration(
                          color: isWinner 
                            ? Colors.green.withValues(alpha: 0.15)
                            : darkBlue.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(r.borderRadius(8)),
                        ),
                        child: Text(
                          '$voteCount',
                          style: GoogleFonts.poppins( 
                            fontSize: r.fontSize(16),
                            fontWeight: FontWeight.w700,
                            color: isWinner ? Colors.green : darkBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Show progress bar only for voting polls, not for bets
                  if (!isBet) ...[
                    SizedBox(height: r.height(12)),
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
                                    height: r.height(14),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(r.borderRadius(8)),
                                    ),
                                  ),
                                  if (percent > 0)
                                    Container(
                                      height: r.height(12),
                                      width: constraints.maxWidth * percent,
                                      decoration: BoxDecoration(
                                        color: isWinner ? Colors.green : primaryBlue,
                                        borderRadius: BorderRadius.horizontal(
                                          left: Radius.circular(r.borderRadius(8)),
                                          right: percent >= 0.999 ? Radius.circular(r.borderRadius(8)) : Radius.circular(0),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                        SizedBox(width: r.width(8)),
                        Text(
                          '${totalVotes > 0 ? ((voteCount / totalVotes * 100).toStringAsFixed(1)) : "0"}%',
                          style: GoogleFonts.poppins(
                            fontSize: r.fontSize(12),
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
                padding: EdgeInsets.fromLTRB(r.width(16), 0, r.width(16), r.height(16)),
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
                                fontSize: r.fontSize(12),
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: r.height(12)),
                            Row(
                              children: [
                                UserAvatarDisplay(
                                  avatarUrl: challengerAvatar,
                                  radius: r.width(16),
                                  onTap: null,
                                ),
                                SizedBox(width: r.width(8)),
                                Expanded(
                                  child: Text(
                                    challenger,
                                    style: GoogleFonts.poppins(
                                      fontSize: r.fontSize(13),
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
                      SizedBox(width: r.width(25)),
                    if (reward != null || rewardText != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reward',
                              style: GoogleFonts.poppins(
                                fontSize: r.fontSize(12),
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: r.height(12)),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: r.width(10), vertical: r.height(6)),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      rewardText ?? (reward?.toString() ?? 'No reward'),
                                      style: GoogleFonts.poppins(
                                        fontSize: r.fontSize(12),
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
                padding: EdgeInsets.fromLTRB(r.width(16), r.height(12), r.width(16), r.height(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voters',
                      style: GoogleFonts.poppins(
                        fontSize: r.fontSize(12),
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: r.height(12)),
                    ...voters.map((voter) {
                      final userName = voter['user_name'] ?? 'User';
                      return Container(
                        margin: EdgeInsets.only(bottom: r.height(15)),
                        padding: EdgeInsets.only(left: r.width(12), right: r.width(12)),
                        child: Row(
                          children: [
                            UserAvatarDisplay(
                              avatarUrl: voter['avatar_url'],
                              radius: r.width(18),
                              onTap: null,
                            ),
                            SizedBox(width: r.width(12)),
                            Expanded(
                              child: Text(
                                userName,
                                style: GoogleFonts.poppins(
                                  fontSize: r.fontSize(14),
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
