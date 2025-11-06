import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/groups_service.dart';

class AvatarGroupWidget extends StatefulWidget {
  final String groupId;
  final String? avatarUrl;
  final double radius;
  final bool allowEdit;
  final bool deferredUpload; // novo: se true, não faz upload automático
  final void Function(String? localPath)?
  onImageSelected; // novo: callback com path local
  final VoidCallback? onAvatarChanged;
  final bool showBlueBorder;

  const AvatarGroupWidget({
    super.key,
    required this.groupId,
    this.avatarUrl,
    this.radius = 30,
    this.allowEdit = false,
    this.deferredUpload = false,
    this.onImageSelected,
    this.onAvatarChanged,
    this.showBlueBorder = true,
  });

  @override
  State<AvatarGroupWidget> createState() => _AvatarGroupWidgetState();
}

class _AvatarGroupWidgetState extends State<AvatarGroupWidget> {
  final GroupsService _groupsService = GroupsService();
  String? _avatarUrl;
  File? _selectedImageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _avatarUrl = widget.avatarUrl;
  }

  @override
  void didUpdateWidget(AvatarGroupWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.avatarUrl != oldWidget.avatarUrl) {
      setState(() {
        _avatarUrl = widget.avatarUrl;
      });
    }
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
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
        });
        if (widget.deferredUpload) {
          if (widget.onImageSelected != null) {
            widget.onImageSelected!(pickedFile.path);
          }
        } else {
          await _uploadSelectedAvatar();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: ${e.toString()}'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  Future<void> _uploadSelectedAvatar() async {
    if (_selectedImageFile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _groupsService.uploadGroupAvatar(
        groupId: widget.groupId,
        avatarFilePath: _selectedImageFile!.path,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final newAvatarUrl = data['avatar_url'] as String?;

        if (mounted) {
          setState(() {
            _avatarUrl = newAvatarUrl;
            _selectedImageFile = null;
            _isLoading = false;
          });

          // Callback para notificar mudança
          if (widget.onAvatarChanged != null) {
            widget.onAvatarChanged!();
          }

          // Mostrar sucesso
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Avatar atualizado com sucesso!',
              ),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Erro ao fazer upload');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedImageFile = null;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double radius = widget.radius;
    final Color primaryBlue = const Color.fromARGB(255, 81, 163, 230);

    final bool hasImage =
        (_selectedImageFile != null) ||
        (_avatarUrl != null && _avatarUrl!.isNotEmpty);
    const String defaultGroupAvatarAsset = 'lib/images/avatar_group2.png';
    return Stack(
      children: [
        hasImage
            ? Container(
              width: radius * 2,
              height: radius * 2,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
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
                        : (_selectedImageFile != null)
                        ? Image.file(
                          _selectedImageFile!,
                          fit: BoxFit.cover,
                          width: radius * 2,
                          height: radius * 2,
                        )
                        : Image.network(
                          _avatarUrl!,
                          fit: BoxFit.cover,
                          width: radius * 2,
                          height: radius * 2,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              defaultGroupAvatarAsset,
                              fit: BoxFit.cover,
                              width: radius * 2,
                              height: radius * 2,
                            );
                          },
                        ),
              ),
            )
            : Container(
              width: radius * 2,
              height: radius * 2,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipOval(
                child: Image.asset(
                  defaultGroupAvatarAsset,
                  fit: BoxFit.cover,
                  width: radius * 2,
                  height: radius * 2,
                ),
              ),
            ),
        if (widget.allowEdit && !_isLoading)
          Positioned(
            bottom: 0,
            right: 10,
            child: GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                decoration: BoxDecoration(
                  color: primaryBlue, // Fundo azul
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                padding: EdgeInsets.all(widget.radius * 0.1),
                child: Icon(
                  Icons.add_a_photo, // Ícone de 'mais'
                  size: widget.radius * 0.2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

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
    const String defaultGroupAvatarAsset = 'lib/images/avatar_group2.png';
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
        child:
            avatarUrl == null
                ? ClipOval(
                  child: Image.asset(
                    defaultGroupAvatarAsset,
                    fit: BoxFit.cover,
                    width: radius * 2,
                    height: radius * 2,
                  ),
                )
                : null,
      ),
    );
  }
}
