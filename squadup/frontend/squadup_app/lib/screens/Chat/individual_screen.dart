import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IndividualChatScreen extends StatefulWidget {
  final String chatId;
  final String userName;
  final String userUniNumber;

  const IndividualChatScreen({
    super.key,
    required this.chatId,
    required this.userName,
    required this.userUniNumber,
  });

  @override
  State<IndividualChatScreen> createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _hasText = false;
  bool _isSearching = false;
  String _searchQuery = '';
  final List<int> _highlightedMessageIndexes = [];
  int _currentHighlightIndex = -1;

  // Fictitious messages data
  final List<Map<String, dynamic>> _messages = [
    {
      'message_id': '1',
      'text': 'Hey! How are you doing?',
      'sender_uni': '20230001',
      'timestamp': '09:30',
      'is_mine': false,
    },
    {
      'message_id': '2',
      'text': 'I\'m good! Just finished the assignment',
      'sender_uni': '20230999',
      'timestamp': '09:32',
      'is_mine': true,
    },
    {
      'message_id': '3',
      'text': 'That\'s great! Did you understand the last topic?',
      'sender_uni': '20230001',
      'timestamp': '09:33',
      'is_mine': false,
    },
    {
      'message_id': '4',
      'text': 'Yes, it was challenging but I managed to get it',
      'sender_uni': '20230999',
      'timestamp': '09:35',
      'is_mine': true,
    },
    {
      'message_id': '5',
      'text': 'Can you help me with exercise 3?',
      'sender_uni': '20230001',
      'timestamp': '09:36',
      'is_mine': false,
    },
    {
      'message_id': '6',
      'text': 'Sure! Let\'s meet at the library tomorrow',
      'sender_uni': '20230999',
      'timestamp': '09:38',
      'is_mine': true,
    },
    {
      'message_id': '7',
      'text': 'Perfect! What time works for you?',
      'sender_uni': '20230001',
      'timestamp': '09:40',
      'is_mine': false,
    },
    {
      'message_id': '8',
      'text': 'How about 2 PM?',
      'sender_uni': '20230999',
      'timestamp': '09:42',
      'is_mine': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {
        _hasText = _messageController.text.trim().isNotEmpty;
      });
    });
    _searchController.addListener(() {
      _filterMessages(_searchController.text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _filterMessages(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _highlightedMessageIndexes.clear();
      _currentHighlightIndex = -1;

      if (_searchQuery.isNotEmpty) {
        for (int i = 0; i < _messages.length; i++) {
          final text = (_messages[i]['text'] ?? '').toString().toLowerCase();
          if (text.contains(_searchQuery)) {
            _highlightedMessageIndexes.add(i);
          }
        }

        if (_highlightedMessageIndexes.isNotEmpty) {
          _currentHighlightIndex = 0;
          _scrollToMessage(_highlightedMessageIndexes[0]);
        }
      }
    });
  }

  void _scrollToMessage(int messageIndex) {
    if (_scrollController.hasClients &&
        messageIndex >= 0 &&
        messageIndex < _messages.length) {
      final double itemHeight = 80.0;
      final double offset = messageIndex * itemHeight;
      final double maxScroll = _scrollController.position.maxScrollExtent;
      final double targetOffset = offset.clamp(0.0, maxScroll);

      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToNextMatch() {
    if (_highlightedMessageIndexes.isNotEmpty) {
      setState(() {
        _currentHighlightIndex =
            (_currentHighlightIndex + 1) % _highlightedMessageIndexes.length;
        _scrollToMessage(_highlightedMessageIndexes[_currentHighlightIndex]);
      });
    }
  }

  void _navigateToPreviousMatch() {
    if (_highlightedMessageIndexes.isNotEmpty) {
      setState(() {
        _currentHighlightIndex =
            (_currentHighlightIndex - 1 + _highlightedMessageIndexes.length) %
                _highlightedMessageIndexes.length;
        _scrollToMessage(_highlightedMessageIndexes[_currentHighlightIndex]);
      });
    }
  }

  Widget _buildHighlightedText(
    String text,
    bool isOther,
    bool isCurrentHighlight,
  ) {
    if (_searchQuery.isEmpty) {
      return Text(
        text,
        style: GoogleFonts.poppins(
          color: isOther ? Colors.black87 : Colors.white,
          fontSize: 15,
          height: 1.4,
        ),
      );
    }

    final String lowerText = text.toLowerCase();
    final String lowerQuery = _searchQuery.toLowerCase();
    final List<TextSpan> spans = [];

    int start = 0;
    int index = lowerText.indexOf(lowerQuery);

    while (index != -1) {
      if (index > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, index),
            style: GoogleFonts.poppins(
              color: isOther ? Colors.black87 : Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + _searchQuery.length),
          style: GoogleFonts.poppins(
            color:
                isCurrentHighlight
                    ? Colors.white
                    : (isOther ? Colors.black87 : Colors.white),
            fontSize: 15,
            height: 1.4,
            backgroundColor:
                isCurrentHighlight ? const Color(0xFF1D385F) : Colors.yellow.withOpacity(0.3),
            fontWeight: isCurrentHighlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      );

      start = index + _searchQuery.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    if (start < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(start),
          style: GoogleFonts.poppins(
            color: isOther ? Colors.black87 : Colors.white,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _highlightedMessageIndexes.clear();
        _currentHighlightIndex = -1;
        _searchQuery = '';
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSending = true;
      _messages.add({
        'message_id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': text,
        'sender_uni': '20230999',
        'timestamp': TimeOfDay.now().format(context),
        'is_mine': true,
      });
      _messageController.clear();
      _isSending = false;
    });

    _scrollToBottom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryBlue = const Color(0xFF64AFE8);
    final darkBlue = const Color(0xFF1D385F);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 12,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: darkBlue, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                // Avatar
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      widget.userName.isNotEmpty
                          ? widget.userName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: darkBlue,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Online',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF4CAF50),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isSearching ? Icons.close : Icons.search,
                    color: darkBlue,
                    size: 24,
                  ),
                  onPressed: _toggleSearch,
                  tooltip: _isSearching ? 'Close search' : 'Search messages',
                ),
              ],
            ),
          ),
          
          // Search bar
          if (_isSearching)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: darkBlue.withOpacity(0.05),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search in messages...',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: primaryBlue,
                            size: 22,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ),
                  ),
                  if (_highlightedMessageIndexes.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_currentHighlightIndex + 1}/${_highlightedMessageIndexes.length}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: darkBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.keyboard_arrow_up, color: primaryBlue, size: 24),
                      onPressed: _navigateToPreviousMatch,
                      tooltip: 'Previous',
                    ),
                    IconButton(
                      icon: Icon(Icons.keyboard_arrow_down, color: primaryBlue, size: 24),
                      onPressed: _navigateToNextMatch,
                      tooltip: 'Next',
                    ),
                  ] else if (_searchQuery.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        'No results',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          
          // Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: darkBlue.withOpacity(0.5),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isOther = !msg['is_mine'];
                      final isCurrentHighlight =
                          _currentHighlightIndex >= 0 &&
                          _highlightedMessageIndexes.isNotEmpty &&
                          _highlightedMessageIndexes[_currentHighlightIndex] == index;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment:
                              isOther
                                  ? MainAxisAlignment.start
                                  : MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (isOther) ...[
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: darkBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    widget.userName.isNotEmpty
                                        ? widget.userName[0].toUpperCase()
                                        : '?',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isOther ? Colors.grey.shade100 : primaryBlue,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(20),
                                    topRight: const Radius.circular(20),
                                    bottomLeft: Radius.circular(isOther ? 4 : 20),
                                    bottomRight: Radius.circular(isOther ? 20 : 4),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildHighlightedText(
                                      msg['text'] ?? '',
                                      isOther,
                                      isCurrentHighlight,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      msg['timestamp'] ?? '',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color:
                                            isOther
                                                ? Colors.black45
                                                : Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          
          // Input field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: darkBlue,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () {
                        // Attachment functionality
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Type a message...',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey.shade500,
                            fontSize: 15,
                          ),
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: darkBlue,
                        ),
                        enabled: !_isSending,
                        minLines: 1,
                        maxLines: 4,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _hasText ? primaryBlue : darkBlue,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(
                              _hasText ? Icons.send : Icons.mic,
                              color: Colors.white,
                              size: 20,
                            ),
                      onPressed: _isSending
                          ? null
                          : () {
                              if (_hasText) {
                                _sendMessage();
                              } else {
                                // Voice message functionality
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
