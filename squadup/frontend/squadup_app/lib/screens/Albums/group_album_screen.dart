import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/header_avatar.dart';
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
  
  // Search functionality
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  List<Gallery> get _filteredGalleries {
    if (_searchQuery.isEmpty) {
      return _galleries;
    }
    return _galleries.where((gallery) {
      return gallery.eventName.toLowerCase().startsWith(_searchQuery.toLowerCase());
    }).toList();
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
                          _buildHeader(darkBlue),
                        const SizedBox(height: 20),

                        // Section title and add button
                        if (!_isSearching) ...[
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Albums',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: darkBlue,
                                    ),
                                  ),
                                  _buildAddButton(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],

                        // Search bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: _buildSearchBar(),
                        ),

                        // Lista de eventos
                        Expanded(
                          child:
                              _galleries.isEmpty
                                  ? _buildEmptyState()
                                  : _filteredGalleries.isEmpty && _searchQuery.isNotEmpty
                                      ? _buildNoSearchResultsState()
                                      : ListView.builder(
                                        padding: const EdgeInsets.all(16.0),
                                        itemCount: _filteredGalleries.length,
                                        itemBuilder: (context, index) {
                                          final gallery = _filteredGalleries[index];
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
    return HeaderAvatar(
      darkBlue: darkBlue,
      title: _groupDetails?.name ?? widget.groupName,
      groupId: widget.groupId,
      avatarUrl: _groupDetails?.avatarUrl,
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
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: primaryBlue,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: darkBlue.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              'New',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      onTap: () {
        setState(() {
          _isSearching = true;
        });
      },
      style: GoogleFonts.poppins(fontSize: 14, color: darkBlue),
      decoration: InputDecoration(
        hintText: 'Search albums...',
        hintStyle: GoogleFonts.poppins(
          fontSize: 17,
          color: darkBlue,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(Icons.search, color: darkBlue, size: 30),
        suffixIcon:
            _searchQuery.isNotEmpty || _isSearching
                ? IconButton(
                  icon: Icon(
                    _searchQuery.isNotEmpty ? Icons.clear : Icons.close,
                    color: darkBlue,
                    size: 28,
                  ),
                  onPressed: () {
                    if (_searchQuery.isNotEmpty) {
                      setState(() {
                        _searchQuery = '';
                      });
                    } else {
                      setState(() {
                        _isSearching = false;
                      });
                      FocusScope.of(context).unfocus();
                    }
                  },
                )
                : null,
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 60.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 300,
            height: 300,
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
          const SizedBox(height: 32),
          Text(
            'No albums yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Create the first album for the group!',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: () async {
              await Navigator.pushNamed(context, '/create-gallery', arguments: {
                'groupId': widget.groupId,
                'groupName': _groupDetails?.name ?? widget.groupName,
              });
              await _refreshData();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 15, 74, 128),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Create Album',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  Widget _buildNoSearchResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No albums found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
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
    final images = gallery.images.take(4).toList();
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/album-detail',
          arguments: {
            'gallery': gallery,
            'groupName': _groupDetails?.name ?? widget.groupName,
          },
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
            // Até 4 fotos lado a lado
            if (images.isNotEmpty)
              Row(
                children: images.map((img) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 2.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: img == images.first ? Radius.circular(16) : Radius.zero,
                          topRight: img == images.last ? Radius.circular(16) : Radius.zero,
                        ),
                        child: Image.network(
                          img,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 160,
                              color: primaryBlue.withValues(alpha: 0.1),
                              child: Icon(
                                Icons.image_not_supported,
                                color: primaryBlue,
                                size: 30,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 160,
                              color: primaryBlue.withValues(alpha: 0.1),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: primaryBlue,
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            if (images.isEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Container(
                  height: 120,
                  color: primaryBlue.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.photo_library_outlined,
                    color: primaryBlue,
                    size: 40,
                  ),
                ),
              ),
            // Informações do evento
            Padding(
              padding: const EdgeInsets.all(15.0),
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
                            Icons.camera_alt,
                            size: 16,
                            color: darkBlue,
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
                  
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
