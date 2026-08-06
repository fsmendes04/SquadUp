import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/gallery.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'layout.dart';

class AlbumDetailScreen extends StatefulWidget {
  final Gallery gallery;
  final String groupName;

  const AlbumDetailScreen({
    super.key,
    required this.gallery,
    required this.groupName,
  });

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  final darkBlue = const Color.fromARGB(255, 29, 56, 95);
  final primaryBlue = const Color.fromARGB(255, 81, 163, 230);
  final lightGrey = const Color.fromARGB(255, 242, 242, 242);

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

  String _formatTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '09:00';
    }
  }

  void _showImageViewer(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ImageViewerScreen(
              images: widget.gallery.images,
              initialIndex: initialIndex,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          size: 28,
                          color: Colors.black,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.gallery.eventName,
                              style: GoogleFonts.poppins(
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                                color: darkBlue,
                              ),
                            ),
                            Text(
                              '${widget.gallery.images.length} photos',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: darkBlue.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: darkBlue,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_a_photo,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Add',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildInfoRow(
                  'Created on:',
                  '${_formatDate(widget.gallery.date)}, ${_formatTime(widget.gallery.createdAt)}',
                ),
                const SizedBox(height: 16),

                _buildInfoRow('Location:', widget.gallery.location),
                const SizedBox(height: 16),

                if (widget.gallery.images.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildPhotoGrid(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label ',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: darkBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoGrid() {
    final images = widget.gallery.images;
    final count = images.length;

    if (count == 0) {
      return const SizedBox();
    }

    final layout = generatePhotoLayout(images.length);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: StaggeredGrid.count(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        children:
            layout.map((tile) {
              return StaggeredGridTile.count(
                crossAxisCellCount: tile.width,
                mainAxisCellCount: tile.height,
                child: _photo(images[tile.index], tile.index),
              );
            }).toList(),
      ),
    );
  }

  Widget _photo(String url, int index) {
    return GestureDetector(
      onTap: () => _showImageViewer(index),
      child: ClipRRect(child: Image.network(url, fit: BoxFit.cover)),
    );
  }
}

// Tela de visualização de imagem em tela cheia
class ImageViewerScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ImageViewerScreen({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Galeria de imagens
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      widget.images[index],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 48,
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),

            // Botão de voltar
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Contador de imagens
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.images.length}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
