import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/groups_service.dart';

class AvatarGroupWidget extends StatefulWidget {
  final String groupId;
  final String? avatarUrl;
  final double radius;
  final bool allowEdit;
  final VoidCallback? onAvatarChanged;

  const AvatarGroupWidget({
    super.key,
    required this.groupId,
    this.avatarUrl,
    this.radius = 30,
    this.allowEdit = false,
    this.onAvatarChanged,
  });

  @override
  State<AvatarGroupWidget> createState() => _AvatarGroupWidgetState();
}

class _AvatarGroupWidgetState extends State<AvatarGroupWidget> {
  final GroupsService _groupsService = GroupsService();
  String? _avatarUrl;
  String? _selectedImagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _avatarUrl = widget.avatarUrl;
  }

  Future<void> _showImageSourceDialog() async {
    if (_isLoading) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Escolher foto do grupo',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageSourceOption(
                      icon: Icons.photo_library,
                      label: 'Galeria',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                    _buildImageSourceOption(
                      icon: Icons.camera_alt,
                      label: 'Câmera',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (pickedFile != null && mounted) {
      setState(() {
        _selectedImagePath = pickedFile.path;
      });
      _uploadSelectedAvatar();
    }
  }

  Future<void> _uploadSelectedAvatar() async {
    if (_selectedImagePath == null) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await _groupsService.uploadGroupAvatar(
        widget.groupId,
        _selectedImagePath!,
      );
      setState(() {
        _avatarUrl = response['data']['avatar_url'];
        _selectedImagePath = null;
      });
      if (widget.onAvatarChanged != null) widget.onAvatarChanged!();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double outerRadius = widget.radius;
    final double borderWidth = 2;
    final double innerRadius = outerRadius - borderWidth;
    final Color primaryBlue = const Color.fromARGB(255, 81, 163, 230);

    return Stack(
      children: [
        // Outer gradient border
        Container(
          width: outerRadius * 2,
          height: outerRadius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [primaryBlue.withOpacity(0.8), primaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            // White border
            child: Container(
              width: innerRadius * 2,
              height: innerRadius * 2,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Center(
                child: Container(
                  width: (innerRadius - borderWidth) * 2,
                  height: (innerRadius - borderWidth) * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [primaryBlue.withOpacity(0.7), primaryBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: ClipOval(
                    child:
                        _isLoading
                            ? Center(
                              child: SizedBox(
                                width: widget.radius,
                                height: widget.radius,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            )
                            : (_selectedImagePath != null)
                            ? Image.file(
                              File(_selectedImagePath!),
                              fit: BoxFit.cover,
                              width: (innerRadius - borderWidth) * 2,
                              height: (innerRadius - borderWidth) * 2,
                            )
                            : (_avatarUrl != null)
                            ? Image.network(
                              _avatarUrl!,
                              fit: BoxFit.cover,
                              width: (innerRadius - borderWidth) * 2,
                              height: (innerRadius - borderWidth) * 2,
                            )
                            : Center(
                              child: Icon(
                                Icons.groups,
                                size: widget.radius * 0.8,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.allowEdit && !_isLoading)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                padding: EdgeInsets.all(widget.radius * 0.15),
                child: Icon(
                  Icons.camera_alt,
                  size: widget.radius * 0.3,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Widget simples para exibir avatar de grupo apenas (sem edição)
class GroupAvatarDisplay extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  final VoidCallback? onTap;

  const GroupAvatarDisplay({
    super.key,
    this.avatarUrl,
    this.radius = 25,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double outerRadius = radius;
    final double borderWidth = 2;
    final double innerRadius = outerRadius - borderWidth;
    final Color primaryBlue = const Color.fromARGB(255, 81, 163, 230);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: outerRadius * 2,
        height: outerRadius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [primaryBlue.withOpacity(0.8), primaryBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Container(
            width: innerRadius * 2,
            height: innerRadius * 2,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Center(
              child: Container(
                width: (innerRadius - borderWidth) * 2,
                height: (innerRadius - borderWidth) * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [primaryBlue.withOpacity(0.7), primaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ClipOval(
                  child:
                      avatarUrl != null
                          ? Image.network(
                            avatarUrl!,
                            fit: BoxFit.cover,
                            width: (innerRadius - borderWidth) * 2,
                            height: (innerRadius - borderWidth) * 2,
                          )
                          : Center(
                            child: Icon(
                              Icons.groups,
                              size: radius,
                              color: Colors.white,
                            ),
                          ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
