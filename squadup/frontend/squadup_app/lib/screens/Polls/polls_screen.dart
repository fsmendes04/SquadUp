import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'create_poll_screen.dart';
import '../../widgets/squadup_button.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
                  // TODO: Refresh polls list
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePolls() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatsCard(),
        const SizedBox(height: 20),
        _buildPollCard(
          icon: Icons.location_on,
          iconColor: darkBlue,
          title: 'Quem chega primeiro ao Porto?',
          options: [
            PollOption(name: 'João (your choice)', percentage: 40),
            PollOption(name: 'Miguel', percentage: 40),
            PollOption(name: 'Ana', percentage: 20),
          ],
          participants: 5,
          endDate: '14 Mar 2024',
        ),
      ],
    );
  }

  Widget _buildFinishedPolls() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Nenhuma aposta terminada',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildStatsCard() {
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
              _buildStatItem('23', 'Vitórias'),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildStatItem('22', 'Derrotas'),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildStatItem('45', 'Total'),
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
                'Termina: $endDate',
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
    final isSelected = option.name.contains('(your choice)');
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
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
              valueColor: AlwaysStoppedAnimation<Color>(
                isSelected ? darkBlue : primaryBlue,
              ),
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
