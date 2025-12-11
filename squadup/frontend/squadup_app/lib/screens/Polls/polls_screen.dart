import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'create_poll_screen.dart';
import '../../widgets/squadup_button.dart';
import '../../services/polls_service.dart';

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

class _PollsScreenState extends State<PollsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final darkBlue = const Color.fromARGB(255, 29, 56, 95);
  final primaryBlue = const Color.fromARGB(255, 81, 163, 230);
  final PollsService _pollsService = PollsService();
  List<dynamic> _activePolls = [];
  List<dynamic> _finishedPolls = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPolls();
  }

  Future<void> _loadPolls() async {
    setState(() => _isLoading = true);
    try {
      final response = await _pollsService.getPollsByGroup(widget.groupId);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final polls = response.data['data'] as List;
        setState(() {
          _activePolls = polls.where((p) => p['status'] == 'active').toList();
          _finishedPolls = polls.where((p) => p['status'] == 'closed').toList();
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
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,    
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: darkBlue, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Polls',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: darkBlue,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActivePolls(),
                _buildFinishedPolls(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal:40.0, vertical: 40.0),
            child: SquadUpButton(
              text: 'New Poll',
              width: double.infinity,
              height: 55,
              backgroundColor: darkBlue,
              onPressed: () async {
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
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePolls() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activePolls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.poll_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No active polls',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activePolls.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            children: [
              _buildStatsCard(),
              const SizedBox(height: 20),
            ],
          );
        }
        final poll = _activePolls[index - 1];
        final options = (poll['options'] as List?)?.map((opt) {
          final totalVotes = (poll['options'] as List)
              .fold<int>(0, (sum, o) => sum + (o['vote_count'] as int? ?? 0));
          final voteCount = opt['vote_count'] as int? ?? 0;
          final percentage = totalVotes > 0 ? (voteCount * 100 / totalVotes).round() : 0;
          return PollOption(name: opt['text'], percentage: percentage);
        }).toList() ?? [];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildPollCard(
            icon: Icons.poll,
            iconColor: darkBlue,
            title: poll['title'] ?? '',
            options: options,
            participants: (poll['votes'] as List?)?.length ?? 0,
            endDate: poll['closed_at'] != null ? poll['closed_at'].toString().substring(0, 10) : 'No end date',
          ),
        );
      },
    );
  }

  Widget _buildFinishedPolls() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_finishedPolls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No finished polls',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _finishedPolls.length,
      itemBuilder: (context, index) {
        final poll = _finishedPolls[index];
        final options = (poll['options'] as List?)?.map((opt) {
          final totalVotes = (poll['options'] as List)
              .fold<int>(0, (sum, o) => sum + (o['vote_count'] as int? ?? 0));
          final voteCount = opt['vote_count'] as int? ?? 0;
          final percentage = totalVotes > 0 ? (voteCount * 100 / totalVotes).round() : 0;
          return PollOption(name: opt['text'], percentage: percentage);
        }).toList() ?? [];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildPollCard(
            icon: Icons.check_circle,
            iconColor: Colors.green,
            title: poll['title'] ?? '',
            options: options,
            participants: (poll['votes'] as List?)?.length ?? 0,
            endDate: poll['closed_at'] != null ? poll['closed_at'].toString().substring(0, 10) : 'Closed',
          ),
        );
      },
    );
  }


  Widget _buildStatsCard() {
    final totalPolls = _activePolls.length + _finishedPolls.length;
    final activeCount = _activePolls.length;
    final closedCount = _finishedPolls.length;

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('$activeCount', 'Active'),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildStatItem('$closedCount', 'Closed'),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
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
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildPollCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<PollOption> options,
    required int participants,
    required String endDate,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: darkBlue,
                      ),
                    ),
                    
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...options.map((option) => _buildPollOption(option)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.people_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '$participants',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                endDate,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: darkBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPollOption(PollOption option) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  option.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: darkBlue,
                  ),
                ),
              ),
              Text(
                '${option.percentage}%',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: darkBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: option.percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class PollOption {
  final String name;
  final int percentage;

  PollOption({required this.name, required this.percentage});
}
