import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'individual_screen.dart';
import '../../widgets/header_avatar.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Fictitious chat data
  final List<Map<String, dynamic>> _chats = [
    {
      'chat_id': '1',
      'name': 'Ana Silva',
      'uni_number': '20230001',
      'last_message': 'Hey! Did you finish the project?',
      'timestamp': '10:30',
      'unread_count': 2,
      'avatar': 'A',
    },
    {
      'chat_id': '2',
      'name': 'João Santos',
      'uni_number': '20230002',
      'last_message': 'See you at the library!',
      'timestamp': '09:15',
      'unread_count': 0,
      'avatar': 'J',
    },
    {
      'chat_id': '3',
      'name': 'Maria Costa',
      'uni_number': '20230003',
      'last_message': 'Thanks for the notes 📚',
      'timestamp': 'Yesterday',
      'unread_count': 0,
      'avatar': 'M',
    },
    {
      'chat_id': '4',
      'name': 'Pedro Oliveira',
      'uni_number': '20230004',
      'last_message': 'Can you help me with the assignment?',
      'timestamp': 'Yesterday',
      'unread_count': 1,
      'avatar': 'P',
    },
    {
      'chat_id': '5',
      'name': 'Sofia Ferreira',
      'uni_number': '20230005',
      'last_message': 'Let\'s study together tomorrow',
      'timestamp': 'Monday',
      'unread_count': 0,
      'avatar': 'S',
    },
  ];

  // Fictitious group data
  final List<Map<String, dynamic>> _groups = [
    {
      'group_id': '1',
      'name': 'Software Engineering',
      'last_message': 'Carlos: Meeting at 3 PM',
      'timestamp': '11:45',
      'unread_count': 5,
      'members_count': 12,
      'avatar': 'SE',
    },
    {
      'group_id': '2',
      'name': 'Study Group 2024',
      'last_message': 'Rita: Check the shared document',
      'timestamp': '08:20',
      'unread_count': 0,
      'members_count': 8,
      'avatar': 'SG',
    },
    {
      'group_id': '3',
      'name': 'Project Team Alpha',
      'last_message': 'You: Sent a file',
      'timestamp': 'Yesterday',
      'unread_count': 3,
      'members_count': 5,
      'avatar': 'PT',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryBlue = const Color(0xFF64AFE8);
    final darkBlue = const Color(0xFF1D385F);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  HeaderAvatar(
                    darkBlue: darkBlue,
                    title: 'Messages',
                    groupId: 'messages',
                    avatarUrl: null,
                    onBack: () => Navigator.pop(context),
                    avatarRadius: 0,
                  ),
                  Positioned(
                    right: 20,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.search, size: 28, color: darkBlue),
                          onPressed: () {
                            // Search functionality
                          },
                          tooltip: 'Search',
                        ),
                        IconButton(
                          icon: Icon(Icons.add_circle_outline, size: 28, color: primaryBlue),
                          onPressed: () {
                            // New chat functionality
                          },
                          tooltip: 'New Chat',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              
              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: darkBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: darkBlue,
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Chats'),
                    Tab(text: 'Groups'),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // CHATS TAB
                    _buildChatsList(),
                    // GROUPS TAB
                    _buildGroupsList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatsList() {
    final primaryBlue = const Color(0xFF64AFE8);
    final darkBlue = const Color(0xFF1D385F);

    return ListView.builder(
      padding: const EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: kBottomNavigationBarHeight + 16,
      ),
      itemCount: _chats.length,
      itemBuilder: (context, index) {
        final chat = _chats[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IndividualChatScreen(
                  chatId: chat['chat_id'],
                  userName: chat['name'],
                  userUniNumber: chat['uni_number'],
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: chat['unread_count'] > 0
                    ? primaryBlue.withOpacity(0.3)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      chat['avatar'],
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Name and message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat['name'],
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: darkBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chat['last_message'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: darkBlue.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Time and badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      chat['timestamp'],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: darkBlue.withOpacity(0.6),
                      ),
                    ),
                    if (chat['unread_count'] > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          chat['unread_count'].toString(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupsList() {
    final primaryBlue = const Color(0xFF64AFE8);
    final darkBlue = const Color(0xFF1D385F);

    return ListView.builder(
      padding: const EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: kBottomNavigationBarHeight + 16,
      ),
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        final group = _groups[index];
        return InkWell(
          onTap: () {
            // Navigate to group chat
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Opening ${group['name']}',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: darkBlue,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: darkBlue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: group['unread_count'] > 0
                    ? primaryBlue.withOpacity(0.3)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Group Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: darkBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      group['avatar'],
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Name and message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              group['name'],
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: darkBlue,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.people,
                            size: 16,
                            color: darkBlue.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            group['members_count'].toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: darkBlue.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        group['last_message'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: darkBlue.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Time and badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      group['timestamp'],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: darkBlue.withOpacity(0.6),
                      ),
                    ),
                    if (group['unread_count'] > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          group['unread_count'].toString(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
