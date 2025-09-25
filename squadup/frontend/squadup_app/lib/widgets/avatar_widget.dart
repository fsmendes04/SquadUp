import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';
import '../services/avatar_service.dart';

class AvatarWidget extends StatefulWidget {
  final User? user;
  final double size;
  final bool showEditButton;
  final Function(User)? onAvatarUpdated;
  final VoidCallback? onEditPressed;

  const AvatarWidget({
    Key? key,
    this.user,
    this.size = 80.0,
    this.showEditButton = false,
    this.onAvatarUpdated,
    this.onEditPressed,
  }) : super(key: key);

  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget> {
  final AvatarService _avatarService = AvatarService();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Avatar principal
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: ClipOval(child: _buildAvatarImage()),
        ),

        // Indicador de carregamento
        if (_isUploading)
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.5),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),

        // Botão de edição
        if (widget.showEditButton && !_isUploading)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                iconSize: widget.size * 0.2,
                padding: EdgeInsets.all(widget.size * 0.05),
                constraints: BoxConstraints(
                  minWidth: widget.size * 0.3,
                  minHeight: widget.size * 0.3,
                ),
                onPressed: widget.onEditPressed ?? _showImageSourceDialog,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarImage() {
    if (widget.user?.hasAvatar == true) {
      return Image.network(
        widget.user!.avatarUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderAvatar();
        },
      );
    } else {
      return _buildPlaceholderAvatar();
    }
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Icon(
        Icons.person,
        size: widget.size * 0.6,
        color: Theme.of(context).primaryColor.withOpacity(0.7),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Selecionar foto do perfil',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _selectAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Câmera'),
                onTap: () {
                  Navigator.pop(context);
                  _selectAndUploadImage(ImageSource.camera);
                },
              ),
              if (widget.user?.hasAvatar == true)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Remover foto',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _removeAvatar();
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectAndUploadImage(ImageSource source) async {
    try {
      setState(() {
        _isUploading = true;
      });

      final updatedUser = await _avatarService.selectAndUploadAvatar(source);

      if (widget.onAvatarUpdated != null) {
        widget.onAvatarUpdated!(updatedUser);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar avatar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _removeAvatar() async {
    try {
      setState(() {
        _isUploading = true;
      });

      final updatedUser = await _avatarService.deleteAvatar();

      if (widget.onAvatarUpdated != null) {
        widget.onAvatarUpdated!(updatedUser);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar removido com sucesso!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover avatar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
}

// Widget simples para exibir avatar sem edição
class SimpleAvatarWidget extends StatelessWidget {
  final User? user;
  final double size;

  const SimpleAvatarWidget({Key? key, this.user, this.size = 40.0})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AvatarWidget(user: user, size: size, showEditButton: false);
  }
}
