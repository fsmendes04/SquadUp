import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/avatar_group.dart';
import '../widgets/loading_overlay.dart';
import '../services/groups_service.dart';
import '../models/groups.dart';

class GroupGalleryScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupGalleryScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupGalleryScreen> createState() => _GroupGalleryScreenState();
}

class _GroupGalleryScreenState extends State<GroupGalleryScreen> {
  final darkBlue = const Color.fromARGB(255, 29, 56, 95);
  final primaryBlue = const Color.fromARGB(255, 81, 163, 230);
  final lightGrey = const Color.fromARGB(255, 242, 242, 242);

  final _groupsService = GroupsService();
  GroupWithMembers? _groupDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroupDetails();
  }

  Future<void> _loadGroupDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _groupsService.getGroupById(widget.groupId);
      final groupDetails = GroupWithMembers.fromJson(response['data']);

      if (mounted) {
        setState(() {
          _groupDetails = groupDetails;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error loading group details: $e');
    }
  }

  // Dados fictícios dos eventos
  final List<Map<String, dynamic>> events = [
    {
      'id': 1,
      'title': 'Beach Day Trip',
      'date': '24 Nov 2025',
      'location': 'Miami Beach',
      'photoCount': 6,
      'image': 'lib/images/beach.jpeg',
    },
    {
      'id': 2,
      'title': 'Weekend BBQ',
      'date': '15 Nov 2025',
      'location': 'Central Park',
      'photoCount': 12,
      'image': 'lib/images/bbq.webp',
    },
    {
      'id': 3,
      'title': 'Movie Night',
      'date': '10 Nov 2025',
      'location': 'Cinema City',
      'photoCount': 8,
      'image': 'lib/images/movie.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Loading gallery...',
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: _buildHeader(darkBlue),
              ),
              const SizedBox(height: 20),

              // Filtros
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          _buildFilterChip('Filters'),
                          const SizedBox(width: 8),
                          _buildAddButton(),
                        ],
                      ),
                    ),
                    Icon(Icons.search, size: 32, color: darkBlue),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Lista de eventos
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: _buildEventCard(event),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color darkBlue) {
    return SizedBox(
      height: kToolbarHeight + 10, // espaço extra para avatar maior
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: darkBlue, size: 32),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Center(
                  child: AvatarGroupWidget(
                    groupId: widget.groupId,
                    avatarUrl: _groupDetails?.avatarUrl,
                    radius: 31,
                  ),
                ),
                const SizedBox(width: 14),
                // Nome do grupo
                Expanded(
                  child: Text(
                    _groupDetails?.name ?? widget.groupName,
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
            icon: Icon(Icons.edit, color: darkBlue, size: 32),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: primaryBlue, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primaryBlue,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.tune, size: 16, color: primaryBlue),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Criar novo evento em breve!'),
            backgroundColor: primaryBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryBlue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Abrir evento: ${event['title']}'),
            backgroundColor: primaryBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem do evento
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Image.asset(
                    event['image'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: primaryBlue.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.image_not_supported,
                          color: primaryBlue,
                          size: 50,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            // Informações do evento
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          event['title'],
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: darkBlue,
                          ),
                        ),
                      ),
                      Text(
                        '${event['photoCount']}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: darkBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: primaryBlue),
                      const SizedBox(width: 4),
                      Text(
                        event['location'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.calendar_today, size: 12, color: primaryBlue),
                      const SizedBox(width: 4),
                      Text(
                        event['date'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
