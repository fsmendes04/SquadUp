import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/avatar_group.dart';
import '../../widgets/loading_overlay.dart';
import '../../services/groups_service.dart';
import '../../services/gallery_service.dart';
import '../../models/groups.dart';
import '../../models/gallery.dart';

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
  final _galleryService = GalleryService();
  GroupWithMembers? _groupDetails;
  List<Gallery> _galleries = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load group details and galleries in parallel
      final groupResponse = await _groupsService.getGroupById(widget.groupId);
      final galleries = await _galleryService.getGalleriesByGroup(
        widget.groupId,
      );

      if (mounted) {
        setState(() {
          _groupDetails = GroupWithMembers.fromJson(groupResponse['data']);
          _galleries = galleries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar galeria';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Loading gallery...',
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child:
              _error != null
                  ? _buildErrorState()
                  : RefreshIndicator(
                    onRefresh: _refreshData,
                    color: primaryBlue,
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
                          child:
                              _galleries.isEmpty
                                  ? _buildEmptyState()
                                  : ListView.builder(
                                    padding: const EdgeInsets.all(16.0),
                                    itemCount: _galleries.length,
                                    itemBuilder: (context, index) {
                                      final gallery = _galleries[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 20.0,
                                        ),
                                        child: _buildGalleryCard(gallery),
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
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
      onTap: () async {
        final result = await Navigator.pushNamed(
          context,
          '/create-gallery',
          arguments: {
            'groupId': widget.groupId,
            'groupName': _groupDetails?.name ?? widget.groupName,
          },
        );
        if (result == true) {
          await _loadData();
        }
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhuma galeria ainda',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie a primeira galeria do grupo!',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
            onPressed: _refreshData,
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
    );
  }

  Widget _buildGalleryCard(Gallery gallery) {
    final firstImage = gallery.images.isNotEmpty ? gallery.images.first : null;

    return GestureDetector(
      onTap: () {
        // TODO: Navigate to gallery details screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Abrir galeria: ${gallery.eventName}'),
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
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child:
                  firstImage != null
                      ? Image.network(
                        firstImage,
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
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            color: primaryBlue.withValues(alpha: 0.1),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: primaryBlue,
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                              ),
                            ),
                          );
                        },
                      )
                      : Container(
                        height: 200,
                        color: primaryBlue.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.photo_library_outlined,
                          color: primaryBlue,
                          size: 50,
                        ),
                      ),
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
                          gallery.eventName,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: darkBlue,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.photo_library,
                            size: 16,
                            color: primaryBlue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${gallery.images.length}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: darkBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: primaryBlue),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          gallery.location,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.calendar_today, size: 12, color: primaryBlue),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(gallery.date),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
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
    );
  }
}
